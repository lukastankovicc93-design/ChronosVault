--[[
    Config.lua (ReplicatedStorage.Shared)
    Chronos Vault: Ultimate Multi-Zone & Rebirth Configuration
    - 4 Tiered Lighted Zones (Common, Rare, Epic, Legendary Core)
    - 4 Dedicated Zone Guardian Monsters with distinct speeds
    - Calculated Progression System & Rebirth System
    - Player Hatchery Plots System
    - Manual Map Mode Toggle
]]

local Config = {}

------------------------------------------------------------
-- MANUAL MAP EDITING TOGGLE
------------------------------------------------------------
-- If true, server won't rebuild the map if you manually modified it in Studio!
Config.MANUAL_MAP_MODE     = false

------------------------------------------------------------
-- ROUND & GAMEPLAY
------------------------------------------------------------
Config.ROUND_DURATION      = 120
Config.INTERMISSION        = 10
Config.BASE_CAPACITY       = 3
Config.CAPACITY_INCREMENT  = 2

------------------------------------------------------------
-- MULTI-ZONE MAP LAYOUT (Expanded & Tiered)
------------------------------------------------------------
Config.ZONES = {
	Zone1 = {
		Name          = "Stardust Meadows (Tier 1 - Common)",
		Color         = Color3.fromRGB(0, 210, 255),
		LightColor    = Color3.fromRGB(0, 180, 255),
		Center        = Vector3.new(-75, 4, -20),
		Size          = Vector3.new(110, 4, 110),
		MinSpeedToRun = 20,
		EggTiers      = { "Common", "Common", "Common", "Silver" },
		Monster = {
			Name            = "🛸 Stardust Drone",
			Speed           = 19,
			SightRange      = 38,
			AttackRange     = 6,
			ScatterCount    = 1,
			Color           = Color3.fromRGB(0, 220, 255),
			Size            = Vector3.new(3, 4, 3),
		}
	},
	Zone2 = {
		Name          = "Solar Expanse (Tier 2 - Rare)",
		Color         = Color3.fromRGB(255, 170, 0),
		LightColor    = Color3.fromRGB(255, 140, 20),
		Center        = Vector3.new(75, 4, -20),
		Size          = Vector3.new(110, 4, 110),
		MinSpeedToRun = 26,
		EggTiers      = { "Silver", "Silver", "Gold" },
		Monster = {
			Name            = "🔥 Solar Fiend",
			Speed           = 25,
			SightRange      = 42,
			AttackRange     = 7,
			ScatterCount    = 2,
			Color           = Color3.fromRGB(255, 140, 0),
			Size            = Vector3.new(4, 5.5, 4),
		}
	},
	Zone3 = {
		Name          = "Void Nebula (Tier 3 - Epic)",
		Color         = Color3.fromRGB(180, 50, 255),
		LightColor    = Color3.fromRGB(190, 40, 255),
		Center        = Vector3.new(0, 6, 85),
		Size          = Vector3.new(140, 4, 100),
		MinSpeedToRun = 33,
		EggTiers      = { "Silver", "Gold", "Gold", "Chronos" },
		Monster = {
			Name            = "🔮 Void Reaper",
			Speed           = 32,
			SightRange      = 48,
			AttackRange     = 8,
			ScatterCount    = 3,
			Color           = Color3.fromRGB(190, 40, 255),
			Size            = Vector3.new(4.5, 6.5, 4.5),
		}
	},
	Zone4 = {
		Name          = "THE CHRONOS CORE (Tier 4 - Legendary)",
		Color         = Color3.fromRGB(255, 30, 120),
		LightColor    = Color3.fromRGB(255, 40, 140),
		Center        = Vector3.new(0, 14, 0),
		Size          = Vector3.new(65, 8, 65),
		MinSpeedToRun = 40,
		EggTiers      = { "Gold", "Chronos", "Chronos" },
		Monster = {
			Name            = "👑 CHRONOS TITAN PRIME",
			Speed           = 38,
			SightRange      = 55,
			AttackRange     = 10,
			ScatterCount    = 4,
			Color           = Color3.fromRGB(255, 30, 80),
			Size            = Vector3.new(6, 9, 6),
		}
	},
}

------------------------------------------------------------
-- REBIRTH PROGRESSION SYSTEM
------------------------------------------------------------
Config.REBIRTH = {
	BaseEggCost       = 100,     -- Cost for Rebirth 1
	CostMultiplier    = 2.5,     -- Multiplier per rebirth
	SpeedReqBase      = 4,       -- Requires Speed Level 4 for Rebirth 1
	SpeedReqInc       = 1,       -- +1 Speed Level required per rebirth
	MultiplierPerReb  = 1.5,     -- +150% Egg Value per Rebirth (Permanent)
}

function Config.GetRebirthCost(currentRebirths)
	local cost = math.floor(Config.REBIRTH.BaseEggCost * (Config.REBIRTH.CostMultiplier ^ currentRebirths))
	local speedReq = Config.REBIRTH.SpeedReqBase + (currentRebirths * Config.REBIRTH.SpeedReqInc)
	return cost, speedReq
end

------------------------------------------------------------
-- EGG TIERS & 3D MESH
------------------------------------------------------------
Config.EGG_MESH_ID         = "rbxassetid://705225654"
Config.GALAXY_TEXTURE      = "rbxassetid://171410628"

Config.EGG_TIERS = {
	Common = {
		Name        = "Stardust Egg",
		Color       = Color3.fromRGB(120, 200, 255),
		Value       = 1,
		Scale       = Vector3.new(1.1, 1.4, 1.1),
		ParticleClr = ColorSequence.new(Color3.fromRGB(100, 220, 255), Color3.fromRGB(200, 150, 255)),
		SoundPitch  = 1.0,
	},
	Silver = {
		Name        = "Supernova Egg",
		Color       = Color3.fromRGB(180, 100, 255),
		Value       = 4,
		Scale       = Vector3.new(1.3, 1.7, 1.3),
		ParticleClr = ColorSequence.new(Color3.fromRGB(220, 100, 255), Color3.fromRGB(0, 255, 255)),
		SoundPitch  = 1.18,
	},
	Gold = {
		Name        = "Solar Flare Egg",
		Color       = Color3.fromRGB(255, 200, 40),
		Value       = 14,
		Scale       = Vector3.new(1.6, 2.1, 1.6),
		ParticleClr = ColorSequence.new(Color3.fromRGB(255, 220, 50), Color3.fromRGB(255, 80, 0)),
		SoundPitch  = 1.35,
	},
	Chronos = {
		Name        = "🌌 GALACTIC CHRONOS EGG",
		Color       = Color3.fromRGB(255, 40, 200),
		Value       = 60,
		Scale       = Vector3.new(2.4, 3.2, 2.4),
		ParticleClr = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 180)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 215, 0)),
		}),
		SoundPitch  = 1.6,
	},
}

------------------------------------------------------------
-- PLAYER HATCHERY PLOTS
------------------------------------------------------------
Config.MAX_PLOTS = 6
Config.HATCH_COST = 10 -- Eggs needed to hatch
Config.HATCH_REWARDS = {
	MinCoins = 25,
	MaxCoins = 150,
}

------------------------------------------------------------
-- AUDIO
------------------------------------------------------------
Config.SOUNDS = {
	EggPickup   = "rbxassetid://9069609200",
	DepositBank = "rbxassetid://9069609268",
	UpgradeBuy  = "rbxassetid://9069609074",
	JumpPad     = "rbxassetid://9114223170",
	BackpackFull= "rbxassetid://9069609124",
	EnemyAlert  = "rbxassetid://9069609124",
	EnemyAttack = "rbxassetid://9114223170",
	RebirthSFX  = "rbxassetid://9069609074",
	HatchCrack  = "rbxassetid://9069609200",
	HatchBurst  = "rbxassetid://9069609268",
	MusicLoop   = "rbxassetid://9043887091",
}

------------------------------------------------------------
-- UPGRADES (Rebalanced for Speed Progression)
------------------------------------------------------------
Config.UPGRADES = {
	Speed = {
		DisplayName   = "Hyper Speed",
		Icon          = "⚡",
		BaseValue     = 18,
		Increment     = 3,
		MaxLevel      = 12, -- Max WalkSpeed = 18 + 36 = 54! Can outrun all monsters
		BaseCost      = 6,
		CostMult      = 1.45,
		Description   = "+3 WalkSpeed to outpace zone guardians",
	},
	Backpack = {
		DisplayName   = "Cosmic Backpack",
		Icon          = "🎒",
		BaseValue     = 3,
		Increment     = 2,
		MaxLevel      = 8,
		BaseCost      = 10,
		CostMult      = 1.65,
		Description   = "+2 Egg carry capacity before banking",
	},
	Multiplier = {
		DisplayName   = "Vault Multiplier",
		Icon          = "💎",
		BaseValue     = 1,
		Increment     = 1,
		MaxLevel      = 6,
		BaseCost      = 18,
		CostMult      = 2.1,
		Description   = "+1x multiplier on all deposited eggs",
	},
	Jump = {
		DisplayName   = "Anti-Gravity Boots",
		Icon          = "🦘",
		BaseValue     = 50,
		Increment     = 10,
		MaxLevel      = 5,
		BaseCost      = 12,
		CostMult      = 1.6,
		Description   = "+10 JumpPower for high vault areas",
	},
}

function Config.GetCost(upgradeType, currentLevel)
	local up = Config.UPGRADES[upgradeType]
	if not up or currentLevel >= up.MaxLevel then
		return math.huge
	end
	return math.floor(up.BaseCost * (up.CostMult ^ currentLevel))
end

Config.DATA_STORE_NAME     = "ChronosVault_Rebirth_v5"
Config.AUTO_SAVE_INTERVAL  = 120

return Config
