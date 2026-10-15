--[[
    Config.lua (ReplicatedStorage.Shared)
    Chronos Vault: Complete Overhaul Configuration
    Tuning for gameplay, egg tiers, deposit system, sound effects, and visuals.
]]

local Config = {}

------------------------------------------------------------
-- ROUND & GAMEPLAY
------------------------------------------------------------
Config.ROUND_DURATION      = 100    -- seconds per round
Config.INTERMISSION        = 10     -- seconds between rounds
Config.EGGS_PER_ROUND      = 28     -- total eggs across the arena

-- Real "Steal the Egg" Backpack System
Config.BASE_CAPACITY       = 3      -- max eggs a player can carry before banking
Config.CAPACITY_INCREMENT  = 2      -- +2 capacity per backpack upgrade

------------------------------------------------------------
-- EGG TIERS (Juicy Visuals & Rewards)
------------------------------------------------------------
Config.EGG_TIERS = {
	Common = {
		Name        = "Bronze Egg",
		Color       = Color3.fromRGB(205, 127, 50),
		Value       = 1,
		Weight      = 60, -- 60% spawn chance
		Size        = Vector3.new(1.8, 2.6, 1.8),
		ParticleClr = ColorSequence.new(Color3.fromRGB(255, 200, 100)),
		SoundPitch  = 1.0,
	},
	Silver = {
		Name        = "Silver Egg",
		Color       = Color3.fromRGB(200, 225, 255),
		Value       = 3,
		Weight      = 25, -- 25% spawn chance
		Size        = Vector3.new(2.1, 3.0, 2.1),
		ParticleClr = ColorSequence.new(Color3.fromRGB(150, 220, 255)),
		SoundPitch  = 1.15,
	},
	Gold = {
		Name        = "Golden Egg",
		Color       = Color3.fromRGB(255, 215, 0),
		Value       = 10,
		Weight      = 12, -- 12% spawn chance
		Size        = Vector3.new(2.4, 3.4, 2.4),
		ParticleClr = ColorSequence.new(Color3.fromRGB(255, 230, 50)),
		SoundPitch  = 1.3,
	},
	Chronos = {
		Name        = "👑 Chronos Core Egg",
		Color       = Color3.fromRGB(255, 50, 180),
		Value       = 35,
		Weight      = 3,  -- 3% spawn chance (Spawns at Central Vault)
		Size        = Vector3.new(3.0, 4.2, 3.0),
		ParticleClr = ColorSequence.new(Color3.fromRGB(255, 50, 220), Color3.fromRGB(0, 255, 255)),
		SoundPitch  = 1.5,
	},
}

------------------------------------------------------------
-- SOUND EFFECTS (Roblox Licensed Sound Library)
------------------------------------------------------------
Config.SOUNDS = {
	EggPickup   = "rbxassetid://9069609200",  -- Juicy bubble/pop chime
	DepositBank = "rbxassetid://9069609268",  -- Big cash register/coin cascade
	UpgradeBuy  = "rbxassetid://9069609074",  -- Fanfare/level up triumph
	JumpPad     = "rbxassetid://9114223170",  -- Kinetic whoosh
	BackpackFull= "rbxassetid://9069609124",  -- Thud/alert buzzer
	MusicLoop   = "rbxassetid://9043887091",  -- Ambient cyber electronic loop
}

------------------------------------------------------------
-- UPGRADES & SHOPS
------------------------------------------------------------
Config.UPGRADES = {
	Speed = {
		DisplayName   = "Super Speed",
		Icon          = "⚡",
		BaseValue     = 18,
		Increment     = 4,
		MaxLevel      = 10,
		BaseCost      = 5,
		CostMult      = 1.5,
		Description   = "+4 WalkSpeed & longer neon trail",
	},
	Backpack = {
		DisplayName   = "Egg Backpack",
		Icon          = "🎒",
		BaseValue     = 3,
		Increment     = 2,
		MaxLevel      = 6,
		BaseCost      = 8,
		CostMult      = 1.7,
		Description   = "+2 Egg carry capacity before banking",
	},
	Multiplier = {
		DisplayName   = "Vault Multiplier",
		Icon          = "💎",
		BaseValue     = 1,
		Increment     = 1,
		MaxLevel      = 5,
		BaseCost      = 15,
		CostMult      = 2.2,
		Description   = "+1x multiplier on all deposited eggs",
	},
	Jump = {
		DisplayName   = "Spring Boots",
		Icon          = "🦘",
		BaseValue     = 50,
		Increment     = 10,
		MaxLevel      = 5,
		BaseCost      = 10,
		CostMult      = 1.6,
		Description   = "+10 JumpPower for platform parkour",
	},
}

function Config.GetCost(upgradeType, currentLevel)
	local up = Config.UPGRADES[upgradeType]
	if not up or currentLevel >= up.MaxLevel then
		return math.huge
	end
	return math.floor(up.BaseCost * (up.CostMult ^ currentLevel))
end

------------------------------------------------------------
-- MAP COORDINATES
------------------------------------------------------------
Config.LOBBY_CENTER        = Vector3.new(0, 16, -135)
Config.VAULT_DEPOSIT_POS   = Vector3.new(0, 16.5, -115) -- In lobby entrance
Config.ARENA_CENTER        = Vector3.new(0, 0, 0)
Config.VAULT_CORE_POS      = Vector3.new(0, 12, 0)

Config.DATA_STORE_NAME     = "ChronosVault_Master_v3"
Config.AUTO_SAVE_INTERVAL  = 120

return Config
