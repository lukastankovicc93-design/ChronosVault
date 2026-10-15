--[[
    GameManager.server.lua (ServerScriptService)
    Core server loop:
    - Player stat management (WalkSpeed, JumpPower, Multipliers)
    - Full upgrade shop transactions (Speed, Multiplier, Jump, Magnet)
    - Round lifecycle with Arena Egg Spawning (Normal + Core Eggs)
    - Safe-zone leaderstats & data sync
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Config     = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DataModule = require(script.Parent:WaitForChild("DataStoreModule"))

------------------------------------------------------------
-- REMOTE EVENTS
------------------------------------------------------------
local function getOrCreate(name, className)
	local obj = ReplicatedStorage:FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = ReplicatedStorage
	end
	return obj
end

local BuyUpgradeEvent = getOrCreate("BuyUpgrade", "RemoteEvent")
local SyncDataEvent   = getOrCreate("SyncData", "RemoteEvent")
local StatusEvent     = getOrCreate("RoundStatus", "RemoteEvent")
local EggCountEvent   = getOrCreate("EggCount", "RemoteEvent")
local SpeedLevelEvent = getOrCreate("SpeedLevel", "RemoteEvent")

------------------------------------------------------------
-- EGG CONTAINER
------------------------------------------------------------
local eggFolder = workspace:FindFirstChild("EggSpawns") or Instance.new("Folder")
eggFolder.Name = "EggSpawns"
eggFolder.Parent = workspace

------------------------------------------------------------
-- CHARACTER STAT APPLICATION
------------------------------------------------------------
local function applyCharacterStats(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end

	local data = DataModule.Get(player)
	local speedCfg = Config.UPGRADES.Speed
	local jumpCfg  = Config.UPGRADES.Jump

	hum.WalkSpeed = speedCfg.BaseValue + (data.SpeedLevel * speedCfg.Increment)
	hum.UseJumpPower = true
	hum.JumpPower = jumpCfg.BaseValue + (data.JumpLevel * jumpCfg.Increment)
end

------------------------------------------------------------
-- PLAYER SETUP
------------------------------------------------------------
local function setupPlayer(player: Player)
	local data = DataModule.Load(player)

	-- Leaderstats (Visible in Roblox Tab list)
	local ls = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local eggsVal = ls:FindFirstChild("Eggs") or Instance.new("IntValue")
	eggsVal.Name = "Eggs"
	eggsVal.Value = data.Eggs
	eggsVal.Parent = ls

	local totalVal = ls:FindFirstChild("Total") or Instance.new("IntValue")
	totalVal.Name = "Total"
	totalVal.Value = data.TotalEggs
	totalVal.Parent = ls

	-- Hook character spawning
	player.CharacterAdded:Connect(function(char)
		applyCharacterStats(player, char)
	end)

	if player.Character then
		applyCharacterStats(player, player.Character)
	end

	-- Initial sync
	SyncDataEvent:FireClient(player, data)
	EggCountEvent:FireClient(player, data.Eggs)
	SpeedLevelEvent:FireClient(player, data.SpeedLevel)
end

local function teardownPlayer(player: Player)
	DataModule.Save(player)
	DataModule.RemoveCache(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(teardownPlayer)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end

------------------------------------------------------------
-- SHOP TRANSACTIONS (BuyUpgrade)
------------------------------------------------------------
BuyUpgradeEvent.OnServerEvent:Connect(function(player: Player, upgradeType: string)
	local upDef = Config.UPGRADES[upgradeType]
	if not upDef then return end

	local data = DataModule.Get(player)
	local levelKey = upgradeType .. "Level"
	local currentLvl = data[levelKey] or 0

	if currentLvl >= upDef.MaxLevel then return end

	local cost = Config.GetCost(upgradeType, currentLvl)

	if DataModule.SpendEggs(player, cost) then
		data = DataModule.Get(player)
		data[levelKey] = currentLvl + 1
		DataModule.Set(player, data)

		-- Apply immediate in-game stat changes
		if player.Character then
			applyCharacterStats(player, player.Character)
		end

		-- Update leaderstats
		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Eggs") then
			ls.Eggs.Value = data.Eggs
		end

		-- Full sync back to client
		SyncDataEvent:FireClient(player, data)
		EggCountEvent:FireClient(player, data.Eggs)
		SpeedLevelEvent:FireClient(player, data.SpeedLevel)
	end
end)

------------------------------------------------------------
-- EGG SPAWN LOGIC
------------------------------------------------------------
local function spawnEggInstance(pos: Vector3, isCoreEgg: boolean)
	local egg = Instance.new("Part")
	egg.Name = isCoreEgg and "CoreVaultEgg" or "VaultEgg"
	egg.Shape = Enum.PartType.Ball
	egg.Size = isCoreEgg and (Config.EGG_SIZE * 1.4) or Config.EGG_SIZE
	egg.Position = pos
	egg.Anchored = true
	egg.CanCollide = false
	egg.Color = isCoreEgg and Config.CORE_EGG_COLOR or Config.EGG_COLOR
	egg.Material = Enum.Material.Neon
	egg.Parent = eggFolder

	-- Light & Highlight
	local light = Instance.new("PointLight")
	light.Color = egg.Color
	light.Range = isCoreEgg and 18 or 10
	light.Brightness = 2
	light.Parent = egg

	-- Touch pickup
	local collected = false
	egg.Touched:Connect(function(hit)
		if collected then return end
		local char = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if not player then return end

		collected = true

		local data = DataModule.Get(player)
		local multLvl = data.MultiplierLevel or 0
		local mult = 1 + (multLvl * Config.UPGRADES.Multiplier.Increment)
		local baseGained = isCoreEgg and Config.CORE_EGG_MULT or 1
		local totalGained = baseGained * mult

		DataModule.AddEggs(player, totalGained)
		data = DataModule.Get(player)

		-- Update leaderstats
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			if ls:FindFirstChild("Eggs") then ls.Eggs.Value = data.Eggs end
			if ls:FindFirstChild("Total") then ls.Total.Value = data.TotalEggs end
		end

		SyncDataEvent:FireClient(player, data)
		EggCountEvent:FireClient(player, data.Eggs)

		-- Pop animation
		local tween = TweenService:Create(egg, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = Vector3.new(0.1, 0.1, 0.1),
			Transparency = 1,
		})
		tween:Play()
		tween.Completed:Connect(function()
			egg:Destroy()
		end)
	end)

	return egg
end

local function spawnRoundEggs()
	-- 1. Standard arena eggs
	local min = Config.SPAWN_MIN
	local max = Config.SPAWN_MAX
	for _ = 1, Config.EGGS_PER_ROUND do
		local pos = Vector3.new(
			math.random(min.X, max.X),
			min.Y,
			math.random(min.Z, max.Z)
		)
		spawnEggInstance(pos, false)
	end

	-- 2. Tower eggs
	local towerTops = {
		Vector3.new(60, 12, 60),
		Vector3.new(-60, 12, 60),
		Vector3.new(60, 12, -60),
		Vector3.new(-60, 12, -60),
	}
	for _, tPos in ipairs(towerTops) do
		spawnEggInstance(tPos, false)
	end

	-- 3. Core Vault Rare Eggs in the center dais
	local corePos = Config.VAULT_CORE_POS + Vector3.new(0, 3, 0)
	spawnEggInstance(corePos, true)
	spawnEggInstance(corePos + Vector3.new(5, 0, 5), true)
	spawnEggInstance(corePos + Vector3.new(-5, 0, -5), true)
end

local function clearEggs()
	for _, child in ipairs(eggFolder:GetChildren()) do
		child:Destroy()
	end
end

------------------------------------------------------------
-- ROUND LOOP
------------------------------------------------------------
local function broadcastStatus(msg: string)
	StatusEvent:FireAllClients(msg)
end

task.spawn(function()
	while true do
		-- INTERMISSION
		broadcastStatus("⏳ Intermission... Visit Shops in Lobby!")
		clearEggs()
		task.wait(Config.INTERMISSION)

		-- ROUND START
		broadcastStatus("🚨 Vault Breach! Collect eggs & beware!")
		spawnRoundEggs()

		-- COUNTDOWN
		for t = Config.ROUND_DURATION, 1, -1 do
			broadcastStatus("⚡ Round Active: " .. t .. "s left")
			task.wait(1)
		end

		-- ROUND OVER
		broadcastStatus("🏁 Round Over! Returning to Safe Zone...")
		clearEggs()
		task.wait(3)
	end
end)

print("[ChronosVault] GameManager with multi-shop support loaded ✓")
