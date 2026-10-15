--[[
    MapBuilder.server.lua (ServerScriptService)
    Chronos Vault: 10x Galactic Arena Overhaul
    - Fancy Cosmic & Nebula Surface Textures applied across all floors and pedestals
    - Swirling Galactic Core Vortex on the Central Vault Dais
    - Stylized Space-Station Lobby with Holograms & Star Particle Emitters
    - High-Tech Kiosks with animated holographic signs
    - Kinetic Jump Pads & Cosmic Laser Conduits
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Remote Events
local function getOrCreateRemote(name)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local OpenShopEvent = getOrCreateRemote("OpenShop")

------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------
if workspace:FindFirstChild("ChronosMap") then
	workspace.ChronosMap:Destroy()
end

local mapFolder = Instance.new("Folder")
mapFolder.Name = "ChronosMap"
mapFolder.Parent = workspace

local arenaFolder = Instance.new("Folder")
arenaFolder.Name = "Arena"
arenaFolder.Parent = mapFolder

local lobbyFolder = Instance.new("Folder")
lobbyFolder.Name = "Lobby"
lobbyFolder.Parent = mapFolder

local propsFolder = Instance.new("Folder")
propsFolder.Name = "Props"
propsFolder.Parent = mapFolder

------------------------------------------------------------
-- BUILDER HELPER WITH GALACTIC TEXTURES
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

	-- Apply Galactic Surface Texture if requested
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
-- 1. GALACTIC LOBBY & THE GREAT DEPOSIT VAULT
------------------------------------------------------------
local lobbyPos = Config.LOBBY_CENTER

-- Main Lobby Platform with Nebula Texture
local lobbyFloor = makePart({
	Name = "LobbyFloor",
	Size = Vector3.new(100, 4, 70),
	CFrame = CFrame.new(lobbyPos),
	Color = Color3.fromRGB(18, 14, 30),
	Material = Enum.Material.Slate,
	GalacticTexture = true,
	TileSize = 30,
	TexTransparency = 0.4,
	Parent = lobbyFolder,
})

-- Glowing Cyber Trim & Border
makePart({ Name = "LobbyTrimN", Size = Vector3.new(100, 3, 1.5), CFrame = CFrame.new(lobbyPos + Vector3.new(0, 3, -35)), Color = Color3.fromRGB(180, 50, 255), Material = Enum.Material.Neon, Parent = lobbyFolder })
makePart({ Name = "LobbyTrimW", Size = Vector3.new(1.5, 3, 70),  CFrame = CFrame.new(lobbyPos + Vector3.new(-50, 3, 0)), Color = Color3.fromRGB(180, 50, 255), Material = Enum.Material.Neon, Parent = lobbyFolder })
makePart({ Name = "LobbyTrimE", Size = Vector3.new(1.5, 3, 70),  CFrame = CFrame.new(lobbyPos + Vector3.new(50, 3, 0)),  Color = Color3.fromRGB(180, 50, 255), Material = Enum.Material.Neon, Parent = lobbyFolder })

-- Spawns (Cosmic Neon Pads)
for i = -1, 1 do
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CosmicSpawn_" .. (i + 2)
	spawn.Size = Vector3.new(8, 0.8, 8)
	spawn.Position = lobbyPos + Vector3.new(i * 16, 2.4, -18)
	spawn.Color = Color3.fromRGB(0, 230, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Duration = 0
	spawn.Parent = lobbyFolder
end

------------------------------------------------------------
-- THE DEPOSIT VAULT BANK (Golden Ring of Power)
------------------------------------------------------------
local bankPos = Config.VAULT_DEPOSIT_POS

local bankBase = makePart({
	Name = "BankBase",
	Size = Vector3.new(22, 2.5, 22),
	CFrame = CFrame.new(bankPos) * CFrame.Angles(0, 0, math.rad(90)),
	Color = Color3.fromRGB(40, 25, 60),
	Material = Enum.Material.Metal,
	Parent = lobbyFolder,
})
bankBase.Shape = Enum.PartType.Cylinder

local depositRing = makePart({
	Name = "DepositPad",
	Size = Vector3.new(18, 0.5, 18),
	CFrame = CFrame.new(bankPos + Vector3.new(0, 1.4, 0)),
	Color = Color3.fromRGB(255, 215, 0),
	Material = Enum.Material.Neon,
	GalacticTexture = true,
	TileSize = 10,
	Parent = lobbyFolder,
})

-- Golden Stardust Particles
local sparkles = Instance.new("ParticleEmitter")
sparkles.Name = "DepositSparkles"
sparkles.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 240, 100)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 0)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 0, 180)),
})
sparkles.Size = NumberSequence.new(0.8, 0.2)
sparkles.Lifetime = NumberRange.new(1.2, 2.2)
sparkles.Rate = 35
sparkles.Speed = NumberRange.new(4, 10)
sparkles.SpreadAngle = Vector2.new(45, 45)
sparkles.Parent = depositRing

-- Hologram Billboard
local bankSignPart = makePart({
	Name = "BankHolo",
	Size = Vector3.new(1, 1, 1),
	CFrame = CFrame.new(bankPos + Vector3.new(0, 10, 0)),
	Transparency = 1,
	CanCollide = false,
	Parent = lobbyFolder,
})

local bankGui = Instance.new("BillboardGui")
bankGui.Size = UDim2.new(0, 360, 0, 95)
bankGui.AlwaysOnTop = true
bankGui.Adornee = bankSignPart
bankGui.Parent = bankSignPart

local bankLbl = Instance.new("TextLabel")
bankLbl.Size = UDim2.new(1, 0, 0.65, 0)
bankLbl.BackgroundTransparency = 1
bankLbl.TextColor3 = Color3.fromRGB(255, 220, 0)
bankLbl.TextStrokeColor3 = Color3.fromRGB(80, 20, 120)
bankLbl.TextStrokeTransparency = 0.1
bankLbl.Font = Enum.Font.GothamBlack
bankLbl.TextScaled = true
bankLbl.Text = "🏦 COSMIC DEPOSIT VAULT"
bankLbl.Parent = bankGui

local bankSubLbl = Instance.new("TextLabel")
bankSubLbl.Size = UDim2.new(1, 0, 0.35, 0)
bankSubLbl.Position = UDim2.new(0, 0, 0.65, 0)
bankSubLbl.BackgroundTransparency = 1
bankSubLbl.TextColor3 = Color3.fromRGB(180, 230, 255)
bankSubLbl.Font = Enum.Font.GothamBold
bankSubLbl.TextScaled = true
bankSubLbl.Text = "STEP HERE TO BANK STOLEN EGGS!"
bankSubLbl.Parent = bankGui

------------------------------------------------------------
-- 2. COSMIC KIOSKS (Speed Lab & Vault Perks)
------------------------------------------------------------
local function createCosmicKiosk(shopType, titleText, iconText, themeColor, pos)
	local m = Instance.new("Model")
	m.Name = shopType .. "Shop"
	m.Parent = lobbyFolder

	local counter = makePart({
		Name = "Counter",
		Size = Vector3.new(18, 4.5, 8),
		CFrame = CFrame.new(pos + Vector3.new(0, 2.25, 0)),
		Color = Color3.fromRGB(24, 18, 38),
		Material = Enum.Material.Metal,
		Parent = m,
	})
	makePart({
		Name = "CounterTrim",
		Size = Vector3.new(18.4, 0.6, 8.4),
		CFrame = CFrame.new(pos + Vector3.new(0, 4.6, 0)),
		Color = themeColor,
		Material = Enum.Material.Neon,
		Parent = m,
	})

	makePart({
		Name = "Roof",
		Size = Vector3.new(20, 1.8, 11),
		CFrame = CFrame.new(pos + Vector3.new(0, 16, 0)),
		Color = Color3.fromRGB(20, 16, 32),
		Material = Enum.Material.Metal,
		Parent = m,
	})
	makePart({
		Name = "RoofNeon",
		Size = Vector3.new(20.5, 0.8, 11.5),
		CFrame = CFrame.new(pos + Vector3.new(0, 16.5, 0)),
		Color = themeColor,
		Material = Enum.Material.Neon,
		Parent = m,
	})

	-- 3D Spinning Hologram above roof
	local holoPart = makePart({
		Name = "HoloPart",
		Size = Vector3.new(3, 3, 3),
		CFrame = CFrame.new(pos + Vector3.new(0, 19.5, 0)),
		Color = themeColor,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = m,
	})
	task.spawn(function()
		while holoPart and holoPart.Parent do
			holoPart.CFrame = holoPart.CFrame * CFrame.Angles(0, math.rad(2.5), 0)
			task.wait(0.03)
		end
	end)

	local holoGui = Instance.new("BillboardGui")
	holoGui.Size = UDim2.new(0, 270, 0, 75)
	holoGui.StudsOffset = Vector3.new(0, 2.5, 0)
	holoGui.AlwaysOnTop = true
	holoGui.Adornee = holoPart
	holoGui.Parent = holoPart

	local hText = Instance.new("TextLabel")
	hText.Size = UDim2.new(1, 0, 1, 0)
	hText.BackgroundTransparency = 1
	hText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hText.Font = Enum.Font.GothamBlack
	hText.TextScaled = true
	hText.Text = iconText .. " " .. titleText
	hText.Parent = holoGui

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = titleText
	prompt.ActionText = "Open Shop"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter

	prompt.Triggered:Connect(function(player)
		OpenShopEvent:FireClient(player, shopType)
	end)

	-- Glowing step-on pad
	local pad = makePart({
		Name = "ShopPad",
		Size = Vector3.new(12, 0.4, 7),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.4, 7.5)),
		Color = themeColor,
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		Parent = m,
	})

	local padDebounce = {}
	pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and not padDebounce[player] then
			padDebounce[player] = true
			OpenShopEvent:FireClient(player, shopType)
			task.wait(2)
			padDebounce[player] = nil
		end
	end)
end

createCosmicKiosk("Speed", "SPEED LAB", "⚡", Color3.fromRGB(0, 230, 255), lobbyPos + Vector3.new(-32, 0, 5))
createCosmicKiosk("Perks", "VAULT PERKS", "💎", Color3.fromRGB(255, 170, 0), lobbyPos + Vector3.new(32, 0, 5))

------------------------------------------------------------
-- 3. TRANSIT BRIDGE & PERIMETER GATES
------------------------------------------------------------
local bridgeLength = 36
local bridgeWidth = 16
local bridgeZ = -78

local bridge = makePart({
	Name = "CyberBridge",
	Size = Vector3.new(bridgeWidth, 2, bridgeLength),
	CFrame = CFrame.new(0, 8, bridgeZ),
	Color = Color3.fromRGB(28, 22, 45),
	Material = Enum.Material.Metal,
	GalacticTexture = true,
	TileSize = 16,
	Parent = lobbyFolder,
})

makePart({ Name = "BridgeRailL", Size = Vector3.new(1, 3.5, bridgeLength), CFrame = CFrame.new(-bridgeWidth/2, 10.5, bridgeZ), Color = Color3.fromRGB(0, 240, 255), Material = Enum.Material.Neon, Parent = lobbyFolder })
makePart({ Name = "BridgeRailR", Size = Vector3.new(1, 3.5, bridgeLength), CFrame = CFrame.new(bridgeWidth/2, 10.5, bridgeZ),  Color = Color3.fromRGB(0, 240, 255), Material = Enum.Material.Neon, Parent = lobbyFolder })

------------------------------------------------------------
-- 4. GALACTIC ARENA WITH NEBULA FLOOR
------------------------------------------------------------
local arenaSize = Vector3.new(190, 4, 190)

-- Deep Cosmic Space Floor
makePart({
	Name = "GalacticGround",
	Size = arenaSize,
	CFrame = CFrame.new(0, 0, 0),
	Color = Color3.fromRGB(12, 10, 22),
	Material = Enum.Material.Slate,
	GalacticTexture = true,
	TileSize = 35,
	TexTransparency = 0.2,
	Parent = arenaFolder,
})

-- Forcefield Barriers with Star Glow
local pWallHeight = 35
local pWallThick = 2
local halfX = arenaSize.X / 2
local halfZ = arenaSize.Z / 2

makePart({ Name = "BarrierN", Size = Vector3.new(arenaSize.X, pWallHeight, pWallThick), CFrame = CFrame.new(0, pWallHeight/2, -halfZ), Color = Color3.fromRGB(150, 50, 255), Material = Enum.Material.ForceField, Transparency = 0.65, Parent = arenaFolder })
makePart({ Name = "BarrierS", Size = Vector3.new(arenaSize.X, pWallHeight, pWallThick), CFrame = CFrame.new(0, pWallHeight/2, halfZ),  Color = Color3.fromRGB(150, 50, 255), Material = Enum.Material.ForceField, Transparency = 0.65, Parent = arenaFolder })
makePart({ Name = "BarrierE", Size = Vector3.new(pWallThick, pWallHeight, arenaSize.Z), CFrame = CFrame.new(halfX, pWallHeight/2, 0),  Color = Color3.fromRGB(150, 50, 255), Material = Enum.Material.ForceField, Transparency = 0.65, Parent = arenaFolder })
makePart({ Name = "BarrierW", Size = Vector3.new(pWallThick, pWallHeight, arenaSize.Z), CFrame = CFrame.new(-halfX, pWallHeight/2, 0), Color = Color3.fromRGB(150, 50, 255), Material = Enum.Material.ForceField, Transparency = 0.65, Parent = arenaFolder })

------------------------------------------------------------
-- 5. CENTRAL VAULT DAIS & SWIRLING COSMIC VORTEX
------------------------------------------------------------
local corePos = Config.VAULT_CORE_POS

makePart({ Name = "DaisBase", Size = Vector3.new(46, 4, 46), CFrame = CFrame.new(corePos + Vector3.new(0, -2, 0)), Color = Color3.fromRGB(22, 16, 38), Material = Enum.Material.Metal, GalacticTexture = true, TileSize = 16, Parent = arenaFolder })
makePart({ Name = "DaisTop",  Size = Vector3.new(36, 4, 36), CFrame = CFrame.new(corePos + Vector3.new(0, 2, 0)),  Color = Color3.fromRGB(30, 22, 50), Material = Enum.Material.Metal, GalacticTexture = true, TileSize = 12, Parent = arenaFolder })
makePart({ Name = "DaisTrim", Size = Vector3.new(37, 0.6, 37), CFrame = CFrame.new(corePos + Vector3.new(0, 4.3, 0)), Color = Color3.fromRGB(255, 40, 200), Material = Enum.Material.Neon, Parent = arenaFolder })

-- Swirling Cosmic Vortex in Central Vault
local vortexPart = makePart({
	Name = "CosmicVortexCenter",
	Size = Vector3.new(12, 0.4, 12),
	CFrame = CFrame.new(corePos + Vector3.new(0, 4.4, 0)),
	Color = Color3.fromRGB(255, 0, 180),
	Material = Enum.Material.Neon,
	Parent = arenaFolder,
})
vortexPart.Shape = Enum.PartType.Cylinder
vortexPart.CFrame = CFrame.new(corePos + Vector3.new(0, 4.4, 0)) * CFrame.Angles(0, 0, math.rad(90))

local vortexEmitter = Instance.new("ParticleEmitter")
vortexEmitter.Name = "VortexSwirl"
vortexEmitter.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 200)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 230, 255)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 215, 0)),
})
vortexEmitter.Size = NumberSequence.new(1.4, 0.1)
vortexEmitter.Lifetime = NumberRange.new(1.5, 2.5)
vortexEmitter.Rate = 40
vortexEmitter.Speed = NumberRange.new(5, 12)
vortexEmitter.SpreadAngle = Vector2.new(180, 180)
vortexEmitter.Parent = vortexPart

-- 4 Obsidian Energy Pillars
local pillarLocs = {
	Vector3.new(15, 12, 15),
	Vector3.new(-15, 12, 15),
	Vector3.new(15, 12, -15),
	Vector3.new(-15, 12, -15),
}
for i, pOffset in ipairs(pillarLocs) do
	makePart({
		Name = "CorePillar_" .. i,
		Size = Vector3.new(4, 26, 4),
		CFrame = CFrame.new(corePos + pOffset),
		Color = Color3.fromRGB(0, 240, 255),
		Material = Enum.Material.Neon,
		Parent = arenaFolder,
	})
end

-- Ramps to Vault Center
local function makeRamp(name, cf)
	local r = Instance.new("WedgePart")
	r.Name = name
	r.Size = Vector3.new(12, 6, 22)
	r.CFrame = cf
	r.Color = Color3.fromRGB(34, 26, 54)
	r.Material = Enum.Material.Metal
	r.Anchored = true
	r.Parent = arenaFolder
	return r
end

makeRamp("RampNorth", CFrame.new(0, 1, -29) * CFrame.Angles(0, math.rad(180), 0))
makeRamp("RampSouth", CFrame.new(0, 1, 29) * CFrame.Angles(0, 0, 0))
makeRamp("RampEast",  CFrame.new(29, 1, 0) * CFrame.Angles(0, math.rad(90), 0))
makeRamp("RampWest",  CFrame.new(-29, 1, 0) * CFrame.Angles(0, math.rad(-90), 0))

------------------------------------------------------------
-- 6. FOUR CORNER HAZARD TOWERS
------------------------------------------------------------
local towerCoords = {
	Vector3.new(62, 0, 62),
	Vector3.new(-62, 0, 62),
	Vector3.new(62, 0, -62),
	Vector3.new(-62, 0, -62),
}

for i, tPos in ipairs(towerCoords) do
	makePart({ Name = "TowerPlatform_" .. i, Size = Vector3.new(24, 12, 24), CFrame = CFrame.new(tPos + Vector3.new(0, 6, 0)), Color = Color3.fromRGB(24, 18, 40), Material = Enum.Material.Slate, GalacticTexture = true, TileSize = 14, Parent = arenaFolder })
	makePart({ Name = "TowerTrim_" .. i, Size = Vector3.new(25, 0.8, 25), CFrame = CFrame.new(tPos + Vector3.new(0, 12.4, 0)), Color = Color3.fromRGB(255, 180, 0), Material = Enum.Material.Neon, Parent = arenaFolder })
	makePart({ Name = "TowerPedestal_" .. i, Size = Vector3.new(6, 1.2, 6), CFrame = CFrame.new(tPos + Vector3.new(0, 13.2, 0)), Color = Color3.fromRGB(0, 240, 255), Material = Enum.Material.Neon, Parent = arenaFolder })
end

------------------------------------------------------------
-- 7. KINETIC BOUNCE PADS (Super Fling)
------------------------------------------------------------
local bounceLocations = {
	{ Pos = Vector3.new(38, 0.6, 38),   Dir = Vector3.new(-45, 85, -45) },
	{ Pos = Vector3.new(-38, 0.6, 38),  Dir = Vector3.new(45, 85, -45) },
	{ Pos = Vector3.new(38, 0.6, -38),  Dir = Vector3.new(-45, 85, 45) },
	{ Pos = Vector3.new(-38, 0.6, -38), Dir = Vector3.new(45, 85, 45) },
}

for i, bData in ipairs(bounceLocations) do
	local bPad = makePart({
		Name = "KineticPad_" .. i,
		Size = Vector3.new(8, 0.8, 8),
		CFrame = CFrame.new(bData.Pos),
		Color = Color3.fromRGB(0, 255, 140),
		Material = Enum.Material.Neon,
		Parent = arenaFolder,
	})

	local padDebounce = {}
	bPad.Touched:Connect(function(hit)
		local char = hit.Parent
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and not padDebounce[char] then
			padDebounce[char] = true

			local snd = Instance.new("Sound")
			snd.SoundId = Config.SOUNDS.JumpPad
			snd.Volume = 1.0
			snd.PlayOnRemove = true
			snd.Parent = bPad
			snd:Destroy()

			hrp.AssemblyLinearVelocity = bData.Dir

			bPad.Color = Color3.fromRGB(255, 255, 255)
			task.wait(0.2)
			bPad.Color = Color3.fromRGB(0, 255, 140)
			task.wait(0.5)
			padDebounce[char] = nil
		end
	end)
end

print("[ChronosVault] Galactic Cosmic Map with Textures & Vortex Built ✓")
