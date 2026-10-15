--[[
    GameManager.server.lua (ServerScriptService)
    Chronos Vault: Galactic Steal-the-Egg Core Engine
    - True 3D Egg Models (Official Egg Hunt Mesh + Cosmic Galaxy Skins)
    - Egg Scatter Mechanic (Sentinels knock loose carried eggs upon tackle!)
    - Backpack carrying system with visual eggs stacked on player's back
    - The Great Deposit Vault (Bank eggs for currency with multipliers)
    - Sound FX & Full RemoteEvent synchronization
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local Config     = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local DataModule = require(script.Parent:WaitForChild("DataStoreModule"))

------------------------------------------------------------
-- REMOTE & BINDABLE EVENTS
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
local EggEffectEvent  = getOrCreateRemote("EggEffect")

local ScatterEvent = ReplicatedStorage:FindFirstChild("ScatterEggs")
if not ScatterEvent then
	ScatterEvent = Instance.new("BindableEvent")
	ScatterEvent.Name = "ScatterEggs"
	ScatterEvent.Parent = ReplicatedStorage
end

------------------------------------------------------------
-- FOLDERS & AMBIENT MUSIC
------------------------------------------------------------
local eggFolder = workspace:FindFirstChild("EggSpawns") or Instance.new("Folder")
eggFolder.Name = "EggSpawns"
eggFolder.Parent = workspace

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
-- PLAYER BACKPACK STATE
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

	for _, part in ipairs(bp.Visuals or {}) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	bp.Visuals = {}

	-- Stack 3D carried eggs on back
	for i = 1, bp.Count do
		local visualEgg = Instance.new("Part")
		visualEgg.Name = "CarriedEgg_" .. i
		visualEgg.Size = Vector3.new(1.0, 1.3, 1.0)
		visualEgg.Color = Color3.fromRGB(255, 215, 0)
		visualEgg.Material = Enum.Material.Neon
		visualEgg.CanCollide = false
		visualEgg.Massless = true
		visualEgg.Parent = char

		-- 3D Egg Mesh for carried egg
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = Config.EGG_MESH_ID
		mesh.Scale = Vector3.new(0.9, 1.2, 0.9)
		mesh.TextureId = Config.GALAXY_TEXTURE
		mesh.Parent = visualEgg

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
		EggEffectEvent:FireClient(player, "PlaySound", Config.SOUNDS.UpgradeBuy, 1.0)
	end
end)

------------------------------------------------------------
-- FORWARD DECLARATION FOR SPAWN EGG
------------------------------------------------------------
local spawnEgg

------------------------------------------------------------
-- EGG SCATTER MECHANIC (When hit by Guardians!)
------------------------------------------------------------
ScatterEvent.Event:Connect(function(targetPlayer: Player, scatterCount: number, impactPos: Vector3)
	local bp = playerBackpacks[targetPlayer.UserId]
	if not bp or bp.Count <= 0 then return end

	local toDrop = math.min(scatterCount, bp.Count)
	local valuePerEgg = math.floor(bp.Value / bp.Count)
	bp.Count = bp.Count - toDrop
	bp.Value = bp.Value - (valuePerEgg * toDrop)

	updateBackpackVisuals(targetPlayer)

	-- Scatter loose eggs in a burst around player
	for i = 1, toDrop do
		local angle = (i / toDrop) * math.pi * 2 + math.random()
		local dropPos = impactPos + Vector3.new(math.cos(angle) * 7, 2, math.sin(angle) * 7)
		spawnEgg(dropPos, "Common")
	end

	-- Alert client & play scatter sound
	EggEffectEvent:FireClient(targetPlayer, "AttackedScatter", toDrop)

	local data = DataModule.Get(targetPlayer)
	local payload = {
		Eggs            = data.Eggs,
		TotalEggs       = data.TotalEggs,
		SpeedLevel      = data.SpeedLevel,
		BackpackLevel   = data.BackpackLevel,
		MultiplierLevel = data.MultiplierLevel,
		JumpLevel       = data.JumpLevel,
		CarriedCount    = bp.Count,
		CarriedValue    = bp.Value,
		Capacity        = getCapacity(targetPlayer),
	}
	SyncDataEvent:FireClient(targetPlayer, payload)
end)

------------------------------------------------------------
-- DEPOSIT VAULT BANK HOOK
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

			DataModule.AddEggs(player, bankedTotal)
			data = DataModule.Get(player)

			local depositedCount = bp.Count
			bp.Count = 0
			bp.Value = 0
			updateBackpackVisuals(player)

			local ls = player:FindFirstChild("leaderstats")
			if ls then
				if ls:FindFirstChild("Eggs") then ls.Eggs.Value = data.Eggs end
				if ls:FindFirstChild("Total") then ls.Total.Value = data.TotalEggs end
			end

			EggEffectEvent:FireClient(player, "DepositSuccess", bankedTotal, depositedCount)

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
-- TRUE 3D EGG SPAWN & SINE-WAVE ANIMATION
------------------------------------------------------------
local function pickRandomTier()
	local roll = math.random(1, 100)
	if roll <= 55 then
		return "Common"
	elseif roll <= 83 then
		return "Silver"
	elseif roll <= 96 then
		return "Gold"
	else
		return "Chronos"
	end
end

spawnEgg = function(pos: Vector3, forcedTier: string?)
	local tierKey = forcedTier or pickRandomTier()
	local tierDef = Config.EGG_TIERS[tierKey]

	local egg = Instance.new("Part")
	egg.Name = "Egg_" .. tierKey
	egg.Size = Vector3.new(2, 2.8, 2)
	egg.Position = pos
	egg.Anchored = true
	egg.CanCollide = false
	egg.Color = tierDef.Color
	egg.Material = Enum.Material.Neon
	egg.Parent = eggFolder

	-- Authentic 3D Roblox Egg Hunt Mesh + Cosmic Texture!
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = Config.EGG_MESH_ID
	mesh.TextureId = Config.GALAXY_TEXTURE
	mesh.Scale = tierDef.Scale
	mesh.Parent = egg

	-- PointLight Aura
	local light = Instance.new("PointLight")
	light.Color = tierDef.Color
	light.Range = (tierKey == "Chronos") and 20 or 12
	light.Brightness = 3
	light.Parent = egg

	-- Cosmic Stardust Particles
	local pe = Instance.new("ParticleEmitter")
	pe.Color = tierDef.ParticleClr
	pe.Size = NumberSequence.new(0.6, 0.1)
	pe.Lifetime = NumberRange.new(0.8, 1.5)
	pe.Rate = (tierKey == "Chronos") and 35 or 14
	pe.Speed = NumberRange.new(2, 6)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = egg

	-- 3D Name Tag
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 160, 0, 42)
	bg.StudsOffset = Vector3.new(0, tierDef.Scale.Y * 2.2 + 0.8, 0)
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

	-- Smooth Sine-Wave Bobbing & 360° Galactic Spin
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
			EggEffectEvent:FireClient(player, "BackpackFull")
			return
		end

		collected = true
		rotConnection:Disconnect()

		bp.Count += 1
		bp.Value += tierDef.Value
		updateBackpackVisuals(player)

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

		pe:Emit(25)
		light.Brightness = 7
		local tw = TweenService:Create(egg, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
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

	-- Standard Arena Eggs
	for _ = 1, Config.EGGS_PER_ROUND do
		local pos = Vector3.new(
			math.random(-75, 75),
			3.5,
			math.random(-75, 75)
		)
		spawnEgg(pos)
	end

	-- Tower Tops (Guaranteed Gold)
	local towerTops = {
		Vector3.new(62, 14, 62),
		Vector3.new(-62, 14, 62),
		Vector3.new(62, 14, -62),
		Vector3.new(-62, 14, -62),
	}
	for _, tPos in ipairs(towerTops) do
		spawnEgg(tPos, "Gold")
	end

	-- Center Vortex (Legendary Galactic Chronos Egg)
	local corePos = Config.VAULT_CORE_POS + Vector3.new(0, 7.5, 0)
	spawnEgg(corePos, "Chronos")
end

------------------------------------------------------------
-- ROUND LOOP
------------------------------------------------------------
local function broadcast(msg)
	StatusEvent:FireAllClients(msg)
end

task.spawn(function()
	while true do
		broadcast("⏳ Intermission... Upgrade & Deposit at Bank!")
		task.wait(Config.INTERMISSION)

		broadcast("🚨 VAULT BREACH! Sentinels Awakened! Steal the eggs!")
		spawnArenaEggs()

		for t = Config.ROUND_DURATION, 1, -1 do
			broadcast("⚡ Time Left: " .. t .. "s | Evade Sentinels & Bank!")
			task.wait(1)
		end

		broadcast("🏁 Round Over! Deposit your loot!")
		task.wait(3)
	end
end)

print("[ChronosVault] Galactic GameManager with 3D Egg Mesh & Scatter System Loaded ✓")
