# Chronos Vault 🥚⚡

A minimal **steal-the-egg** Roblox game with **speed upgrades**.

## Game Loop
1. **Intermission** (10s) → eggs cleared
2. **Round** (120s) → 15 golden eggs spawn across the map
3. Walk into eggs to collect them
4. Spend eggs to upgrade your walk speed (5 levels)

## Project Structure (Rojo)
```
ChronosVault/
├── default.project.json   ← Rojo config
└── src/
    ├── server/
    │   ├── GameManager.server.lua    ← Round loop, egg spawn, leaderboard
    │   └── DataStoreModule.lua       ← Persistent data (pcall + UpdateAsync)
    ├── client/
    │   └── SpeedClient.client.lua    ← HUD + buy speed button
    └── shared/
        └── Config.lua                ← All tunable values
```

## Setup
1. Install [Rojo](https://rojo.space) and the Roblox Studio plugin
2. `rojo serve` in this directory
3. Connect from Roblox Studio
4. Playtest!

## Tuning
Edit `src/shared/Config.lua` to change round duration, egg count, speed costs, etc.
