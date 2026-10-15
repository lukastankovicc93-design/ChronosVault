--[[
    LightingSetup.server.lua (ServerScriptService)
    Transforms flat default lighting into a high-end, vibrant, stylized sci-fi aesthetic:
    - ShadowMap / Future technology with crisp shadows
    - Custom ColorCorrection for vivid arcade saturation & punchy contrast
    - Bloom for dazzling neon reflections & egg auras
    - Cyber atmosphere with subtle haze
]]

local Lighting = game:GetService("Lighting")

-- 1. Base lighting technology & atmosphere
Lighting.Technology = Enum.Technology.ShadowMap
Lighting.ClockTime = 15.0
Lighting.GeographicLatitude = 35
Lighting.Brightness = 2.4
Lighting.Ambient = Color3.fromRGB(70, 75, 95)
Lighting.OutdoorAmbient = Color3.fromRGB(110, 120, 150)
Lighting.ShadowSoftness = 0.2
Lighting.GlobalShadows = true

-- 2. Clear out any existing effects
for _, child in ipairs(Lighting:GetChildren()) do
	if child:IsA("PostProcessEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
		child:Destroy()
	end
end

-- 3. Vivid ColorCorrection (Arcade/Simulator Pop)
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "ChronosColorCorrection"
cc.Brightness = 0.04
cc.Contrast = 0.22
cc.Saturation = 0.40
cc.TintColor = Color3.fromRGB(250, 245, 255)
cc.Parent = Lighting

-- 4. Bloom Effect (Pulsing Neon Lights & Eggs)
local bloom = Instance.new("BloomEffect")
bloom.Name = "ChronosBloom"
bloom.Intensity = 0.75
bloom.Size = 22
bloom.Threshold = 0.82
bloom.Parent = Lighting

-- 5. Sun Rays
local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "ChronosSunRays"
sunRays.Intensity = 0.18
sunRays.Spread = 0.85
sunRays.Parent = Lighting

-- 6. Modern Atmosphere
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "ChronosAtmosphere"
atmosphere.Density = 0.28
atmosphere.Offset = 0.25
atmosphere.Color = Color3.fromRGB(160, 190, 240)
atmosphere.Decay = Color3.fromRGB(80, 100, 160)
atmosphere.Glare = 0.2
atmosphere.Haze = 1.2
atmosphere.Parent = Lighting

-- 7. High-tech Skybox (Deep Blue & Starry)
local sky = Instance.new("Sky")
sky.Name = "ChronosSky"
sky.SkyboxBk = "rbxassetid://600830446"
sky.SkyboxDn = "rbxassetid://600831635"
sky.SkyboxFt = "rbxassetid://600832720"
sky.SkyboxLf = "rbxassetid://600834110"
sky.SkyboxRt = "rbxassetid://600835177"
sky.SkyboxUp = "rbxassetid://600836162"
sky.StarCount = 4500
sky.CelestialBodiesShown = true
sky.Parent = Lighting

print("[ChronosVault] Advanced AAA Lighting Applied ✓")
