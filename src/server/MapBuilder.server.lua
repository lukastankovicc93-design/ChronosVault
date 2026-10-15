--[[
    MapBuilder.server.lua (ServerScriptService)
    Chronos Vault: Expanded Multi-Zone Map & Player Plots
    - 4 Lighted Themed Zones (Stardust Valley, Solar Expanse, Void Nebula, Chronos Core)
    - Rebirth Sanctuary with glowing Altar & Portal
    - 6 Dedicated Player Hatchery Plots with Incubator Nests
    - Cosmic Galaxy Textures on all grounds & structures
    - Modular folder hierarchy for easy manual Studio editing!
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

------------------------------------------------------------
-- MANUAL EDIT CHECK
------------------------------------------------------------
if Config.MANUAL_MAP_MODE then
	if workspace:FindFirstChild("ChronosMap") then
		print("[ChronosVault] Manual Map Mode active: Preserving existing map ✓")
		return
	end
end

if workspace:FindFirstChild("ChronosMap") then
	workspace.ChronosMap:Destroy()
end

local mapFolder = Instance.new("Folder")
mapFolder.Name = "ChronosMap"
mapFolder.Parent = workspace

local lobbyFolder = Instance.new("Folder")
lobbyFolder.Name = "Lobby"
lobbyFolder.Parent = mapFolder

local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "Plots"
plotsFolder.Parent = mapFolder

local zonesFolder = Instance.new("Folder")
zonesFolder.Name = "Zones"
zonesFolder.Parent = mapFolder

------------------------------------------------------------
-- BUILDER HELPER
------------------------------------------------------------
local function makePart(props)
	local p = Instance.new("Part")
	p.Name = props.Name or "Part"
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.CFrame = props.CFrame or CFrame.new(0, 0, 0)
	p.Color = props.Color or Color3.fromRGB(30, 24, 45)
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = (props.CanCollide ~= false)
	p.Transparency = props.Transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = props.Parent or mapFolder

	if props.GalacticTexture then
		local tex = Instance.new("Texture")
		tex.Name = "GalacticSurfaceTex"
		tex.Texture = Config.GALAXY_TEXTURE
		tex.Face = Enum.NormalId.Top
		tex.StudsPerTileU = props.TileSize or 24
		tex.StudsPerTileV = props.TileSize or 24
		tex.Transparency = props.TexTransparency or 0.35
		tex.Parent = p
	end

	return p
end

------------------------------------------------------------
-- 1. SPACIOUS LOBBY & THE GREAT DEPOSIT VAULT
------------------------------------------------------------
local lobbyPos = Config.LOBBY_CENTER

makePart({
	Name = "LobbyFloor",
	Size = Vector3.new(130, 4, 80),
	CFrame = CFrame.new(lobbyPos),
	Color = Color3.fromRGB(18, 14, 30),
	Material = Enum.Material.Slate,
	GalacticTexture = true,
	TileSize = 30,
	Parent = lobbyFolder,
})

-- Spawns
for i = -2, 2 do
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn_" .. (i + 3)
	spawn.Size = Vector3.new(7, 0.8, 7)
	spawn.Position = lobbyPos + Vector3.new(i * 14, 2.4, -24)
	spawn.Color = Color3.fromRGB(0, 230, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Duration = 0
	spawn.Parent = lobbyFolder
end

-- The Great Deposit Bank
local bankPos = Config.VAULT_DEPOSIT_POS
local bankBase = makePart({
	Name = "BankBase",
	Size = Vector3.new(24, 2.5, 24),
	CFrame = CFrame.new(bankPos) * CFrame.Angles(0, 0, math.rad(90)),
	Color = Color3.fromRGB(40, 25, 60),
	Material = Enum.Material.Metal,
	Parent = lobbyFolder,
})
bankBase.Shape = Enum.PartType.Cylinder

local depositRing = makePart({
	Name = "DepositPad",
	Size = Vector3.new(20, 0.5, 20),
	CFrame = CFrame.new(bankPos + Vector3.new(0, 1.4, 0)),
	Color = Color3.fromRGB(255, 215, 0),
	Material = Enum.Material.Neon,
	GalacticTexture = true,
	TileSize = 10,
	Parent = lobbyFolder,
})

local sparkles = Instance.new("ParticleEmitter")
sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 240, 100), Color3.fromRGB(255, 120, 0))
sparkles.Size = NumberSequence.new(0.8, 0.2)
sparkles.Lifetime = NumberRange.new(1.2, 2.2)
sparkles.Rate = 35
sparkles.Speed = NumberRange.new(4, 10)
sparkles.Parent = depositRing

------------------------------------------------------------
-- REBIRTH SANCTUARY (Lobby East Wing)
------------------------------------------------------------
local rebirthPos = lobbyPos + Vector3.new(48, 0, -10)

local rebirthAltar = makePart({
	Name = "RebirthAltar",
	Size = Vector3.new(14, 3, 14),
	CFrame = CFrame.new(rebirthPos + Vector3.new(0, 1.5, 0)),
	Color = Color3.fromRGB(35, 18, 55),
	Material = Enum.Material.Metal,
	Parent = lobbyFolder,
})

local rebirthRing = makePart({
	Name = "RebirthRing",
	Size = Vector3.new(12, 0.4, 12),
	CFrame = CFrame.new(rebirthPos + Vector3.new(0, 3.2, 0)),
	Color = Color3.fromRGB(255, 50, 220),
	Material = Enum.Material.Neon,
	Parent = lobbyFolder,
})

-- Rebirth Rotating Aura
local rHolo = makePart({
	Name = "RebirthHoloPart",
	Size = Vector3.new(3, 3, 3),
	CFrame = CFrame.new(rebirthPos + Vector3.new(0, 8, 0)),
	Color = Color3.fromRGB(255, 50, 220),
	Material = Enum.Material.Neon,
	CanCollide = false,
	Parent = lobbyFolder,
})

task.spawn(function()
	while rHolo and rHolo.Parent do
		rHolo.CFrame = rHolo.CFrame * CFrame.Angles(0, math.rad(2), math.rad(1))
		task.wait(0.03)
	end
end)

local rGui = Instance.new("BillboardGui")
rGui.Size = UDim2.new(0, 280, 0, 75)
rGui.StudsOffset = Vector3.new(0, 2.5, 0)
rGui.AlwaysOnTop = true
rGui.Adornee = rHolo
rGui.Parent = rHolo

local rText = Instance.new("TextLabel")
rText.Size = UDim2.new(1, 0, 1, 0)
rText.BackgroundTransparency = 1
rText.TextColor3 = Color3.fromRGB(255, 80, 240)
rText.Font = Enum.Font.GothamBlack
rText.TextScaled = true
rText.Text = "🌀 REBIRTH ALTAR\n[E] REBIRTH"
rText.Parent = rGui

local rPrompt = Instance.new("ProximityPrompt")
rPrompt.ObjectText = "Rebirth Altar"
rPrompt.ActionText = "Ascend & Rebirth"
rPrompt.HoldDuration = 0
rPrompt.MaxActivationDistance = 16
rPrompt.Parent = rebirthAltar
rPrompt.Triggered:Connect(function(player)
	OpenRebirthEvent:FireClient(player)
end)

------------------------------------------------------------
-- SPEED LAB & VAULT KIOSKS
------------------------------------------------------------
local function createKiosk(shopType, title, icon, color, pos)
	local m = Instance.new("Model")
	m.Name = shopType .. "Shop"
	m.Parent = lobbyFolder

	local counter = makePart({ Name = "Counter", Size = Vector3.new(16, 4.5, 8), CFrame = CFrame.new(pos + Vector3.new(0, 2.25, 0)), Color = Color3.fromRGB(24, 18, 38), Material = Enum.Material.Metal, Parent = m })
	makePart({ Name = "Trim", Size = Vector3.new(16.4, 0.6, 8.4), CFrame = CFrame.new(pos + Vector3.new(0, 4.6, 0)), Color = color, Material = Enum.Material.Neon, Parent = m })
	makePart({ Name = "Roof", Size = Vector3.new(18, 1.8, 10), CFrame = CFrame.new(pos + Vector3.new(0, 16, 0)), Color = Color3.fromRGB(20, 16, 32), Material = Enum.Material.Metal, Parent = m })

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = title
	prompt.ActionText = "Open Shop"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.Parent = counter
	prompt.Triggered:Connect(function(player)
		OpenShopEvent:FireClient(player, shopType)
	end)
end

createKiosk("Speed", "SPEED LAB", "⚡", Color3.fromRGB(0, 230, 255), lobbyPos + Vector3.new(-48, 0, -10))
createKiosk("Perks", "VAULT PERKS", "💎", Color3.fromRGB(255, 170, 0), lobbyPos + Vector3.new(-22, 0, 22))

------------------------------------------------------------
-- 2. DEDICATED PLAYER HATCHERY PLOTS (6 Plots)
------------------------------------------------------------
local plotOffsets = {
	Vector3.new(-50, 0, -65),
	Vector3.new(-20, 0, -65),
	Vector3.new(10,  0, -65),
	Vector3.new(40,  0, -65),
	Vector3.new(-35, 0, -95),
	Vector3.new(25,  0, -95),
}

for i, pOffset in ipairs(plotOffsets) do
	local plotModel = Instance.new("Model")
	plotModel.Name = "Plot_" .. i
	plotModel.Parent = plotsFolder

	local plotPos = lobbyPos + pOffset

	-- Plot Platform
	local plotBase = makePart({
		Name = "PlotFloor",
		Size = Vector3.new(22, 2, 22),
		CFrame = CFrame.new(plotPos),
		Color = Color3.fromRGB(25, 20, 36),
		Material = Enum.Material.Slate,
		GalacticTexture = true,
		TileSize = 10,
		Parent = plotModel,
	})
	makePart({ Name = "PlotBorder", Size = Vector3.new(22.6, 0.6, 22.6), CFrame = CFrame.new(plotPos + Vector3.new(0, 1.1, 0)), Color = Color3.fromRGB(0, 230, 255), Material = Enum.Material.Neon, Parent = plotModel })

	-- 3D Sign Board
	local signPost = makePart({ Name = "SignPost", Size = Vector3.new(1, 8, 1), CFrame = CFrame.new(plotPos + Vector3.new(0, 5, -9)), Color = Color3.fromRGB(30, 30, 45), Material = Enum.Material.Metal, Parent = plotModel })
	local signBoard = makePart({ Name = "SignBoard", Size = Vector3.new(12, 3, 1), CFrame = CFrame.new(plotPos + Vector3.new(0, 8.5, -9)), Color = Color3.fromRGB(20, 20, 35), Material = Enum.Material.Metal, Parent = plotModel })

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

	-- Egg Incubator Nest in center of plot
	local nest = makePart({
		Name = "IncubatorNest",
		Size = Vector3.new(8, 1.5, 8),
		CFrame = CFrame.new(plotPos + Vector3.new(0, 1.7, 1)),
		Color = Color3.fromRGB(255, 180, 0),
		Material = Enum.Material.Neon,
		Parent = plotModel,
	})

	-- Incubator 3D Egg Display
	local nestEgg = makePart({
		Name = "NestEgg",
		Size = Vector3.new(2, 2.8, 2),
		CFrame = CFrame.new(plotPos + Vector3.new(0, 3.8, 1)),
		Color = Color3.fromRGB(255, 215, 0),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = plotModel,
	})
	local eggMesh = Instance.new("SpecialMesh")
	eggMesh.MeshType = Enum.MeshType.FileMesh
	eggMesh.MeshId = Config.EGG_MESH_ID
	eggMesh.TextureId = Config.GALAXY_TEXTURE
	eggMesh.Scale = Vector3.new(1.3, 1.7, 1.3)
	eggMesh.Parent = nestEgg

	-- Prompt to Hatch
	local hatchPrompt = Instance.new("ProximityPrompt")
	hatchPrompt.ObjectText = "Incubator Nest"
	hatchPrompt.ActionText = "Hatch Egg (10 Eggs)"
	hatchPrompt.HoldDuration = 0.5
	hatchPrompt.MaxActivationDistance = 14
	hatchPrompt.Parent = nest

	hatchPrompt.Triggered:Connect(function(player)
		HatchEggEvent:FireServer(i)
	end)
end

------------------------------------------------------------
-- 3. THE 4 TIERED LIGHTED SECTIONS / ZONES
------------------------------------------------------------
for zKey, zDef in pairs(Config.ZONES) do
	local zModel = Instance.new("Model")
	zModel.Name = zKey .. "_" .. zDef.Name
	zModel.Parent = zonesFolder

	-- Zone Ground Platform
	local ground = makePart({
		Name = "ZoneGround",
		Size = zDef.Size,
		CFrame = CFrame.new(zDef.Center),
		Color = Color3.fromRGB(15, 12, 25),
		Material = Enum.Material.Slate,
		GalacticTexture = true,
		TileSize = 25,
		Parent = zModel,
	})

	-- Zone Illuminated Perimeter Border
	makePart({
		Name = "BorderTrim",
		Size = Vector3.new(zDef.Size.X + 2, 1, zDef.Size.Z + 2),
		CFrame = CFrame.new(zDef.Center + Vector3.new(0, zDef.Size.Y/2 + 0.5, 0)),
		Color = zDef.Color,
		Material = Enum.Material.Neon,
		Parent = zModel,
	})

	-- 4 Corner High-Intensity Light Beacons
	local halfX = zDef.Size.X / 2 - 4
	local halfZ = zDef.Size.Z / 2 - 4
	local beaconOffsets = {
		Vector3.new(halfX, 12, halfZ),
		Vector3.new(-halfX, 12, halfZ),
		Vector3.new(halfX, 12, -halfZ),
		Vector3.new(-halfX, 12, -halfZ),
	}
	for bIdx, bOffset in ipairs(beaconOffsets) do
		local beacon = makePart({
			Name = "Beacon_" .. bIdx,
			Size = Vector3.new(3, 24, 3),
			CFrame = CFrame.new(zDef.Center + bOffset),
			Color = zDef.Color,
			Material = Enum.Material.Neon,
			Parent = zModel,
		})
		local light = Instance.new("PointLight")
		light.Color = zDef.LightColor
		light.Range = 45
		light.Brightness = 4
		light.Parent = beacon
	end

	-- Entrance Archway with Speed Recommendation
	local archBeam = makePart({
		Name = "EntranceArch",
		Size = Vector3.new(26, 3, 2),
		CFrame = CFrame.new(zDef.Center + Vector3.new(0, 16, -zDef.Size.Z/2)),
		Color = zDef.Color,
		Material = Enum.Material.Neon,
		Parent = zModel,
	})

	local archGui = Instance.new("BillboardGui")
	archGui.Size = UDim2.new(0, 320, 0, 75)
	archGui.AlwaysOnTop = true
	archGui.Adornee = archBeam
	archGui.Parent = archBeam

	local aLabel = Instance.new("TextLabel")
	aLabel.Size = UDim2.new(1, 0, 1, 0)
	aLabel.BackgroundTransparency = 1
	aLabel.TextColor3 = zDef.Color
	aLabel.Font = Enum.Font.GothamBlack
	aLabel.TextScaled = true
	aLabel.Text = zDef.Name .. "\n⚠️ Rec. Speed: " .. zDef.MinSpeedToRun .. "+"
	aLabel.Parent = archGui
end

-- Central Chronos Core Vortex
local corePos = Config.ZONES.Zone4.Center
local vortex = makePart({
	Name = "CosmicVortex",
	Size = Vector3.new(16, 0.5, 16),
	CFrame = CFrame.new(corePos + Vector3.new(0, 4.4, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	Color = Color3.fromRGB(255, 30, 120),
	Material = Enum.Material.Neon,
	Parent = zonesFolder,
})
vortex.Shape = Enum.PartType.Cylinder

local vEmitter = Instance.new("ParticleEmitter")
vEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 0, 180), Color3.fromRGB(0, 240, 255))
vEmitter.Size = NumberSequence.new(1.8, 0.2)
vEmitter.Rate = 50
vEmitter.Speed = NumberRange.new(6, 14)
vEmitter.SpreadAngle = Vector2.new(180, 180)
vEmitter.Parent = vortex

print("[ChronosVault] Expanded Multi-Zone Map & Plots Built Successfully ✓")
