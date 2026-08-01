# ps-dispatch — Sail integration

Sail fork of [Project-Sloth/ps-dispatch](https://github.com/Project-Sloth/ps-dispatch).

| Field | Value |
|-------|--------|
| Sail fork | https://github.com/Sytrookie/ps-dispatch |
| Upstream | https://github.com/Project-Sloth/ps-dispatch |
| Monorepo path | `system_resources/[core]/ps-dispatch` |
| License | **GPL-3.0** (see `LICENSE`) |

## Sail deltas

| Path | Change |
|------|--------|
| `sail_bridge_client.lua` | Fake `QBCore` + `PlayerData` from Sail bags / jobs; callsign via server callback |
| `fxmanifest.lua` | Drop PolyZone; load Sail bridge first; oxmysql for callsign lookup |
| `client/main.lua` | Hot-reload: zones + call list rehydrate; stop clears NUI focus + alert blips |
| `server/main.lua` | Attach/detach uses `sailCharacterId`; session call list in GlobalState |
| `SAIL.md` | This file |

## Config notes

- `Config.Jobs` uses job **types** `leo` / `ems` (Sail bridge sets `job.type` from police/ambulance names).
- `Config.OnDutyOnly = true` — requires `sail_jobs` clock-in.
- Phone for 911: ox_inventory item `phone` (adjust `Config.PhoneItems` to match Sail).
- `Config.PhoneRequired` — when true, emergency chat commands need a phone item.

## Hot-reload / persistence (session)

| Behavior | Support |
|----------|---------|
| Resource `restart ps-dispatch` mid-session | **Supported**: client re-runs zones + UI setup; server rehydrates active calls from GlobalState |
| Full FXServer reboot | Active call list is **empty** (session bag only — not MySQL). Acceptable for ephemeral 911/traffic alerts |
| Attach identity | Always `Player(src).state.sailCharacterId` — client cannot spoof unit citizenid |

If seamless full-reboot call history is required later, add a durable table — not implemented.

## Upstream merge

```bat
cd system_resources\[core]\ps-dispatch
git fetch upstream
git merge upstream/main
rem keep Sail files listed above
git push origin main
cd ..\..\..
git add system_resources/[core]/ps-dispatch
git commit -m "Bump ps-dispatch submodule"
```
