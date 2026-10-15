--[[
    MapBuilder.server.lua (ServerScriptService)
    Chronos Vault: World Decorator & Dynamic Interactivity
    - Physical parts are permanently declared in Workspace via default.project.json!
    - This script decorates the world at runtime:
      - Adds PointLights & Neon Glow to Zone Beacons
      - Adds Particle Emitters to Deposit Pad & Cosmic Vortex
      - Adds ProximityPrompts & Billboards to Rebirth Altar, Kiosks & Incubator Nests
      - Applies Galactic Surface Textures
    - Fully supports manual editing in Studio!
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local function getOrCreateRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local OpenShopEvent    = getOrCreateRemote("OpenShop")
local OpenRebirthEvent = getOrCreateRemote("OpenRebirth")
local HatchEggEvent    = getOrCreateRemote("HatchEgg")

local map = workspace:WaitForChild("ChronosMap", 15)
if not map then
	warn("[ChronosVault] ChronosMap folder not found in Workspace!")
	return
end

local lobby = map:WaitForChild("Lobby", 10)
local plots = map:WaitForChild("Plots", 10)
local zones = map:WaitForChild("Zones", 10)

------------------------------------------------------------
-- 1. DECORATE LOBBY (Deposit Pad, Altar, Kiosks)
------------------------------------------------------------
if lobby then
	-- Deposit Pad Sparkles
	local depositPad = lobby:FindFirstChild("DepositPad")
	if depositPad and not depositPad:FindFirstChildWhichIsA("ParticleEmitter") then
		depositPad.Material = Enum.Material.Neon
		depositPad.Color = Color3.fromRGB(255, 215, 0)

		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "DepositSparkles"
		sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 240, 100), Color3.fromRGB(255, 120, 0))
		sparkles.Size = NumberSequence.new(0.8, 0.2)
		sparkles.Lifetime = NumberRange.new(1.2, 2.2)
		sparkles.Rate = 35
		sparkles.Speed = NumberRange.new(4, 10)
		sparkles.Parent = depositPad

		-- 3D Bank Sign
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 360, 0, 85)
		bb.StudsOffset = Vector3.new(0, 8, 0)
		bb.AlwaysOnTop = true
		bb.Adornee = depositPad
		bb.Parent = depositPad

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(255, 220, 0)
		lbl.Font = Enum.Font.GothamBlack
		lbl.TextScaled = true
		lbl.Text = "🏦 VAULT DEPOSIT BANK\nSTEP HERE TO SECURE EGGS!"
		lbl.Parent = bb
	end

	-- Rebirth Altar Prompt & Hologram
	local altar = lobby:FindFirstChild("RebirthAltar")
	if altar and not altar:FindFirstChildWhichIsA("ProximityPrompt") then
		altar.Material = Enum.Material.Neon
		altar.Color = Color3.fromRGB(255, 50, 200)

		local rPrompt = Instance.new("ProximityPrompt")
		rPrompt.ObjectText = "Rebirth Altar"
		rPrompt.ActionText = "Ascend & Rebirth"
		rPrompt.HoldDuration = 0
		rPrompt.MaxActivationDistance = 16
		rPrompt.Parent = altar
		rPrompt.Triggered:Connect(function(player)
			OpenRebirthEvent:FireClient(player)
		end)

		local rGui = Instance.new("BillboardGui")
		rGui.Size = UDim2.new(0, 280, 0, 75)
		rGui.StudsOffset = Vector3.new(0, 6, 0)
		rGui.AlwaysOnTop = true
		rGui.Adornee = altar
		rGui.Parent = altar

		local rText = Instance.new("TextLabel")
		rText.Size = UDim2.new(1, 0, 1, 0)
		rText.BackgroundTransparency = 1
		rText.TextColor3 = Color3.fromRGB(255, 80, 240)
		rText.Font = Enum.Font.GothamBlack
		rText.TextScaled = true
		rText.Text = "🌀 REBIRTH ALTAR\n[E] REBIRTH"
		rText.Parent = rGui
	end

	-- Speed Shop Kiosk
	local spdShop = lobby:FindFirstChild("SpeedShop")
	if spdShop and not spdShop:FindFirstChildWhichIsA("ProximityPrompt") then
		spdShop.Material = Enum.Material.Neon
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "SPEED LAB"
		prompt.ActionText = "Open Shop"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 16
		prompt.Parent = spdShop
		prompt.Triggered:Connect(function(player)
			OpenShopEvent:FireClient(player, "Speed")
		end)

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 240, 0, 60)
		bb.StudsOffset = Vector3.new(0, 5, 0)
		bb.AlwaysOnTop = true
		bb.Adornee = spdShop
		bb.Parent = spdShop

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(0, 240, 255)
		lbl.Font = Enum.Font.GothamBlack
		lbl.TextScaled = true
		lbl.Text = "⚡ SPEED LAB\n[E] UPGRADE"
		lbl.Parent = bb
	end

	-- Perks Shop Kiosk
	local perksShop = lobby:FindFirstChild("PerksShop")
	if perksShop and not perksShop:FindFirstChildWhichIsA("ProximityPrompt") then
		perksShop.Material = Enum.Material.Neon
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "VAULT PERKS"
		prompt.ActionText = "Open Shop"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 16
		prompt.Parent = perksShop
		prompt.Triggered:Connect(function(player)
			OpenShopEvent:FireClient(player, "Perks")
		end)

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 240, 0, 60)
		bb.StudsOffset = Vector3.new(0, 5, 0)
		bb.AlwaysOnTop = true
		bb.Adornee = perksShop
		bb.Parent = perksShop

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(255, 180, 0)
		lbl.Font = Enum.Font.GothamBlack
		lbl.TextScaled = true
		lbl.Text = "💎 VAULT PERKS\n[E] UPGRADE"
		lbl.Parent = bb
	end
end

------------------------------------------------------------
-- 2. DECORATE PLOTS (Incubator Nests & Prompts)
------------------------------------------------------------
if plots then
	for i = 1, Config.MAX_PLOTS do
		local plotPart = plots:FindFirstChild("Plot_" .. i)
		if plotPart then
			-- Add Incubator Nest model on top of plot if not present
			local nest = plotPart:FindFirstChild("IncubatorNest")
			if not nest then
				nest = Instance.new("Part")
				nest.Name = "IncubatorNest"
				nest.Size = Vector3.new(8, 1.5, 8)
				nest.Position = plotPart.Position + Vector3.new(0, 1.7, 0)
				nest.Color = Color3.fromRGB(255, 180, 0)
				nest.Material = Enum.Material.Neon
				nest.Anchored = true
				nest.Parent = plotPart

				local nestEgg = Instance.new("Part")
				nestEgg.Name = "NestEgg"
				nestEgg.Size = Vector3.new(2, 2.8, 2)
				nestEgg.Position = nest.Position + Vector3.new(0, 2.2, 0)
				nestEgg.Color = Color3.fromRGB(255, 215, 0)
				nestEgg.Material = Enum.Material.Neon
				nestEgg.Anchored = true
				nestEgg.CanCollide = false
				nestEgg.Parent = plotPart

				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.FileMesh
				mesh.MeshId = Config.EGG_MESH_ID
				mesh.TextureId = Config.GALAXY_TEXTURE
				mesh.Scale = Vector3.new(1.3, 1.7, 1.3)
				mesh.Parent = nestEgg

				local prompt = Instance.new("ProximityPrompt")
				prompt.ObjectText = "Incubator Nest"
				prompt.ActionText = "Hatch Egg (10 Eggs)"
				prompt.HoldDuration = 0.5
				prompt.MaxActivationDistance = 14
				prompt.Parent = nest
				prompt.Triggered:Connect(function(player)
					HatchEggEvent:FireServer(i)
				end)

				-- 3D Owner Sign
				local signBoard = Instance.new("Part")
				signBoard.Name = "SignBoard"
				signBoard.Size = Vector3.new(12, 3, 1)
				signBoard.Position = plotPart.Position + Vector3.new(0, 6, -9)
				signBoard.Color = Color3.fromRGB(20, 20, 35)
				signBoard.Material = Enum.Material.Metal
				signBoard.Anchored = true
				signBoard.Parent = plotPart

				local signGui = Instance.new("BillboardGui")
				signGui.Size = UDim2.new(0, 240, 0, 60)
				signGui.AlwaysOnTop = true
				signGui.Adornee = signBoard
				signGui.Parent = signBoard

				local signText = Instance.new("TextLabel")
				signText.Name = "OwnerLabel"
				signText.Size = UDim2.new(1, 0, 1, 0)
				signText.BackgroundTransparency = 1
				signText.TextColor3 = Color3.fromRGB(0, 230, 255)
				signText.Font = Enum.Font.GothamBold
				signText.TextScaled = true
				signText.Text = "🐣 [UNCLAIMED PLOT " .. i .. "]"
				signText.Parent = signGui
			end
		end
	end
end

------------------------------------------------------------
-- 3. DECORATE ZONES (Lights, Beacons, Vortex)
------------------------------------------------------------
if zones then
	-- Decorate each zone's beacons with PointLights
	for zKey, zDef in pairs(Config.ZONES) do
		local zFolder = zones:FindFirstChild(zKey .. "_" .. zDef.Name:match("^(%w+)")) or zones:FindFirstChildWhichIsA("Folder")
		if zFolder then
			for _, child in ipairs(zFolder:GetChildren()) do
				if child.Name:match("^Beacon") and child:IsA("BasePart") then
					child.Material = Enum.Material.Neon
					if not child:FindFirstChildWhichIsA("PointLight") then
						local light = Instance.new("PointLight")
						light.Color = zDef.LightColor
						light.Range = 45
						light.Brightness = 4
						light.Parent = child
					end
				end
			end
		end
	end

	-- Central Core Vortex Particles
	local coreZone = zones:FindFirstChild("Zone4_Core")
	local vortex = coreZone and coreZone:FindFirstChild("CoreVortex")
	if vortex and not vortex:FindFirstChildWhichIsA("ParticleEmitter") then
		vortex.Material = Enum.Material.Neon
		local vEmitter = Instance.new("ParticleEmitter")
		vEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 0, 180), Color3.fromRGB(0, 240, 255))
		vEmitter.Size = NumberSequence.new(1.8, 0.2)
		vEmitter.Rate = 50
		vEmitter.Speed = NumberRange.new(6, 14)
		vEmitter.SpreadAngle = Vector2.new(180, 180)
		vEmitter.Parent = vortex
	end
end

print("[ChronosVault] World Interactivity & Lights Attached to Physical Map ✓")
