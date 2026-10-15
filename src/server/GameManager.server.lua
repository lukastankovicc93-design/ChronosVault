--[[
    GameManager.server.lua (ServerScriptService)
    Core server script — manages:
    - Round lifecycle (intermission → spawn eggs → collect phase → cleanup)
    - Egg spawning & collection via touched
    - Speed upgrade purchase via RemoteEvent
    - Leaderstats
]]

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config     = require(ReplicatedStorage.Shared.Config)
local DataModule = require(script.Parent.DataStoreModule)

------------------------------------------------------------
-- REMOTE EVENTS (created once at startup)
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

local BuySpeedEvent   = getOrCreate("BuySpeed", "RemoteEvent")
local StatusEvent     = getOrCreate("RoundStatus", "RemoteEvent")
local EggCountEvent   = getOrCreate("EggCount", "RemoteEvent")
local SpeedLevelEvent = getOrCreate("SpeedLevel", "RemoteEvent")

------------------------------------------------------------
-- EGG FOLDER
------------------------------------------------------------
local eggFolder = workspace:FindFirstChild("EggSpawns") or Instance.new("Folder")
eggFolder.Name = "EggSpawns"
eggFolder.Parent = workspace

------------------------------------------------------------
-- PLAYER SETUP
------------------------------------------------------------
local function setupPlayer(player: Player)
	-- Load data
	local data = DataModule.Load(player)

	-- Leaderstats
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local eggsVal = Instance.new("IntValue")
	eggsVal.Name = "Eggs"
	eggsVal.Value = data.Eggs
	eggsVal.Parent = ls

	local totalVal = Instance.new("IntValue")
	totalVal.Name = "Total"
	totalVal.Value = data.TotalEggs
	totalVal.Parent = ls

	-- Apply saved speed
	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		hum.WalkSpeed = Config.BASE_WALK_SPEED + (data.SpeedLevel * Config.SPEED_INCREMENT)
	end)

	-- Sync client
	SpeedLevelEvent:FireClient(player, data.SpeedLevel)
	EggCountEvent:FireClient(player, data.Eggs)
end

local function teardownPlayer(player: Player)
	DataModule.Save(player)
	DataModule.RemoveCache(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(teardownPlayer)

-- Handle players already in game (Studio fast-start)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end

------------------------------------------------------------
-- SPEED UPGRADE HANDLER
------------------------------------------------------------
BuySpeedEvent.OnServerEvent:Connect(function(player: Player)
	local data = DataModule.Get(player)
	if data.SpeedLevel >= Config.MAX_SPEED_LEVEL then return end

	local cost = math.floor(Config.SPEED_COST_BASE * (Config.SPEED_COST_MULT ^ data.SpeedLevel))

	if DataModule.SpendEggs(player, cost) then
		data = DataModule.Get(player)
		data.SpeedLevel += 1
		DataModule.Set(player, data)

		-- Apply speed immediately
		local char = player.Character
		if char then
			local hum = char:FindFirstChild("Humanoid")
			if hum then
				hum.WalkSpeed = Config.BASE_WALK_SPEED + (data.SpeedLevel * Config.SPEED_INCREMENT)
			end
		end

		-- Update leaderstats & client
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			ls.Eggs.Value = data.Eggs
		end

		SpeedLevelEvent:FireClient(player, data.SpeedLevel)
		EggCountEvent:FireClient(player, data.Eggs)
	end
end)

------------------------------------------------------------
-- EGG SPAWNING
------------------------------------------------------------
local function spawnEgg()
	local min = Config.SPAWN_MIN
	local max = Config.SPAWN_MAX
	local pos = Vector3.new(
		math.random(min.X, max.X),
		min.Y,
		math.random(min.Z, max.Z)
	)

	local egg = Instance.new("Part")
	egg.Name = "Egg"
	egg.Shape = Enum.PartType.Ball
	egg.Size = Config.EGG_SIZE
	egg.Position = pos
	egg.Anchored = true
	egg.CanCollide = false
	egg.Color = Config.EGG_COLOR
	egg.Material = Enum.Material.Neon
	egg.Parent = eggFolder

	-- Touch detection
	local collected = false
	egg.Touched:Connect(function(hit)
		if collected then return end
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		collected = true

		-- Give egg
		DataModule.AddEggs(player, 1)
		local data = DataModule.Get(player)

		-- Update leaderstats
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			ls.Eggs.Value = data.Eggs
			ls.Total.Value = data.TotalEggs
		end

		EggCountEvent:FireClient(player, data.Eggs)

		-- Destroy egg with quick shrink tween
		local TweenService = game:GetService("TweenService")
		local tween = TweenService:Create(egg, TweenInfo.new(0.2), {Size = Vector3.new(0.1, 0.1, 0.1)})
		tween:Play()
		tween.Completed:Connect(function()
			egg:Destroy()
		end)
	end)

	return egg
end

local function clearEggs()
	for _, child in ipairs(eggFolder:GetChildren()) do
		child:Destroy()
	end
end

------------------------------------------------------------
-- ROUND LOOP
------------------------------------------------------------
local function broadcastStatus(message: string)
	StatusEvent:FireAllClients(message)
end

task.spawn(function()
	while true do
		-- INTERMISSION
		broadcastStatus("Intermission...")
		clearEggs()
		task.wait(Config.INTERMISSION)

		-- SPAWN EGGS
		broadcastStatus("Round started! Collect eggs!")
		for _ = 1, Config.EGGS_PER_ROUND do
			spawnEgg()
		end

		-- ROUND TIMER
		for t = Config.ROUND_DURATION, 1, -1 do
			broadcastStatus("Time left: " .. t .. "s")
			task.wait(1)
		end

		-- ROUND END
		broadcastStatus("Round over!")
		clearEggs()
		task.wait(3)
	end
end)

print("[ChronosVault] GameManager loaded ✓")
