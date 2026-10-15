-- ChronosVault: Shared Configuration (ReplicatedStorage)
-- Single source of truth for all tuning values

local Config = {}

-- Round settings
Config.ROUND_DURATION      = 120    -- seconds per round
Config.INTERMISSION        = 10     -- seconds between rounds
Config.EGGS_PER_ROUND      = 15     -- eggs spawned each round

-- Egg properties
Config.EGG_SIZE            = Vector3.new(2, 3, 2)
Config.EGG_COLOR           = Color3.fromRGB(255, 215, 0)  -- gold
Config.EGG_COLLECT_RADIUS  = 5      -- studs

-- Speed upgrade system
Config.BASE_WALK_SPEED     = 16
Config.SPEED_INCREMENT     = 4      -- per upgrade
Config.MAX_SPEED_LEVEL     = 5
Config.SPEED_COST_BASE     = 3      -- eggs to buy first upgrade
Config.SPEED_COST_MULT     = 1.5    -- multiplier per level

-- Spawn area bounds (adjust to your map)
Config.SPAWN_MIN = Vector3.new(-100, 5, -100)
Config.SPAWN_MAX = Vector3.new(100, 5, 100)

-- DataStore
Config.DATA_STORE_NAME     = "ChronosVault_PlayerData_v1"
Config.AUTO_SAVE_INTERVAL  = 120    -- seconds

return Config
