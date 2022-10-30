local addonName = ...
local addon, events = CreateFrame('Frame', addonName), {}

-- API Imports
local SetBinding, GetBinding = SetBinding, GetBinding
local GetSpecialization = GetSpecialization
local CHARACTER_BINDINGS = 2

-- -----------------------------------------------------------------------------
-- > ADDON FUNCTIONS
-- -----------------------------------------------------------------------------

local function loadBindings(self, spec)
	local _, name = GetSpecializationInfo(spec)
	if (not self.db.binds[spec]) then
		self.db.binds[spec] = self.db.binds[self.spec]
	end
	local binds = self.db.binds[spec]
	self.spec = spec

	if (InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
		print(string.format('|cffffff00Key Bindings will be changed after combat ends.|r'))
		return
	end

	self:UnregisterEvent('UPDATE_BINDINGS')
	for i = 1, GetNumBindings() do
		local cmd, _, key1, key2 = GetBinding(i)
		local newKey1, newKey2 = unpack(binds[cmd] or {})
		if (key1 ~= newKey1) then
			if (key1) then
				SetBinding(key1) -- clear
			end
			if (newKey1) then
				SetBinding(newKey1, cmd)
			end
		end
		if (key2 ~= newKey2) then
			if (key2 and key2 ~= newKey1) then
				SetBinding(key2) -- clear
			end
			if (newKey2) then
				SetBinding(newKey2, cmd)
			end
		end
	end
	SaveBindings(CHARACTER_BINDINGS)
	self:RegisterEvent('UPDATE_BINDINGS')
	print(string.format('|cffffff00Key Bindings set to Specialization: %s|r', name))
end

local function saveBindings(self, spec)
	local binds = {}
	for i = 1, GetNumBindings() do
		local cmd, _, key1, key2 = GetBinding(i)
		if (key1) then
			binds[cmd] = { key1, key2 }
		end
	end
	self.db.binds[spec] = binds
end

function addon:OnEnable()
	if (next(self.db) == nil) then
		self.db.config = {}
		self.db.binds = {}
	end
	self:RegisterEvent('PLAYER_LOGIN')
end

function events:PLAYER_LOGIN(...)
	local spec = GetSpecialization()
	if (not self.db.binds[spec]) then
		saveBindings(self, spec)
	end
	self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
	self:RegisterEvent('UPDATE_BINDINGS')
	loadBindings(self, spec)
end

function events:PLAYER_REGEN_ENABLED(...)
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
	loadBindings(self, self.spec)
end

function events:ACTIVE_TALENT_GROUP_CHANGED(...)
	local spec = GetSpecialization()
	if (self.spec ~= spec) then
		loadBindings(self, spec)
	end
end

function events:UPDATE_BINDINGS(...)
	saveBindings(self, GetSpecialization())
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
