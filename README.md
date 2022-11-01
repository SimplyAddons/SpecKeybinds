# Specialization Keybinds

An addon for World of Warcraft that enables per-specialization key binding support. After being set, the current key binding layout will automatically change whenever the active specialization is changed. This includes situations when the active specialization is automatically changed by the game (i.e when entering arenas).

This addon is a continuation of Specialization Specific Keybinds, originally authored by [Matthias Y](https://github.com/myzb/SpecSpecificKeybinds), and since archived.

## How to Use

1. **Setting Keybinds:** Using the in-game talent window, activate the specialization you want to set key bindings for. Set your binds using the key binding menu.

1. **Loading Keybinds:** Using the in-game talent window, activate the desired specialization.

_A message similar to the one below will be printed whenever key bindings change_

![SpecKeybinds](https://i.imgur.com/Pi7GAol.jpg)

**Additional Info**

Specs that haven't been key bound yet will use the current set of key bindings as a template.

Key bindings will be saved locally within the __WTF__ folder of your game installation. Only the active key bindings are stored on the game server. The location of your saved key binds is:

``WTF\Account\<account>\<realm>\<character>\SavedVariables\SpecKeybinds.lua``

## Compatibility & Limitations

All key bindings belonging to the standard blizzard interface and those showing up in the standard key binding menu (Esc -> Key Bindings) are supported.

**Action Bar Mods (ElvUI, Bartender)**

The official Blizzard UI offers 8 customizable action bars. Most action bar mods re-use these 8 bars and add a few extra of their own. These mods will have to properly register their own bars with the game or SpecKeybinds won't know they exist.

## FAQ

Q: What about the 'Character Specific Key Bindings' toggle in the Key Bindings menu?  
_A: The addon will save the current active key bindings as character bindings. This means that this toggle will be implicitly set._

Q: Why are (some) of my action bar key bindings not properly getting tracked?  
_A: See the limitations. For mods like ElvUI use the default blizzard key binding menu (Esc -> Key Bindings) to set your bindings. Avoid using 'Quick Binding Mode' if you don't know what you are doing._

Q: Can you add support for AddonName?  
_A: SpecKeybinds uses the default game functionality to set and retrieve key bindings. Addons that also make use of this mechanism will be supported by default. No special support will be added for any action bar addons, to avoid dependency creep, and to ensure Spec Keybinds remains compatible with future versions of WoW, as best it can._

## Feedback
To give feedback or report a bug, please use the [issues](https://github.com/SimplyAddons/SpecKeybinds/issues)

## Legal
Please see the [LICENSE](https://github.com/SimplyAddons/SpecKeybinds/blob/main/LICENSE.txt) file.
