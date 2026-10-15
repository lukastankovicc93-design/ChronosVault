--[[
    Config.lua (ReplicatedStorage.Shared)
    Chronos Vault Configuration
    Single source of truth for map, gameplay, and shop values.
]]

local Config = {}

------------------------------------------------------------
-- ROUND & GAMEPLAY
------------------------------------------------------------
Config.ROUND_DURATION      = 120    -- seconds per round
Config.INTERMISSION        = 12     -- seconds between rounds
Config.EGGS_PER_ROUND      = 20     -- standard eggs per round
Config.VAULT_CORE_EGGS     = 3      -- rare golden core eggs in the center

-- Egg physical properties
Config.EGG_SIZE            = Vector3.new(2.2, 3.2, 2.2)
Config.EGG_COLOR           = Color3.fromRGB(255, 215, 0)      -- gold
Config.CORE_EGG_COLOR      = Color3.fromRGB(255, 50, 180)     -- hyper magenta/neon core egg
Config.CORE_EGG_MULT       = 5                                -- 5x eggs for core egg

------------------------------------------------------------
-- MAP COORDINATES & REGIONS
------------------------------------------------------------
-- Lobby / Safe Zone
Config.LOBBY_CENTER        = Vector3.new(0, 12, -120)
Config.LOBBY_SIZE          = Vector3.new(90, 4, 60)

-- Vault Arena
Config.ARENA_CENTER        = Vector3.new(0, 0, 0)
Config.ARENA_SIZE          = Vector3.new(190, 4, 190)
Config.VAULT_CORE_POS      = Vector3.new(0, 10, 0)            -- Raised center platform

-- Egg spawn bounds in arena
Config.SPAWN_MIN           = Vector3.new(-75, 4, -75)
Config.SPAWN_MAX           = Vector3.new(75, 4, 75)

------------------------------------------------------------
-- UPGRADE SYSTEM & SHOPS
------------------------------------------------------------
Config.UPGRADES = {
	Speed = {
		DisplayName   = "Walk Speed",
		Icon          = "⚡",
		BaseValue     = 16,
		Increment     = 4,
		MaxLevel      = 10,
		BaseCost      = 3,
		CostMult      = 1.5,
		Description   = "+4 WalkSpeed per level",
	},
	Multiplier = {
		DisplayName   = "Egg Multiplier",
		Icon          = "💎",
		BaseValue     = 1,
		Increment     = 1,
		MaxLevel      = 5,
		BaseCost      = 10,
		CostMult      = 2.2,
		Description   = "+1x eggs collected per level",
	},
	Jump = {
		DisplayName   = "Jump Power",
		Icon          = "🦘",
		BaseValue     = 50,
		Increment     = 8,
		MaxLevel      = 5,
		BaseCost      = 5,
		CostMult      = 1.6,
		Description   = "+8 JumpPower for high vault areas",
	},
	Magnet = {
		DisplayName   = "Collect Radius",
		Icon          = "🧲",
		BaseValue     = 5,
		Increment     = 2,
		MaxLevel      = 5,
		BaseCost      = 8,
		CostMult      = 1.8,
		Description   = "+2 studs pickup magnet radius",
	},
}

-- Calculate cost dynamically for any level
function Config.GetCost(upgradeType, currentLevel)
	local up = Config.UPGRADES[upgradeType]
	if not up or currentLevel >= up.MaxLevel then
		return math.huge
	end
	return math.floor(up.BaseCost * (up.CostMult ^ currentLevel))
end

------------------------------------------------------------
-- PERSISTENCE
------------------------------------------------------------
Config.DATA_STORE_NAME     = "ChronosVault_PlayerData_v2"
Config.AUTO_SAVE_INTERVAL  = 120

return Config
