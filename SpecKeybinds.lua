local addonName = ...
local addon, events = CreateFrame('Frame', addonName), {}

-- API Imports
local SetBinding, GetBinding = SetBinding, GetBinding
local GetSpecialization = C_SpecializationInfo.GetSpecialization
local GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
local CHARACTER_BINDINGS = 2

-- -----------------------------------------------------------------------------
-- > DEBUG / LOGGING
-- -----------------------------------------------------------------------------
local DEBUG = false
local function log(...)
	if (DEBUG) then
		print('|cFF1784d1[SpecKeybinds]|r', ...)
	end
end

-- -----------------------------------------------------------------------------
-- > ADDON FUNCTIONS
-- -----------------------------------------------------------------------------

-- GetSpecializationInfo() is not immediately available on entering an instance
local function printActiveSpec(spec)
	local _, name = GetSpecializationInfo(spec)
	if not name then
		C_Timer.After(0.5, function() printActiveSpec(spec) end)
		return
	end
	print(string.format('|cffffff00Key Bindings set to Specialization: %s|r', name))
end

-- GetSpecialization() can return nil for a moment after login / a spec swap.
-- Defer work until it reports a real spec instead of writing to binds[nil].
local function whenSpecReady(callback, attempt)
	local spec = GetSpecialization()
	if (not spec) then
		attempt = (attempt or 0) + 1
		if (attempt <= 20) then
			log('spec not ready, retry', attempt)
			C_Timer.After(0.5, function() whenSpecReady(callback, attempt) end)
		else
			log('spec still nil after 20 retries, giving up')
		end
		return
	end
	callback(spec)
end

-- Compare two key pairs as unordered sets. A command's primary/secondary
-- bindings are a set, not an ordered pair: WoW may load them in a different
-- order than we saved, and treating that as a change makes them ping-pong
-- on every reload.
local function sameKeySet(a1, a2, b1, b2)
	return (a1 == b1 and a2 == b2) or (a1 == b2 and a2 == b1)
end

-- Ignore player housing commands matching these patterns.
-- The HOUSING_* binds share movement keybinds, causing conflict.
-- Note: I could support these, but I dont think its the core focus
-- of this addon, so maybe its just better to ignore them.
local IGNORED_PATTERNS = {
	'^HOUSING_',
	'^TOGGLEHOUSINGDASHBOARD$',
}

local function isIgnored(cmd)
	for _, pattern in ipairs(IGNORED_PATTERNS) do
		if (cmd:match(pattern)) then
			return true
		end
	end
	return false
end

-- Drop any ignored commands already sitting in the saved DB (one-time cleanup
-- for configs saved before the ignore list existed).
local function pruneIgnored(self)
	local removed = 0
	for _, binds in pairs(self.db.binds) do
		for cmd in pairs(binds) do
			if (isIgnored(cmd)) then
				binds[cmd] = nil
				removed = removed + 1
			end
		end
	end
	log('pruneIgnored: removed', removed, 'ignored binding(s) from saved config')
end

-- Deep copy a spec's binding table so two specs never alias the same table.
local function copyBinds(src)
	local dst = {}
	if (src) then
		for cmd, keys in pairs(src) do
			dst[cmd] = { keys[1], keys[2] }
		end
	end
	return dst
end

local function saveBindings(self, spec)
	if (not spec) then
		log('saveBindings aborted: nil spec')
		return
	end
	local binds = {}
	local count = 0
	for i = 1, GetNumBindings() do
		local cmd, _, key1, key2 = GetBinding(i)
		if (key1 and not isIgnored(cmd)) then
			binds[cmd] = { key1, key2 }
			count = count + 1
		end
	end
	self.db.binds[spec] = binds
	log('saved', count, 'binding(s) for spec', spec)
end

-- Addons like ElvUI fire a storm of UPDATE_BINDINGS while applying bar binds.
-- Debounce so the whole burst collapses into a single save, pinned to the spec
-- that was active when the change happened.
local function scheduleSave(self)
	local spec = GetSpecialization()
	if (not spec) then
		log('scheduleSave: nil spec, skipping')
		return
	end
	self.pendingSpec = spec
	if (self.saveScheduled) then
		return
	end
	self.saveScheduled = true
	C_Timer.After(0.2, function()
		self.saveScheduled = false
		if (self.suppressSave or not self.loaded) then
			log('debounced save skipped (suppress=' .. tostring(self.suppressSave) .. ', loaded=' .. tostring(self.loaded) .. ')')
			return
		end
		saveBindings(self, self.pendingSpec)
	end)
end

local function loadBindings(self, spec)
	if (not spec) then
		log('loadBindings aborted: nil spec')
		return
	end

	if (not self.db.binds[spec]) then
		log('no binds for spec', spec, '- copying from spec', tostring(self.spec))
		self.db.binds[spec] = copyBinds(self.db.binds[self.spec])
	end
	local binds = self.db.binds[spec] or {}
	self.spec = spec

	if (InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
		print(string.format('|cffffff00Key Bindings will be changed after combat ends.|r'))
		log('in combat, deferring load for spec', spec)
		return
	end

	-- Suppress the auto-save while we apply, so our own SetBinding/SaveBindings
	-- churn (and the deferred UPDATE_BINDINGS it fires) can't re-snapshot mid-load.
	self.suppressSave = true

	local changed = 0
	for i = 1, GetNumBindings() do
		local cmd, _, key1, key2 = GetBinding(i)
		local newKey1, newKey2 = unpack(binds[cmd] or {})
		-- Ignored commands (e.g. HOUSING_*) are left exactly as WoW has them.
		if (isIgnored(cmd)) then
			-- nothing
		-- Same keys in a different primary/secondary order is not a change;
		-- skip it so movement keys etc. don't ping-pong on every reload.
		elseif (not sameKeySet(key1, key2, newKey1, newKey2)) then
			if (key1 ~= newKey1) then
				log('  change', cmd, '| key1', tostring(key1), '->', tostring(newKey1))
				if (key1) then
					SetBinding(key1) -- clear
				end
				if (newKey1) then
					SetBinding(newKey1, cmd)
				end
				changed = changed + 1
			end
			if (key2 ~= newKey2) then
				log('  change', cmd, '| key2', tostring(key2), '->', tostring(newKey2))
				if (key2 and key2 ~= newKey1) then
					SetBinding(key2) -- clear
				end
				if (newKey2) then
					SetBinding(newKey2, cmd)
				end
				changed = changed + 1
			end
		end
	end
	SaveBindings(CHARACTER_BINDINGS)
	self.loaded = true
	log('applied spec', spec, '-', changed, 'binding(s) changed')

	C_Timer.After(0.1, function()
		self.suppressSave = false
		log('auto-save re-enabled')
	end)

	printActiveSpec(spec)
end

function addon:OnEnable()
	self.db.config = self.db.config or {}
	self.db.binds = self.db.binds or {}
	self.loaded = false
	self.suppressSave = false
	pruneIgnored(self)
	self:RegisterEvent('PLAYER_LOGIN')
end

function events:PLAYER_LOGIN(...)
	self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
	self:RegisterEvent('UPDATE_BINDINGS')
	whenSpecReady(function(spec)
		log('PLAYER_LOGIN resolved spec', spec)
		if (not self.db.binds[spec]) then
			saveBindings(self, spec)
		end
		loadBindings(self, spec)
	end)
end

function events:PLAYER_REGEN_ENABLED(...)
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
	log('combat ended, applying deferred load for spec', tostring(self.spec))
	loadBindings(self, self.spec)
end

function events:ACTIVE_TALENT_GROUP_CHANGED(...)
	whenSpecReady(function(spec)
		if (self.spec ~= spec) then
			log('talent group changed:', tostring(self.spec), '->', spec)
			loadBindings(self, spec)
		end
	end)
end

function events:UPDATE_BINDINGS(...)
	if (self.suppressSave or not self.loaded) then
		log('UPDATE_BINDINGS ignored (suppress=' .. tostring(self.suppressSave) .. ', loaded=' .. tostring(self.loaded) .. ')')
		return
	end
	log('UPDATE_BINDINGS -> scheduling save')
	scheduleSave(self)
end

-- ---------------------
-- > ADDON SETUP
-- ---------------------

function events:ADDON_LOADED(...)
	local name = ...
	if (name == addonName) then
		if (not _G[self.dbName]) then
			_G[self.dbName] = {}
		end
		self.db = _G[self.dbName]
		self:OnEnable()
	end
end

function addon:Initialize(dbName, events)
	self.events = events
	self.dbName = dbName

	-- do not register everything just yet
	self:RegisterEvent('ADDON_LOADED')

	self:SetScript('OnEvent', function(element, event, ...)
		element.events[event](element, ...)
	end)
end

addon:Initialize(addonName .. 'DB', events)
