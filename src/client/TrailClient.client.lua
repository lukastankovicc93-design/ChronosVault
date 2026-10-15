--[[
    TrailClient.client.lua (StarterPlayerScripts)
    Attaches a stylish neon speed trail to the player's character.
    Scales dynamically with the player's Speed level!
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local SyncDataEvent = ReplicatedStorage:WaitForChild("SyncData")

local currentSpeedLevel = 0

local function attachTrail(char)
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	-- Remove old trail if any
	local oldTrail = hrp:FindFirstChild("SpeedTrail")
	if oldTrail then oldTrail:Destroy() end

	local att0 = Instance.new("Attachment")
	att0.Name = "TrailAtt0"
	att0.Position = Vector3.new(0, 1.2, 0)
	att0.Parent = hrp

	local att1 = Instance.new("Attachment")
	att1.Name = "TrailAtt1"
	att1.Position = Vector3.new(0, -1.2, 0)
	att1.Parent = hrp

	local trail = Instance.new("Trail")
	trail.Name = "SpeedTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 240, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 50, 220)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 215, 0)),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.2),
		NumberSequenceKeypoint.new(1.0, 1.0),
	})
	trail.Lifetime = 0.2 + (currentSpeedLevel * 0.08)
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.Parent = hrp
end

player.CharacterAdded:Connect(attachTrail)
if player.Character then
	attachTrail(player.Character)
end

SyncDataEvent.OnClientEvent:Connect(function(data)
	if data and data.SpeedLevel then
		currentSpeedLevel = data.SpeedLevel
		if player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			local trail = hrp and hrp:FindFirstChild("SpeedTrail")
			if trail then
				trail.Lifetime = 0.2 + (currentSpeedLevel * 0.08)
			end
		end
	end
end)
