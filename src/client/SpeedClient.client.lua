--[[
    SpeedClient.client.lua (StarterPlayerScripts)
    Client-side logic for:
    - Speed upgrade UI (ScreenGui with buy button)
    - Egg counter HUD
    - Round status display
    - Communicates with server via RemoteEvents
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer

------------------------------------------------------------
-- WAIT FOR REMOTES
------------------------------------------------------------
local BuySpeedEvent   = ReplicatedStorage:WaitForChild("BuySpeed")
local StatusEvent     = ReplicatedStorage:WaitForChild("RoundStatus")
local EggCountEvent   = ReplicatedStorage:WaitForChild("EggCount")
local SpeedLevelEvent = ReplicatedStorage:WaitForChild("SpeedLevel")

------------------------------------------------------------
-- STATE
------------------------------------------------------------
local currentEggs   = 0
local currentSpeed  = 0
local MAX_SPEED     = 5
local COST_BASE     = 3
local COST_MULT     = 1.5

------------------------------------------------------------
-- CREATE GUI
------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChronosHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- Status label (top center)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0.5, 0, 0, 40)
statusLabel.Position = UDim2.new(0.25, 0, 0.02, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
statusLabel.BackgroundTransparency = 0.3
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = "Waiting..."
statusLabel.Parent = screenGui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusLabel

-- Egg counter (top left)
local eggLabel = Instance.new("TextLabel")
eggLabel.Name = "EggCounter"
eggLabel.Size = UDim2.new(0, 180, 0, 50)
eggLabel.Position = UDim2.new(0.02, 0, 0.1, 0)
eggLabel.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
eggLabel.BackgroundTransparency = 0.2
eggLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
eggLabel.TextScaled = true
eggLabel.Font = Enum.Font.GothamBold
eggLabel.Text = "🥚 0"
eggLabel.Parent = screenGui

local eggCorner = Instance.new("UICorner")
eggCorner.CornerRadius = UDim.new(0, 10)
eggCorner.Parent = eggLabel

-- Speed upgrade button (bottom center)
local buyButton = Instance.new("TextButton")
buyButton.Name = "BuySpeedBtn"
buyButton.Size = UDim2.new(0, 260, 0, 55)
buyButton.Position = UDim2.new(0.5, -130, 0.88, 0)
buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
buyButton.TextScaled = true
buyButton.Font = Enum.Font.GothamBold
buyButton.Text = "⚡ Buy Speed (3 eggs)"
buyButton.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = buyButton

-- Speed level indicator
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLevel"
speedLabel.Size = UDim2.new(0, 180, 0, 35)
speedLabel.Position = UDim2.new(0.02, 0, 0.17, 0)
speedLabel.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
speedLabel.BackgroundTransparency = 0.2
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.GothamBold
speedLabel.Text = "⚡ Speed: 0/" .. MAX_SPEED
speedLabel.Parent = screenGui

local spdCorner = Instance.new("UICorner")
spdCorner.CornerRadius = UDim.new(0, 10)
spdCorner.Parent = speedLabel

------------------------------------------------------------
-- UPDATE FUNCTIONS
------------------------------------------------------------
local function updateEggDisplay()
	eggLabel.Text = "🥚 " .. currentEggs
	-- Pulse animation
	local tween = TweenService:Create(eggLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 200, 0, 56)
	})
	tween:Play()
	tween.Completed:Connect(function()
		TweenService:Create(eggLabel, TweenInfo.new(0.15), {
			Size = UDim2.new(0, 180, 0, 50)
		}):Play()
	end)
end

local function updateSpeedDisplay()
	speedLabel.Text = "⚡ Speed: " .. currentSpeed .. "/" .. MAX_SPEED
	local cost = math.floor(COST_BASE * (COST_MULT ^ currentSpeed))

	if currentSpeed >= MAX_SPEED then
		buyButton.Text = "⚡ MAX SPEED!"
		buyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	else
		buyButton.Text = "⚡ Buy Speed (" .. cost .. " eggs)"
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	end
end

------------------------------------------------------------
-- EVENT HANDLERS
------------------------------------------------------------
EggCountEvent.OnClientEvent:Connect(function(eggs: number)
	currentEggs = eggs
	updateEggDisplay()
end)

SpeedLevelEvent.OnClientEvent:Connect(function(level: number)
	currentSpeed = level
	updateSpeedDisplay()
end)

StatusEvent.OnClientEvent:Connect(function(message: string)
	statusLabel.Text = message
end)

------------------------------------------------------------
-- BUY BUTTON
------------------------------------------------------------
local debounce = false
buyButton.MouseButton1Click:Connect(function()
	if debounce then return end
	if currentSpeed >= MAX_SPEED then return end
	debounce = true

	BuySpeedEvent:FireServer()

	-- Visual feedback
	buyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	task.wait(0.3)
	updateSpeedDisplay()
	debounce = false
end)

-- Initial display
updateSpeedDisplay()
print("[ChronosVault] SpeedClient loaded ✓")
