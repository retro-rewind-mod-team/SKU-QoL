# SKU QoL
**Version:** 1.0  
**Game:** Retro Rewind Video Store Simulator  
**Framework:** UE4SS v3.0.1

---

## What it does

SKU QoL remembers the SKU of the last cassette you picked up and uses it automatically wherever you need to enter it — no typing required.

Two paths are always active in parallel:

| Action | Result |
|--------|--------|
| Pick up a cassette → sit at the computer | Black Market search fires automatically |
| Pick up a cassette → open a poster's SKU editor | SKU is applied immediately |

Both paths react to the same stored SKU, so you can pick up a cassette once and use it freely at either the computer or a poster without any further interaction.

---

## How it works

**Computer path**  
When the player sits down at the computer and the camera animation finishes, the mod calls the Black Market search delegate directly — the same path the search button uses internally. If the player is already at the computer when the cassette is picked up, the search fires immediately.

**Poster path**  
When the player opens the SKU editor on any PosterFrame actor (wall, standing, or small poster), the stored SKU is committed automatically via `SKU Command Button Committed`, bypassing manual input entirely.

---

## Requirements

- **UE4SS** must be installed first.
  Follow the installation instructions on the [UE4SS Nexus page](https://www.nexusmods.com/retrorewindvideostoresimulator/mods/52) before proceeding.


---

## Installation

1. Make sure **UE4SS v3.0.1** is installed.
2. Drop the `SKU-QoL` folder into your `Mods` directory.
3. Load your save — no further setup needed.

---

## Configuration

All options are at the top of `main.lua`:

```lua
local Config = {
    Debug       = false,  -- true = log hook registrations and detailed errors
    HookDelayMs = 3000,   -- milliseconds before hooks register after load
}
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Debug` | bool | `false` | Prints hook registration status and detailed error messages to the UE4SS console |
| `HookDelayMs` | int | `3000` | Delay before hooks register. Increase if you see hook errors on slower machines |

---

## Usage

1. Pick up a cassette.
2a. Sit at the computer → Black Market search fires automatically.  
2b. Open a poster's SKU editor → SKU is applied automatically.

The stored SKU persists until the next cassette is picked up. You can visit multiple posters or re-enter the computer and the last SKU will always be used.

---

## Compatibility

- Does not modify any save data.
- Does not interfere with other mods that hook `Cartridge_Base_C`, `ComputerScreen_C`, or `PosterFrame_C` — hooks are registered once and deduplicated.
- Compatible with all poster types (wall, standing, small).

---

## Known limitations

- The stored SKU resets on game restart (not persisted to disk by design — the workflow is pick up → use immediately).
- If no cassette has been picked up yet, the poster and computer paths do nothing.

---

## Changelog

**1.0**
- Initial release
- Computer: auto-search on Black Market tab when player sits down
- Poster: auto-commit SKU when SKU editor opens


## License
Shield: [![CC BY-SA 4.0][cc-by-sa-shield]][cc-by-sa]

This work is licensed under a
[Creative Commons Attribution-ShareAlike 4.0 International License][cc-by-sa].

[![CC BY-SA 4.0][cc-by-sa-image]][cc-by-sa]

[cc-by-sa]: http://creativecommons.org/licenses/by-sa/4.0/
[cc-by-sa-image]: https://licensebuttons.net/l/by-sa/4.0/88x31.png
[cc-by-sa-shield]: https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg
