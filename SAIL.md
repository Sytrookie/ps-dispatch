# ps-dispatch — Sail integration

Vendored copy of [Project-Sloth/ps-dispatch](https://github.com/Project-Sloth/ps-dispatch) with a Sail client shim.

| Field | Value |
|-------|--------|
| Upstream | https://github.com/Project-Sloth/ps-dispatch |
| Monorepo path | `system_resources/[core]/ps-dispatch` |
| License | **GPL-3.0** (see `LICENSE`) |

## Sail deltas

| Path | Change |
|------|--------|
| `sail_bridge_client.lua` | Fake `QBCore` + `PlayerData` from Sail state bags / jobs |
| `fxmanifest.lua` | Drop PolyZone; load Sail bridge first |
| `client/main.lua` | No longer `exports['qb-core']:GetCoreObject()` |
| `SAIL.md` | This file |

## Config notes

- `Config.Jobs` uses job **types** `leo` / `ems` (Sail bridge sets `job.type` from police/ambulance names).
- `Config.OnDutyOnly = true` — requires `sail_jobs` clock-in.
- Phone for 911: ox_inventory item `phone` (adjust `Config.PhoneItems` to match Sail).

## Upstream merge

```bat
git fetch upstream
git merge upstream/main
rem keep sail_bridge_client.lua + fxmanifest Sail header + main.lua QBCore guard
```
