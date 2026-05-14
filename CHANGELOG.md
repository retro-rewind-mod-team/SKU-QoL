# Changelog

## SKU QoL

### 1.1
- `safe()` — now supports variadics and multiple return values, consistent with Economy QoL and Promotion QoL
- PickUp-Hook — added `cart:IsValid()` check before accessing the product structure; prevents errors when a cassette is invalidated by GC immediately after pickup
- Added reset hooks — `WeatherSystem_C:ReceiveBeginPlay` now resets both `playerAtComputer` and `lastSKU`; `Core_Gamemode_C:End of the day` resets `playerAtComputer`; fixes a bug where either flag could be left in the wrong state after a save reload or end of day

### 1.0
- Added poster support: opening the SKU editor on any PosterFrame actor (wall, standing, small) now commits the stored SKU immediately via `SKU Command Button Committed` — no manual input needed
- Added `Config` table with `Debug` and `HookDelayMs` options
- Added `safe()` helper for consistent error handling and logging
- Added `registeredHooks` deduplication map to prevent double-registration
- Added `debug()` helper, gated behind `Config.Debug`

---

> **Renamed to SKU QoL in version 1.0**
>
> The mod originally only automated the Black Market search at the computer.
> Version 1.0 added automatic SKU assignment for posters — a second, unrelated
> workflow that made "Black Market QoL" an inaccurate name. The mod was renamed
> to SKU QoL to reflect that it now covers the SKU wherever it is needed,
> not just at the Black Market.

---

## Black Market QoL

### 1.1
- Hook registration now logged to console for easier debugging
- `searchSKUInComputer` returns a success bool for internal error tracking

### 1.0
- Initial release
- Stores the SKU of the last picked-up cassette
- Automatically triggers the Black Market search when the player sits at the computer

---
