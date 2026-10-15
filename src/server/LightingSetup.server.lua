--[[
    LightingSetup.server.lua (ServerScriptService)
    Cosmic Galactic Atmosphere:
    - Deep Space Nebula Skybox with authentic high-res space textures
    - Future/ShadowMap technology with sharp neon rim lighting
    - Cosmic ColorCorrection for vibrant galaxy purples, cyans, and golds
    - High-intensity Bloom for pulsing Chronos lasers and egg auras
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- 1. Base Lighting Properties
Lighting.Technology = Enum.Technology.ShadowMap
Lighting.ClockTime = 0.5  -- Midnight space ambience
Lighting.Brightness = 1.8
Lighting.Ambient = Color3.fromRGB(45, 35, 65)
Lighting.OutdoorAmbient = Color3.fromRGB(80, 70, 115)
Lighting.ShadowSoftness = 0.15
Lighting.GlobalShadows = true

-- 2. Cleanup previous effects
for _, child in ipairs(Lighting:GetChildren()) do
	if child:IsA("PostProcessEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
		child:Destroy()
	end
end

-- 3. Galactic Purple/Pink Nebula Skybox
local sky = Instance.new("Sky")
sky.Name = "GalacticNebulaSky"
sky.SkyboxBk = Config.SKYBOX.Bk
sky.SkyboxDn = Config.SKYBOX.Dn
sky.SkyboxFt = Config.SKYBOX.Ft
sky.SkyboxLf = Config.SKYBOX.Lf
sky.SkyboxRt = Config.SKYBOX.Rt
sky.SkyboxUp = Config.SKYBOX.Up
sky.StarCount = 5000
sky.CelestialBodiesShown = true
sky.Parent = Lighting

-- 4. Cosmic ColorCorrection
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "GalacticColorCorrection"
cc.Brightness = 0.05
cc.Contrast = 0.28
cc.Saturation = 0.45
cc.TintColor = Color3.fromRGB(240, 230, 255)
cc.Parent = Lighting

-- 5. Radiant Bloom (Pulsing Eggs & Lasers)
local bloom = Instance.new("BloomEffect")
bloom.Name = "GalacticBloom"
bloom.Intensity = 0.9
bloom.Size = 25
bloom.Threshold = 0.8
bloom.Parent = Lighting

-- 6. Space Atmosphere
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "GalacticAtmosphere"
atmosphere.Density = 0.22
atmosphere.Offset = 0.3
atmosphere.Color = Color3.fromRGB(130, 90, 200)
atmosphere.Decay = Color3.fromRGB(60, 30, 110)
atmosphere.Glare = 0.4
atmosphere.Haze = 1.5
atmosphere.Parent = Lighting

print("[ChronosVault] Galactic Skybox & Cosmic Lighting Applied ✓")
