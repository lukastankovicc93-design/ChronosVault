--[[
    MapBuilder.server.lua (ServerScriptService)
    Procedurally builds the entire Chronos Vault environment on startup:
    - Lobby / Safe Zone with SpawnLocations
    - 2 Physical Interactive Shops: "⚡ Speed Lab" & "💎 Vault Perks"
    - ProximityPrompts & Step-on Touch Pads for shops
    - Cyber-bridge with warning gates
    - Chronos Vault Arena with central vault dais, 4 energy pillars, corner towers
    - Kinetic Bounce Pads for high-speed parkour escapes
    - Forcefield perimeter walls
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Ensure OpenShop RemoteEvent exists
local OpenShopEvent = ReplicatedStorage:FindFirstChild("OpenShop")
if not OpenShopEvent then
	OpenShopEvent = Instance.new("RemoteEvent")
	OpenShopEvent.Name = "OpenShop"
	OpenShopEvent.Parent = ReplicatedStorage
end

------------------------------------------------------------
-- CLEANUP PREVIOUS MAP (if hot reloading)
------------------------------------------------------------
if workspace:FindFirstChild("ChronosMap") then
	workspace.ChronosMap:Destroy()
end

local mapFolder = Instance.new("Folder")
mapFolder.Name = "ChronosMap"
mapFolder.Parent = workspace

local shopsFolder = Instance.new("Folder")
shopsFolder.Name = "Shops"
shopsFolder.Parent = mapFolder

local padsFolder = Instance.new("Folder")
padsFolder.Name = "JumpPads"
padsFolder.Parent = mapFolder

------------------------------------------------------------
-- HELPER BUILDERS
------------------------------------------------------------
local function createPart(name, size, cframe, color, material, parent, canCollide, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color or Color3.fromRGB(60, 60, 70)
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = (canCollide ~= false)
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or mapFolder
	return p
end

------------------------------------------------------------
-- 1. LOBBY / SAFE ZONE
------------------------------------------------------------
local lobbyPos = Config.LOBBY_CENTER
local lobbySize = Config.LOBBY_SIZE

-- Main lobby floor
local lobbyFloor = createPart(
	"LobbyFloor",
	lobbySize,
	CFrame.new(lobbyPos),
	Color3.fromRGB(24, 28, 44),
	Enum.Material.Slate,
	mapFolder
)

-- Neon glowing border around lobby
local borderThickness = 1.5
createPart("LobbyBorderN", Vector3.new(lobbySize.X, 2, borderThickness), CFrame.new(lobbyPos + Vector3.new(0, 2.5, -lobbySize.Z/2)), Color3.fromRGB(0, 230, 255), Enum.Material.Neon, mapFolder)
createPart("LobbyBorderE", Vector3.new(borderThickness, 2, lobbySize.Z), CFrame.new(lobbyPos + Vector3.new(lobbySize.X/2, 2.5, 0)), Color3.fromRGB(0, 230, 255), Enum.Material.Neon, mapFolder)
createPart("LobbyBorderW", Vector3.new(borderThickness, 2, lobbySize.Z), CFrame.new(lobbyPos + Vector3.new(-lobbySize.X/2, 2.5, 0)), Color3.fromRGB(0, 230, 255), Enum.Material.Neon, mapFolder)

-- SpawnLocations
for i = -1, 1 do
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn_" .. (i + 2)
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = lobbyPos + Vector3.new(i * 12, 2.5, 5)
	spawn.Color = Color3.fromRGB(0, 200, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Neutral = true
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Duration = 0
	spawn.Parent = mapFolder
end

-- Welcome Archway / Billboard
local archPoleL = createPart("ArchL", Vector3.new(2, 14, 2), CFrame.new(lobbyPos + Vector3.new(-18, 9, 20)), Color3.fromRGB(40, 45, 65), Enum.Material.Metal)
local archPoleR = createPart("ArchR", Vector3.new(2, 14, 2), CFrame.new(lobbyPos + Vector3.new(18, 9, 20)), Color3.fromRGB(40, 45, 65), Enum.Material.Metal)
local archBeam  = createPart("ArchTop", Vector3.new(38, 3, 2), CFrame.new(lobbyPos + Vector3.new(0, 16.5, 20)), Color3.fromRGB(0, 220, 255), Enum.Material.Neon)

local titleGui = Instance.new("BillboardGui")
titleGui.Name = "WelcomeTitle"
titleGui.Size = UDim2.new(0, 500, 0, 90)
titleGui.StudsOffset = Vector3.new(0, 2.5, 0)
titleGui.AlwaysOnTop = true
titleGui.Adornee = archBeam
titleGui.Parent = archBeam

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, 0, 0.6, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3 = Color3.fromRGB(0, 240, 255)
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextScaled = true
titleLbl.Text = "🏛️ CHRONOS VAULT"
titleLbl.Parent = titleGui

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(1, 0, 0.4, 0)
subLbl.Position = UDim2.new(0, 0, 0.6, 0)
subLbl.BackgroundTransparency = 1
subLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
subLbl.Font = Enum.Font.GothamMedium
subLbl.TextScaled = true
subLbl.Text = "Steal Eggs • Visit Shops • Upgrade Speed & Perks!"
subLbl.Parent = titleGui

------------------------------------------------------------
-- 2. PHYSICAL SHOPS IN LOBBY
------------------------------------------------------------
local function buildShopBooth(shopType, shopName, shopColor, iconText, position)
	local boothModel = Instance.new("Model")
	boothModel.Name = shopType .. "Shop"
	boothModel.Parent = shopsFolder

	-- Base / counter
	local counter = createPart("Counter", Vector3.new(16, 4, 8), CFrame.new(position + Vector3.new(0, 2, 0)), Color3.fromRGB(30, 35, 50), Enum.Material.Metal, boothModel)
	createPart("CounterTop", Vector3.new(17, 0.6, 8.5), CFrame.new(position + Vector3.new(0, 4.3, 0)), shopColor, Enum.Material.Neon, boothModel)

	-- Back wall & Roof
	createPart("BackWall", Vector3.new(16, 12, 1.5), CFrame.new(position + Vector3.new(0, 8, -4)), Color3.fromRGB(20, 22, 35), Enum.Material.Slate, boothModel)
	createPart("Roof", Vector3.new(18, 1.5, 10), CFrame.new(position + Vector3.new(0, 14.5, 0)), Color3.fromRGB(30, 35, 55), Enum.Material.Metal, boothModel)
	createPart("RoofTrim", Vector3.new(18.5, 0.8, 10.5), CFrame.new(position + Vector3.new(0, 15, 0)), shopColor, Enum.Material.Neon, boothModel)

	-- Floating 3D Title Sign
	local signPart = createPart("SignPart", Vector3.new(14, 3, 1), CFrame.new(position + Vector3.new(0, 17, 0)), shopColor, Enum.Material.Neon, boothModel)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 280, 0, 70)
	bb.StudsOffset = Vector3.new(0, 1.5, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = signPart
	bb.Parent = signPart

	local signLbl = Instance.new("TextLabel")
	signLbl.Size = UDim2.new(1, 0, 1, 0)
	signLbl.BackgroundTransparency = 1
	signLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	signLbl.TextStrokeTransparency = 0.2
	signLbl.Font = Enum.Font.GothamBold
	signLbl.TextScaled = true
	signLbl.Text = iconText .. " " .. shopName
	signLbl.Parent = bb

	-- Proximity Prompt on Counter
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ObjectText = shopName
	prompt.ActionText = "Open Shop"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter

	prompt.Triggered:Connect(function(player)
		OpenShopEvent:FireClient(player, shopType)
	end)

	-- Step-on glowing shop pad
	local pad = createPart("ShopPad", Vector3.new(10, 0.4, 6), CFrame.new(position + Vector3.new(0, 0.3, 7)), shopColor, Enum.Material.Neon, boothModel, true, 0.3)
	
	-- Pad touch opens shop too (for mobile / fast-run)
	local padDebounce = {}
	pad.Touched:Connect(function(hit)
		local char = hit.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if player and not padDebounce[player] then
			padDebounce[player] = true
			OpenShopEvent:FireClient(player, shopType)
			task.wait(2)
			padDebounce[player] = nil
		end
	end)
end

-- Build Speed Lab (Left side)
buildShopBooth(
	"Speed",
	"SPEED LAB",
	Color3.fromRGB(0, 190, 255),
	"⚡",
	lobbyPos + Vector3.new(-26, 0, -10)
)

-- Build Vault Perks (Right side)
buildShopBooth(
	"Perks",
	"VAULT PERKS",
	Color3.fromRGB(255, 190, 0),
	"💎",
	lobbyPos + Vector3.new(26, 0, -10)
)

------------------------------------------------------------
-- 3. BRIDGE TO ARENA
------------------------------------------------------------
local bridgeLength = 32
local bridgeWidth = 14
local bridgeStart = lobbyPos.Z + (lobbySize.Z / 2) -- e.g. -120 + 30 = -90
local bridgeZ = -75
local bridgeFloor = createPart(
	"BridgeFloor",
	Vector3.new(bridgeWidth, 2, bridgeLength),
	CFrame.new(0, 6, bridgeZ),
	Color3.fromRGB(35, 40, 55),
	Enum.Material.Metal,
	mapFolder
)
-- Bridge rails
createPart("BridgeRailL", Vector3.new(1, 3, bridgeLength), CFrame.new(-bridgeWidth/2, 8, bridgeZ), Color3.fromRGB(0, 220, 255), Enum.Material.Neon, mapFolder)
createPart("BridgeRailR", Vector3.new(1, 3, bridgeLength), CFrame.new(bridgeWidth/2, 8, bridgeZ), Color3.fromRGB(0, 220, 255), Enum.Material.Neon, mapFolder)

------------------------------------------------------------
-- 4. CHRONOS VAULT ARENA
------------------------------------------------------------
local arenaSize = Config.ARENA_SIZE
local arenaFloor = createPart(
	"ArenaFloor",
	arenaSize,
	CFrame.new(Config.ARENA_CENTER),
	Color3.fromRGB(20, 22, 32),
	Enum.Material.Slate,
	mapFolder
)

-- Arena perimeter neon barrier walls
local wallHeight = 28
local wallThick = 2
local halfX = arenaSize.X / 2
local halfZ = arenaSize.Z / 2

createPart("WallNorth", Vector3.new(arenaSize.X, wallHeight, wallThick), CFrame.new(0, wallHeight/2, -halfZ), Color3.fromRGB(0, 180, 255), Enum.Material.ForceField, mapFolder, true, 0.6)
createPart("WallSouth", Vector3.new(arenaSize.X, wallHeight, wallThick), CFrame.new(0, wallHeight/2, halfZ), Color3.fromRGB(0, 180, 255), Enum.Material.ForceField, mapFolder, true, 0.6)
createPart("WallEast",  Vector3.new(wallThick, wallHeight, arenaSize.Z), CFrame.new(halfX, wallHeight/2, 0), Color3.fromRGB(0, 180, 255), Enum.Material.ForceField, mapFolder, true, 0.6)
createPart("WallWest",  Vector3.new(wallThick, wallHeight, arenaSize.Z), CFrame.new(-halfX, wallHeight/2, 0), Color3.fromRGB(0, 180, 255), Enum.Material.ForceField, mapFolder, true, 0.6)

------------------------------------------------------------
-- 5. CENTRAL VAULT DAIS & PILLARS
------------------------------------------------------------
local vaultCenter = Config.VAULT_CORE_POS

-- Main raised circular platform
local vaultDais = createPart(
	"VaultCoreDais",
	Vector3.new(38, 6, 38),
	CFrame.new(vaultCenter + Vector3.new(0, -3, 0)),
	Color3.fromRGB(30, 32, 45),
	Enum.Material.Metal,
	mapFolder
)
createPart("VaultDaisTrim", Vector3.new(39, 1, 39), CFrame.new(vaultCenter + Vector3.new(0, 0.3, 0)), Color3.fromRGB(255, 60, 180), Enum.Material.Neon, mapFolder)

-- 4 Corner Energy Pillars
local pillarOffsets = {
	Vector3.new(16, 8, 16),
	Vector3.new(-16, 8, 16),
	Vector3.new(16, 8, -16),
	Vector3.new(-16, 8, -16),
}
for i, offset in ipairs(pillarOffsets) do
	local pillar = createPart("EnergyPillar_" .. i, Vector3.new(3.5, 20, 3.5), CFrame.new(vaultCenter + offset), Color3.fromRGB(0, 240, 255), Enum.Material.Neon, mapFolder)
end

-- Center Chronos Core (Pulsing Diamond)
local corePart = createPart("ChronosCore", Vector3.new(6, 6, 6), CFrame.new(vaultCenter + Vector3.new(0, 7, 0)), Color3.fromRGB(255, 40, 150), Enum.Material.Neon, mapFolder, false)
corePart.Shape = Enum.PartType.Ball

-- Central Pedestal for Rare Core Egg
local corePedestal = createPart("CorePedestal", Vector3.new(8, 2, 8), CFrame.new(vaultCenter + Vector3.new(0, 1, 0)), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, mapFolder)

-- 4 Ramps leading up to vault center
local rampLength = 20
local rampHeight = 6
local rampWidth = 10
local function createRamp(name, cf)
	local ramp = Instance.new("WedgePart")
	ramp.Name = name
	ramp.Size = Vector3.new(rampWidth, rampHeight, rampLength)
	ramp.CFrame = cf
	ramp.Color = Color3.fromRGB(40, 45, 65)
	ramp.Material = Enum.Material.Metal
	ramp.Anchored = true
	ramp.Parent = mapFolder
	return ramp
end

createRamp("VaultRampN", CFrame.new(0, 0, -29) * CFrame.Angles(0, math.rad(180), 0))
createRamp("VaultRampS", CFrame.new(0, 0, 29) * CFrame.Angles(0, 0, 0))
createRamp("VaultRampE", CFrame.new(29, 0, 0) * CFrame.Angles(0, math.rad(90), 0))
createRamp("VaultRampW", CFrame.new(-29, 0, 0) * CFrame.Angles(0, math.rad(-90), 0))

------------------------------------------------------------
-- 6. FOUR CORNER HAZARD TOWERS
------------------------------------------------------------
local towerCoords = {
	Vector3.new(60, 0, 60),
	Vector3.new(-60, 0, 60),
	Vector3.new(60, 0, -60),
	Vector3.new(-60, 0, -60),
}

for i, pos in ipairs(towerCoords) do
	local towerPlatform = createPart("Tower_" .. i, Vector3.new(22, 10, 22), CFrame.new(pos + Vector3.new(0, 5, 0)), Color3.fromRGB(28, 30, 42), Enum.Material.Slate, mapFolder)
	createPart("TowerTrim_" .. i, Vector3.new(23, 1, 23), CFrame.new(pos + Vector3.new(0, 10.3, 0)), Color3.fromRGB(255, 200, 0), Enum.Material.Neon, mapFolder)

	-- Egg spawn pedestal on top of tower
	createPart("TowerPedestal_" .. i, Vector3.new(5, 1, 5), CFrame.new(pos + Vector3.new(0, 11, 0)), Color3.fromRGB(0, 220, 255), Enum.Material.Neon, mapFolder)
end

------------------------------------------------------------
-- 7. KINETIC BOUNCE / JUMP PADS
------------------------------------------------------------
local padLocations = {
	{ Pos = Vector3.new(35, 1.2, 35),   Dir = Vector3.new(-40, 75, -40) },
	{ Pos = Vector3.new(-35, 1.2, 35),  Dir = Vector3.new(40, 75, -40) },
	{ Pos = Vector3.new(35, 1.2, -35),  Dir = Vector3.new(-40, 75, 40) },
	{ Pos = Vector3.new(-35, 1.2, -35), Dir = Vector3.new(40, 75, 40) },
}

for i, padData in ipairs(padLocations) do
	local bPad = createPart("BouncePad_" .. i, Vector3.new(7, 0.8, 7), CFrame.new(padData.Pos), Color3.fromRGB(50, 255, 100), Enum.Material.Neon, padsFolder)

	local bDebounce = {}
	bPad.Touched:Connect(function(hit)
		local char = hit.Parent
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChild("Humanoid")
		if hrp and hum and not bDebounce[char] then
			bDebounce[char] = true
			-- Kinetic fling upward & toward center
			hrp.AssemblyLinearVelocity = padData.Dir

			-- Visual flash
			bPad.Color = Color3.fromRGB(255, 255, 255)
			task.wait(0.3)
			bPad.Color = Color3.fromRGB(50, 255, 100)
			task.wait(0.5)
			bDebounce[char] = nil
		end
	end)
end

print("[ChronosVault] Map & Shops built successfully ✓")
