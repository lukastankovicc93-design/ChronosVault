--[[
    GameManager.server.lua (ServerScriptService)
    Chronos Vault: Core Game Loop & Steal-the-Egg Mechanics
    - Backpack carrying system with visual eggs stacked on player's back
    - Multi-tier egg spawning with smooth floating/bobbing rotation & sparkle auras
    - The Great Deposit Vault (bank eggs for currency with multipliers)
    - Full RemoteEvent synchronization (HUD, sounds, floating reward numbers)
    - Background music player
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local Config     = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DataModule = require(script.Parent:WaitForChild("DataStoreModule"))

------------------------------------------------------------
-- REMOTE EVENTS
------------------------------------------------------------
local function getOrCreateRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local BuyUpgradeEvent = getOrCreateRemote("BuyUpgrade")
local SyncDataEvent   = getOrCreateRemote("SyncData")
local StatusEvent     = getOrCreateRemote("RoundStatus")
local EggEffectEvent  = getOrCreateRemote("EggEffect")  -- Floating 3D text / sound

------------------------------------------------------------
-- FOLDERS & AUDIO
------------------------------------------------------------
local eggFolder = workspace:FindFirstChild("EggSpawns") or Instance.new("Folder")
eggFolder.Name = "EggSpawns"
eggFolder.Parent = workspace

-- Background Music Loop
local bgMusic = workspace:FindFirstChild("ChronosBGM") or Instance.new("Sound")
bgMusic.Name = "ChronosBGM"
bgMusic.SoundId = Config.SOUNDS.MusicLoop
bgMusic.Volume = 0.35
bgMusic.Looped = true
bgMusic.Parent = workspace
if not bgMusic.IsPlaying then
	bgMusic:Play()
end

------------------------------------------------------------
-- PLAYER BACKPACK STATE (In-Memory)
------------------------------------------------------------
-- [userId] = { Count = 0, Value = 0, Visuals = {} }
local playerBackpacks = {}

local function getCapacity(player: Player)
	local data = DataModule.Get(player)
	local bpLvl = data.BackpackLevel or 0
	return Config.BASE_CAPACITY + (bpLvl * Config.CAPACITY_INCREMENT)
end

local function updateBackpackVisuals(player: Player)
	local bp = playerBackpacks[player.UserId]
	if not bp then return end

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Clear old attached egg parts
	for _, part in ipairs(bp.Visuals or {}) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	bp.Visuals = {}

	-- Stack carried eggs vertically on player's back
	for i = 1, bp.Count do
		local visualEgg = Instance.new("Part")
		visualEgg.Name = "CarriedEgg_" .. i
		visualEgg.Shape = Enum.PartType.Ball
		visualEgg.Size = Vector3.new(1.1, 1.4, 1.1)
		visualEgg.Color = Color3.fromRGB(255, 215, 0)
		visualEgg.Material = Enum.Material.Neon
		visualEgg.CanCollide = false
		visualEgg.Massless = true
		visualEgg.Parent = char

		local weld = Instance.new("WeldConstraint")
		visualEgg.CFrame = hrp.CFrame * CFrame.new(0, -0.4 + (i * 1.3), 1.1)
		weld.Part0 = hrp
		weld.Part1 = visualEgg
		weld.Parent = visualEgg

		table.insert(bp.Visuals, visualEgg)
	end
end

------------------------------------------------------------
-- STAT APPLICATION
------------------------------------------------------------
local function applyStats(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end

	local data = DataModule.Get(player)
	hum.WalkSpeed = Config.UPGRADES.Speed.BaseValue + (data.SpeedLevel * Config.UPGRADES.Speed.Increment)
	hum.UseJumpPower = true
	hum.JumpPower = Config.UPGRADES.Jump.BaseValue + (data.JumpLevel * Config.UPGRADES.Jump.Increment)

	updateBackpackVisuals(player)
end

------------------------------------------------------------
-- PLAYER SETUP
------------------------------------------------------------
local function setupPlayer(player: Player)
	local data = DataModule.Load(player)

	playerBackpacks[player.UserId] = {
		Count = 0,
		Value = 0,
		Visuals = {},
	}

	-- Leaderstats (Visible in player list)
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

	player.CharacterAdded:Connect(function(char)
		applyStats(player, char)
	end)

	if player.Character then
		applyStats(player, player.Character)
	end

	-- Sync state to client
	local payload = {
		Eggs            = data.Eggs,
		TotalEggs       = data.TotalEggs,
		SpeedLevel      = data.SpeedLevel,
		BackpackLevel   = data.BackpackLevel,
		MultiplierLevel = data.MultiplierLevel,
		JumpLevel       = data.JumpLevel,
		CarriedCount    = 0,
		CarriedValue    = 0,
		Capacity        = getCapacity(player),
	}
	SyncDataEvent:FireClient(player, payload)
end

local function teardownPlayer(player: Player)
	DataModule.Save(player)
	DataModule.RemoveCache(player)
	playerBackpacks[player.UserId] = nil
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(teardownPlayer)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end

------------------------------------------------------------
-- SHOP TRANSACTIONS
------------------------------------------------------------
BuyUpgradeEvent.OnServerEvent:Connect(function(player: Player, upKey: string)
	local upDef = Config.UPGRADES[upKey]
	if not upDef then return end

	local data = DataModule.Get(player)
	local lvlKey = upKey .. "Level"
	local curLvl = data[lvlKey] or 0
	if curLvl >= upDef.MaxLevel then return end

	local cost = Config.GetCost(upKey, curLvl)
	if DataModule.SpendEggs(player, cost) then
		data = DataModule.Get(player)
		data[lvlKey] = curLvl + 1
		DataModule.Set(player, data)

		if player.Character then
			applyStats(player, player.Character)
		end

		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Eggs") then
			ls.Eggs.Value = data.Eggs
		end

		local bp = playerBackpacks[player.UserId] or { Count = 0, Value = 0 }
		local payload = {
			Eggs            = data.Eggs,
			TotalEggs       = data.TotalEggs,
			SpeedLevel      = data.SpeedLevel,
			BackpackLevel   = data.BackpackLevel,
			MultiplierLevel = data.MultiplierLevel,
			JumpLevel       = data.JumpLevel,
			CarriedCount    = bp.Count,
			CarriedValue    = bp.Value,
			Capacity        = getCapacity(player),
		}
		SyncDataEvent:FireClient(player, payload)

		-- Play upgrade chime
		EggEffectEvent:FireClient(player, "PlaySound", Config.SOUNDS.UpgradeBuy, 1.0)
	end
end)

------------------------------------------------------------
-- THE DEPOSIT VAULT HOOK
------------------------------------------------------------
task.spawn(function()
	local pad = workspace:WaitForChild("ChronosMap", 15)
	if pad then pad = pad:WaitForChild("Lobby", 15) end
	if pad then pad = pad:WaitForChild("DepositPad", 15) end
	if not pad then return end

	local depositDebounce = {}
	pad.Touched:Connect(function(hit)
		local char = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if not player or depositDebounce[player] then return end

		local bp = playerBackpacks[player.UserId]
		if bp and bp.Count > 0 then
			depositDebounce[player] = true

			local data = DataModule.Get(player)
			local mult = 1 + ((data.MultiplierLevel or 0) * Config.UPGRADES.Multiplier.Increment)
			local bankedTotal = bp.Value * mult

			-- Credit player
			DataModule.AddEggs(player, bankedTotal)
			data = DataModule.Get(player)

			local depositedCount = bp.Count
			bp.Count = 0
			bp.Value = 0
			updateBackpackVisuals(player)

			-- Update leaderstats
			local ls = player:FindFirstChild("leaderstats")
			if ls then
				if ls:FindFirstChild("Eggs") then ls.Eggs.Value = data.Eggs end
				if ls:FindFirstChild("Total") then ls.Total.Value = data.TotalEggs end
			end

			-- Fire client sound & visual burst
			EggEffectEvent:FireClient(player, "DepositSuccess", bankedTotal, depositedCount)

			-- Full sync
			local payload = {
				Eggs            = data.Eggs,
				TotalEggs       = data.TotalEggs,
				SpeedLevel      = data.SpeedLevel,
				BackpackLevel   = data.BackpackLevel,
				MultiplierLevel = data.MultiplierLevel,
				JumpLevel       = data.JumpLevel,
				CarriedCount    = 0,
				CarriedValue    = 0,
				Capacity        = getCapacity(player),
			}
			SyncDataEvent:FireClient(player, payload)

			task.wait(1.5)
			depositDebounce[player] = nil
		end
	end)
end)

------------------------------------------------------------
-- JUICY EGG SPAWN & ANIMATION ENGINE
------------------------------------------------------------
local function pickRandomTier()
	local roll = math.random(1, 100)
	if roll <= 60 then
		return "Common"
	elseif roll <= 85 then
		return "Silver"
	elseif roll <= 97 then
		return "Gold"
	else
		return "Chronos"
	end
end

local function spawnEgg(pos: Vector3, forcedTier: string?)
	local tierKey = forcedTier or pickRandomTier()
	local tierDef = Config.EGG_TIERS[tierKey]

	local egg = Instance.new("Part")
	egg.Name = "Egg_" .. tierKey
	egg.Shape = Enum.PartType.Ball
	egg.Size = tierDef.Size
	egg.Position = pos
	egg.Anchored = true
	egg.CanCollide = false
	egg.Color = tierDef.Color
	egg.Material = Enum.Material.Neon
	egg.Parent = eggFolder

	-- PointLight Aura
	local light = Instance.new("PointLight")
	light.Color = tierDef.Color
	light.Range = (tierKey == "Chronos") and 18 or 10
	light.Brightness = 2.5
	light.Parent = egg

	-- Sparkle Particles
	local pe = Instance.new("ParticleEmitter")
	pe.Color = tierDef.ParticleClr
	pe.Size = NumberSequence.new(0.5, 0.1)
	pe.Lifetime = NumberRange.new(0.8, 1.4)
	pe.Rate = (tierKey == "Chronos") and 30 or 12
	pe.Speed = NumberRange.new(2, 5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = egg

	-- 3D Name Tag above Egg
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 150, 0, 40)
	bg.StudsOffset = Vector3.new(0, tierDef.Size.Y + 0.8, 0)
	bg.AlwaysOnTop = false
	bg.Adornee = egg
	bg.Parent = egg

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = tierDef.Color
	tl.TextStrokeTransparency = 0.2
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.Text = tierDef.Name
	tl.Parent = bg

	-- Smooth Floating / Bobbing & Rotating animation
	local basePosY = pos.Y
	local startTime = tick() + math.random() * 5
	local rotConnection
	rotConnection = RunService.Heartbeat:Connect(function()
		if not egg or not egg.Parent then
			rotConnection:Disconnect()
			return
		end
		local elapsed = tick() - startTime
		local bobOffset = math.sin(elapsed * 3) * 0.7
		egg.CFrame = CFrame.new(pos.X, basePosY + bobOffset, pos.Z) * CFrame.Angles(0, elapsed * 2.2, 0)
	end)

	-- Pickup Touch Listener
	local collected = false
	egg.Touched:Connect(function(hit)
		if collected then return end
		local char = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if not player then return end

		local bp = playerBackpacks[player.UserId]
		local maxCap = getCapacity(player)

		if bp and bp.Count >= maxCap then
			-- Alert Backpack Full!
			EggEffectEvent:FireClient(player, "BackpackFull")
			return
		end

		collected = true
		rotConnection:Disconnect()

		-- Add to carried backpack
		bp.Count += 1
		bp.Value += tierDef.Value
		updateBackpackVisuals(player)

		-- Fire juicy client effects
		EggEffectEvent:FireClient(player, "EggCollected", tierDef.Name, tierDef.Value, tierDef.SoundPitch, egg.Position)

		local data = DataModule.Get(player)
		local payload = {
			Eggs            = data.Eggs,
			TotalEggs       = data.TotalEggs,
			SpeedLevel      = data.SpeedLevel,
			BackpackLevel   = data.BackpackLevel,
			MultiplierLevel = data.MultiplierLevel,
			JumpLevel       = data.JumpLevel,
			CarriedCount    = bp.Count,
			CarriedValue    = bp.Value,
			Capacity        = maxCap,
		}
		SyncDataEvent:FireClient(player, payload)

		-- Juicy Pop & Shrink Tween
		pe:Emit(25)
		light.Brightness = 6
		local tw = TweenService:Create(egg, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = Vector3.new(0.1, 0.1, 0.1),
			Transparency = 1,
		})
		tw:Play()
		tw.Completed:Connect(function()
			egg:Destroy()
		end)
	end)

	return egg
end

local function spawnArenaEggs()
	for _, child in ipairs(eggFolder:GetChildren()) do
		child:Destroy()
	end

	-- 1. Standard Arena Eggs
	for _ = 1, Config.EGGS_PER_ROUND do
		local pos = Vector3.new(
			math.random(-75, 75),
			3.5,
			math.random(-75, 75)
		)
		spawnEgg(pos)
	end

	-- 2. Tower Tops (High value guaranteed)
	local towerTops = {
		Vector3.new(62, 14, 62),
		Vector3.new(-62, 14, 62),
		Vector3.new(62, 14, -62),
		Vector3.new(-62, 14, -62),
	}
	for _, tPos in ipairs(towerTops) do
		spawnEgg(tPos, "Gold")
	end

	-- 3. Central Core Pedestal (Legendary Chronos Egg)
	local corePos = Config.VAULT_CORE_POS + Vector3.new(0, 7.5, 0)
	spawnEgg(corePos, "Chronos")
end

------------------------------------------------------------
-- ROUND CYCLE
------------------------------------------------------------
local function broadcast(msg)
	StatusEvent:FireAllClients(msg)
end

task.spawn(function()
	while true do
		-- INTERMISSION
		broadcast("⏳ Intermission... Upgrade & Deposit at Bank!")
		task.wait(Config.INTERMISSION)

		-- ROUND START
		broadcast("🚨 VAULT BREACH! Steal eggs & escape to the Bank!")
		spawnArenaEggs()

		-- COUNTDOWN
		for t = Config.ROUND_DURATION, 1, -1 do
			broadcast("⚡ Time Left: " .. t .. "s | Return to Bank!")
			task.wait(1)
		end

		-- ROUND OVER
		broadcast("🏁 Round Over! Deposit your loot!")
		task.wait(3)
	end
end)

print("[ChronosVault] GameManager with Real Steal-the-Egg Core Loop Loaded ✓")
