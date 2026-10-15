--[[
    Config.lua (ReplicatedStorage.Shared)
    Chronos Vault: Galactic Overhaul Configuration
    - True 3D Egg Mesh assets & Cosmic Galactic Textures
    - Deep Space Nebula Skybox IDs
    - Chronos Sentinel Enemy AI settings (Patrol, Chase, Egg Scatter Attack)
    - Full sound library & gameplay tuning
]]

local Config = {}

------------------------------------------------------------
-- ROUND & GAMEPLAY
------------------------------------------------------------
Config.ROUND_DURATION      = 120    -- seconds per round
Config.INTERMISSION        = 12     -- seconds between rounds
Config.EGGS_PER_ROUND      = 30     -- total eggs across the arena

-- Backpack Carry System
Config.BASE_CAPACITY       = 3      -- max eggs before banking
Config.CAPACITY_INCREMENT  = 2      -- +2 capacity per backpack level

------------------------------------------------------------
-- TRUE 3D EGG MESH & COSMIC TEXTURES
------------------------------------------------------------
Config.EGG_MESH_ID         = "rbxassetid://705225654"  -- Official Roblox Egg Hunt 3D Model
Config.GALAXY_TEXTURE      = "rbxassetid://171410628"  -- Cosmic Nebula Texture

-- Galactic Space Skybox Face Textures
Config.SKYBOX = {
	Bk = "rbxassetid://171410628",
	Dn = "rbxassetid://171410649",
	Ft = "rbxassetid://171410620",
	Lf = "rbxassetid://171410666",
	Rt = "rbxassetid://171410657",
	Up = "rbxassetid://171410636",
}

------------------------------------------------------------
-- EGG TIERS (Cosmic Galactic Editions)
------------------------------------------------------------
Config.EGG_TIERS = {
	Common = {
		Name        = "Stardust Egg",
		Color       = Color3.fromRGB(120, 200, 255),
		Value       = 1,
		Weight      = 55,
		Scale       = Vector3.new(1.1, 1.4, 1.1),
		ParticleClr = ColorSequence.new(Color3.fromRGB(100, 220, 255), Color3.fromRGB(200, 150, 255)),
		SoundPitch  = 1.0,
	},
	Silver = {
		Name        = "Supernova Egg",
		Color       = Color3.fromRGB(180, 100, 255),
		Value       = 4,
		Weight      = 28,
		Scale       = Vector3.new(1.3, 1.7, 1.3),
		ParticleClr = ColorSequence.new(Color3.fromRGB(220, 100, 255), Color3.fromRGB(0, 255, 255)),
		SoundPitch  = 1.18,
	},
	Gold = {
		Name        = "Solar Flare Egg",
		Color       = Color3.fromRGB(255, 200, 40),
		Value       = 12,
		Weight      = 13,
		Scale       = Vector3.new(1.5, 2.0, 1.5),
		ParticleClr = ColorSequence.new(Color3.fromRGB(255, 220, 50), Color3.fromRGB(255, 80, 0)),
		SoundPitch  = 1.35,
	},
	Chronos = {
		Name        = "🌌 GALACTIC CHRONOS EGG",
		Color       = Color3.fromRGB(255, 40, 200),
		Value       = 50,
		Weight      = 4,
		Scale       = Vector3.new(2.2, 2.9, 2.2),
		ParticleClr = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 180)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 215, 0)),
		}),
		SoundPitch  = 1.6,
	},
}

------------------------------------------------------------
-- ENEMY CHRONOS SENTINELS (Egg Guardians)
------------------------------------------------------------
Config.ENEMIES = {
	CentralGuardian = {
		Name            = "👑 Chronos Titan",
		Size            = Vector3.new(5, 7, 5),
		WalkSpeed       = 24,
		SightRange      = 45,
		AttackRange     = 8,
		AttackCooldown  = 2.0,
		KnockbackPower  = 65,
		EggScatterCount = 3, -- Drops up to 3 carried eggs!
		Color           = Color3.fromRGB(255, 40, 80),
		PatrolRadius    = 25,
		SpawnPos        = Vector3.new(0, 12, 0), -- Central Vault
	},
	PatrolDroneA = {
		Name            = "🛸 Vault Sentinel Alpha",
		Size            = Vector3.new(3.5, 4.5, 3.5),
		WalkSpeed       = 20,
		SightRange      = 38,
		AttackRange     = 6,
		AttackCooldown  = 1.8,
		KnockbackPower  = 50,
		EggScatterCount = 2,
		Color           = Color3.fromRGB(255, 120, 0),
		PatrolRadius    = 55,
		SpawnPos        = Vector3.new(45, 6, 45),
	},
	PatrolDroneB = {
		Name            = "🛸 Vault Sentinel Beta",
		Size            = Vector3.new(3.5, 4.5, 3.5),
		WalkSpeed       = 20,
		SightRange      = 38,
		AttackRange     = 6,
		AttackCooldown  = 1.8,
		KnockbackPower  = 50,
		EggScatterCount = 2,
		Color           = Color3.fromRGB(0, 200, 255),
		PatrolRadius    = 55,
		SpawnPos        = Vector3.new(-45, 6, -45),
	},
}

------------------------------------------------------------
-- AUDIO SFX
------------------------------------------------------------
Config.SOUNDS = {
	EggPickup   = "rbxassetid://9069609200",  -- Chime / pop
	DepositBank = "rbxassetid://9069609268",  -- Big coin cascade
	UpgradeBuy  = "rbxassetid://9069609074",  -- Fanfare / level up
	JumpPad     = "rbxassetid://9114223170",  -- Kinetic whoosh
	BackpackFull= "rbxassetid://9069609124",  -- Alert buzzer
	EnemyAlert  = "rbxassetid://9069609124",  -- Sentinel alarm / target acquired
	EnemyAttack = "rbxassetid://9114223170",  -- Tackle / impact blast
	MusicLoop   = "rbxassetid://9043887091",  -- Ambient synthwave loop
}

------------------------------------------------------------
-- UPGRADES & BALANCING
------------------------------------------------------------
Config.UPGRADES = {
	Speed = {
		DisplayName   = "Hyper Speed",
		Icon          = "⚡",
		BaseValue     = 18,
		Increment     = 4,
		MaxLevel      = 10,
		BaseCost      = 6,
		CostMult      = 1.5,
		Description   = "+4 WalkSpeed to outrun Sentinels",
	},
	Backpack = {
		DisplayName   = "Cosmic Backpack",
		Icon          = "🎒",
		BaseValue     = 3,
		Increment     = 2,
		MaxLevel      = 6,
		BaseCost      = 10,
		CostMult      = 1.7,
		Description   = "+2 Egg carry capacity before banking",
	},
	Multiplier = {
		DisplayName   = "Galactic Multiplier",
		Icon          = "💎",
		BaseValue     = 1,
		Increment     = 1,
		MaxLevel      = 5,
		BaseCost      = 18,
		CostMult      = 2.2,
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
		Description   = "+10 JumpPower to leap over Guardians",
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
-- MAP POSITIONS
------------------------------------------------------------
Config.LOBBY_CENTER        = Vector3.new(0, 16, -135)
Config.VAULT_DEPOSIT_POS   = Vector3.new(0, 16.5, -115)
Config.ARENA_CENTER        = Vector3.new(0, 0, 0)
Config.VAULT_CORE_POS      = Vector3.new(0, 12, 0)

Config.DATA_STORE_NAME     = "ChronosVault_Galactic_v4"
Config.AUTO_SAVE_INTERVAL  = 120

return Config
