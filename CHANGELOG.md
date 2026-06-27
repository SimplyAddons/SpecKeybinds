# 2.0.0
- ignore new housing binds (HOUSING_*)
- prune any HOUSING_* binds already saved
- fix keybinds drifting on reload when the spec wasn't detected in time
- compare a command's two keys as a set so primary/secondary swaps don't ping-pong
- debounce saves so ElvUI's binding spam doesn't fire a save per key
- reliability fixes for saving/loading binds

# 1.5.6
- bump TOC to 11.2.0

# 1.5.5
- fix lua error when the game client swaps to your chosen spec automatically on entering an instance

# 1.5.4
- bump TOC to 11.0.2

# 1.5.3
- bump TOC to 11.0.0
- add icon texture

# 1.5.2
- bump TOC to 10.2.0

# 1.5.1
- bump TOC to 10.1.0

# 1.5
- bump TOC to 10.0.2

# 1.4
- update TOC for wow 10.0.0
- removed manual keybind command

# 1.3
- update TOC for wow 9.1.0

# 1.2
- update TOC for wow 9.0.5

# 1.1
- update TOC

# 1.0
- always save bindings as character specific bindings

# 0.8-beta
- always load keybinds on login

# 0.7-beta
- reword some variables
- binds loading after combat should load requested spec
- notification when keybinds will be changed after combat ends
- chat command to load spec by number
- be a bit less verbose
- make keybinds update fully event driven
- avoid loading twice when adjusting talents

# 0.6-alpha
- move binds to their own db subtable
- fix loadBindings not restoring alternative bind for command
- load keybinds using ACTIVE_TALENT_GROUP_CHANGED event PLAYER_SPECIALIZATION_CHANGED does not trigger when spec gets auto switched by the game (i.e when entering arenas)
- track keybind changes by directly hooking into SaveBindings
- update toc

# 0.5-alpha
- add pkgmeta
- toc version to shadowlands 9.0.1
- update gitignore
- add readme
- add github workflows
- initial commit