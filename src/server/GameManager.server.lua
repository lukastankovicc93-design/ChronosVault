--[[
    GameManager.server.lua (ServerScriptService)
    Chronos Vault: Multi-Zone Progression & Hatchery Engine
    - Multi-Zone Egg Distribution across 4 Tiered Lighted Sections
    - Dynamic Player Plot Assignment & 3D Hatchery Incubator
    - Rebirth System Handler (Progression reset with permanent multipliers)
    - Egg Scatter Mechanic upon Guardian collision
    - Full Leaderstats: Eggs, Rebirths, Total
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

local BuyUpgradeEvent     = getOrCreateRemote("BuyUpgrade")
local SyncDataEvent       = getOrCreateRemote("SyncData")
local StatusEvent         = getOrCreateRemote("RoundStatus")
local EggEffectEvent      = getOrCreateRemote("EggEffect")
local HatchEggEvent       = getOrCreateRemote("HatchEgg")
local PerformRebirthEvent = getOrCreateRemote("PerformRebirth")

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
-- PLOT ASSIGNMENT SYSTEM (6 Plots)
------------------------------------------------------------
-- [plotIndex] = player
local plotAssignments = {}
-- [userId] = plotIndex
local playerPlotMap = {}

local function assignPlot(player: Player)
	for i = 1, Config.MAX_PLOTS do
		if not plotAssignments[i] then
			plotAssignments[i] = player
			playerPlotMap[player.UserId] = i

			-- Update Plot 3D Sign
			local plotModel = workspace:FindFirstChild("ChronosMap")
			if plotModel then plotModel = plotModel:FindFirstChild("Plots") end
			if plotModel then plotModel = plotModel:FindFirstChild("Plot_" .. i) end
			if plotModel and plotModel:FindFirstChild("SignBoard") then
				local gui = plotModel.SignBoard:FindFirstChildWhichIsA("BillboardGui")
				local lbl = gui and gui:FindFirstChild("OwnerLabel")
				if lbl then
					lbl.Text = "🐣 " .. player.DisplayName .. "'s Hatchery"
					lbl.TextColor3 = Color3.fromRGB(0, 255, 170)
				end
			end
			return i
		end
	end
	return nil
end

local function releasePlot(player: Player)
	local pIdx = playerPlotMap[player.UserId]
	if pIdx then
		plotAssignments[pIdx] = nil
		playerPlotMap[player.UserId] = nil

		local plotModel = workspace:FindFirstChild("ChronosMap")
		if plotModel then plotModel = plotModel:FindFirstChild("Plots") end
		if plotModel then plotModel = plotModel:FindFirstChild("Plot_" .. pIdx) end
		if plotModel and plotModel:FindFirstChild("SignBoard") then
			local gui = plotModel.SignBoard:FindFirstChildWhichIsA("BillboardGui")
			local lbl = gui and gui:FindFirstChild("OwnerLabel")
			if lbl then
				lbl.Text = "🐣 [UNCLAIMED PLOT " .. pIdx .. "]"
				lbl.TextColor3 = Color3.fromRGB(0, 230, 255)
			end
		end
	end
end

------------------------------------------------------------
-- BACKPACK STATE
------------------------------------------------------------
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
		if part and part.Parent then part:Destroy() end
	end
	bp.Visuals = {}

	for i = 1, bp.Count do
		local visualEgg = Instance.new("Part")
		visualEgg.Name = "CarriedEgg_" .. i
		visualEgg.Size = Vector3.new(1.0, 1.3, 1.0)
		visualEgg.Color = Color3.fromRGB(255, 215, 0)
		visualEgg.Material = Enum.Material.Neon
		visualEgg.CanCollide = false
		visualEgg.Massless = true
		visualEgg.Parent = char

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
-- APPLY STATS TO CHARACTER
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
-- PLAYER LIFECYCLE
------------------------------------------------------------
local function syncPlayer(player: Player)
	local data = DataModule.Get(player)
	local bp = playerBackpacks[player.UserId] or { Count = 0, Value = 0 }
	local rebCost, speedReq = Config.GetRebirthCost(data.Rebirths or 0)

	local payload = {
		Eggs            = data.Eggs,
		TotalEggs       = data.TotalEggs,
		Rebirths        = data.Rebirths or 0,
		HatchedEggs     = data.HatchedEggs or 0,
		SpeedLevel      = data.SpeedLevel,
		BackpackLevel   = data.BackpackLevel,
		MultiplierLevel = data.MultiplierLevel,
		JumpLevel       = data.JumpLevel,
		CarriedCount    = bp.Count,
		CarriedValue    = bp.Value,
		Capacity        = getCapacity(player),
		RebirthCost     = rebCost,
		RebirthSpeedReq = speedReq,
		PlotIndex       = playerPlotMap[player.UserId] or 0,
	}
	SyncDataEvent:FireClient(player, payload)
end

local function setupPlayer(player: Player)
	local data = DataModule.Load(player)

	playerBackpacks[player.UserId] = {
		Count = 0,
		Value = 0,
		Visuals = {},
	}

	-- Leaderstats
	local ls = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local eggsVal = ls:FindFirstChild("Eggs") or Instance.new("IntValue")
	eggsVal.Name = "Eggs"
	eggsVal.Value = data.Eggs
	eggsVal.Parent = ls

	local rebVal = ls:FindFirstChild("Rebirths") or Instance.new("IntValue")
	rebVal.Name = "Rebirths"
	rebVal.Value = data.Rebirths or 0
	rebVal.Parent = ls

	local totalVal = ls:FindFirstChild("Total") or Instance.new("IntValue")
	totalVal.Name = "Total"
	totalVal.Value = data.TotalEggs
	totalVal.Parent = ls

	assignPlot(player)

	player.CharacterAdded:Connect(function(char)
		applyStats(player, char)
	end)

	if player.Character then
		applyStats(player, player.Character)
	end

	syncPlayer(player)
end

local function teardownPlayer(player: Player)
	DataModule.Save(player)
	DataModule.RemoveCache(player)
	releasePlot(player)
	playerBackpacks[player.UserId] = nil
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(teardownPlayer)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end

------------------------------------------------------------
-- SHOP UPGRADES
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

		syncPlayer(player)
		EggEffectEvent:FireClient(player, "PlaySound", Config.SOUNDS.UpgradeBuy, 1.0)
	end
end)

------------------------------------------------------------
-- REBIRTH TRANSACTION
------------------------------------------------------------
PerformRebirthEvent.OnServerEvent:Connect(function(player: Player)
	if DataModule.PerformRebirth(player) then
		local data = DataModule.Get(player)

		if player.Character then
			applyStats(player, player.Character)
		end

		local ls = player:FindFirstChild("leaderstats")
		if ls then
			if ls:FindFirstChild("Eggs") then ls.Eggs.Value = 0 end
			if ls:FindFirstChild("Rebirths") then ls.Rebirths.Value = data.Rebirths end
		end

		syncPlayer(player)
		EggEffectEvent:FireClient(player, "RebirthSuccess", data.Rebirths)
	end
end)

------------------------------------------------------------
-- PLOT EGG HATCHING SYSTEM
------------------------------------------------------------
HatchEggEvent.OnServerEvent:Connect(function(player: Player, plotIndex: number)
	local assigned = playerPlotMap[player.UserId]
	if assigned ~= plotIndex then return end

	local data = DataModule.Get(player)
	if data.Eggs < Config.HATCH_COST then
		EggEffectEvent:FireClient(player, "PlaySound", Config.SOUNDS.BackpackFull, 0.8)
		return
	end

	if DataModule.SpendEggs(player, Config.HATCH_COST) then
		data = DataModule.Get(player)
		data.HatchedEggs = (data.HatchedEggs or 0) + 1
		DataModule.Set(player, data)

		-- Animated Hatching on Plot
		local plotModel = workspace.ChronosMap.Plots:FindFirstChild("Plot_" .. plotIndex)
		local nestEgg = plotModel and plotModel:FindFirstChild("NestEgg")
		if nestEgg then
			-- Shake Egg
			task.spawn(function()
				for _ = 1, 6 do
					nestEgg.CFrame = nestEgg.CFrame * CFrame.Angles(0, 0, math.rad(15))
					task.wait(0.06)
					nestEgg.CFrame = nestEgg.CFrame * CFrame.Angles(0, 0, math.rad(-30))
					task.wait(0.06)
					nestEgg.CFrame = nestEgg.CFrame * CFrame.Angles(0, 0, math.rad(15))
					task.wait(0.06)
				end
			end)
		end

		-- Payout with Rebirth Multipliers
		local rebMult = 1 + ((data.Rebirths or 0) * Config.REBIRTH.MultiplierPerReb)
		local reward = math.floor(math.random(Config.HATCH_REWARDS.MinCoins, Config.HATCH_REWARDS.MaxCoins) * rebMult)
		DataModule.AddEggs(player, reward)
		data = DataModule.Get(player)

		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("Eggs") then
			ls.Eggs.Value = data.Eggs
		end

		syncPlayer(player)
		EggEffectEvent:FireClient(player, "EggHatched", reward)
	end
end)

------------------------------------------------------------
-- FORWARD DECLARATION FOR SPAWN EGG
------------------------------------------------------------
local spawnEgg

------------------------------------------------------------
-- EGG SCATTER MECHANIC
------------------------------------------------------------
ScatterEvent.Event:Connect(function(targetPlayer: Player, scatterCount: number, impactPos: Vector3)
	local bp = playerBackpacks[targetPlayer.UserId]
	if not bp or bp.Count <= 0 then return end

	local toDrop = math.min(scatterCount, bp.Count)
	local valPer = math.floor(bp.Value / bp.Count)
	bp.Count = bp.Count - toDrop
	bp.Value = bp.Value - (valPer * toDrop)

	updateBackpackVisuals(targetPlayer)

	for i = 1, toDrop do
		local angle = (i / toDrop) * math.pi * 2 + math.random()
		local dropPos = impactPos + Vector3.new(math.cos(angle) * 7, 2, math.sin(angle) * 7)
		spawnEgg(dropPos, "Common")
	end

	EggEffectEvent:FireClient(targetPlayer, "AttackedScatter", toDrop)
	syncPlayer(targetPlayer)
end)

------------------------------------------------------------
-- DEPOSIT BANK TOUCH LISTENER
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
			local mult = (1 + ((data.MultiplierLevel or 0) * Config.UPGRADES.Multiplier.Increment)) * (1 + ((data.Rebirths or 0) * Config.REBIRTH.MultiplierPerReb))
			local bankedTotal = math.floor(bp.Value * mult)

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
			syncPlayer(player)

			task.wait(1.5)
			depositDebounce[player] = nil
		end
	end)
end)

------------------------------------------------------------
-- TRUE 3D EGG SPAWN LOGIC
------------------------------------------------------------
spawnEgg = function(pos: Vector3, tierKey: string)
	local tierDef = Config.EGG_TIERS[tierKey] or Config.EGG_TIERS.Common

	local egg = Instance.new("Part")
	egg.Name = "Egg_" .. tierKey
	egg.Size = Vector3.new(2, 2.8, 2)
	egg.Position = pos
	egg.Anchored = true
	egg.CanCollide = false
	egg.Color = tierDef.Color
	egg.Material = Enum.Material.Neon
	egg.Parent = eggFolder

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = Config.EGG_MESH_ID
	mesh.TextureId = Config.GALAXY_TEXTURE
	mesh.Scale = tierDef.Scale
	mesh.Parent = egg

	local light = Instance.new("PointLight")
	light.Color = tierDef.Color
	light.Range = (tierKey == "Chronos") and 22 or 12
	light.Brightness = 3
	light.Parent = egg

	local pe = Instance.new("ParticleEmitter")
	pe.Color = tierDef.ParticleClr
	pe.Size = NumberSequence.new(0.6, 0.1)
	pe.Lifetime = NumberRange.new(0.8, 1.5)
	pe.Rate = (tierKey == "Chronos") and 35 or 14
	pe.Speed = NumberRange.new(2, 6)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = egg

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
		syncPlayer(player)

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

local function spawnMultiZoneEggs()
	for _, child in ipairs(eggFolder:GetChildren()) do
		child:Destroy()
	end

	for _, zDef in pairs(Config.ZONES) do
		local eggsInZone = 8
		local halfX = zDef.Size.X / 2 - 10
		local halfZ = zDef.Size.Z / 2 - 10

		for _ = 1, eggsInZone do
			local pX = zDef.Center.X + math.random(-halfX, halfX)
			local pZ = zDef.Center.Z + math.random(-halfZ, halfZ)
			local randomTier = zDef.EggTiers[math.random(1, #zDef.EggTiers)]
			spawnEgg(Vector3.new(pX, zDef.Center.Y + 2.5, pZ), randomTier)
		end
	end
end

------------------------------------------------------------
-- ROUND LOOP
------------------------------------------------------------
local function broadcast(msg)
	StatusEvent:FireAllClients(msg)
end

task.spawn(function()
	while true do
		broadcast("⏳ Intermission... Upgrade, Rebirth & Hatch at your Plot!")
		task.wait(Config.INTERMISSION)

		broadcast("🚨 VAULT BREACH! 4 Zone Guardians Awakened! Steal the eggs!")
		spawnMultiZoneEggs()

		for t = Config.ROUND_DURATION, 1, -1 do
			broadcast("⚡ Time Left: " .. t .. "s | Outrun Zone Guardians & Bank!")
			task.wait(1)
		end

		broadcast("🏁 Round Over! Deposit your loot!")
		task.wait(3)
	end
end)

print("[ChronosVault] Multi-Zone Progression & Plot Hatchery Engine Loaded ✓")
