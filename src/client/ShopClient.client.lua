--[[
    ShopClient.client.lua (StarterPlayerScripts)
    Interactive client interface for Chronos Vault:
    - Real-time HUD (Egg counter, round status, stats bar)
    - Full Cyberpunk Shop GUI (Tabs: Speed Lab & Vault Perks)
    - Integrates with physical in-game shop booths (ProximityPrompt & TouchPads)
    - Dynamic Buy buttons with real-time affordance checks
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

------------------------------------------------------------
-- WAIT FOR REMOTES
------------------------------------------------------------
local BuyUpgradeEvent = ReplicatedStorage:WaitForChild("BuyUpgrade")
local SyncDataEvent   = ReplicatedStorage:WaitForChild("SyncData")
local StatusEvent     = ReplicatedStorage:WaitForChild("RoundStatus")
local OpenShopEvent   = ReplicatedStorage:WaitForChild("OpenShop")

------------------------------------------------------------
-- CLIENT CACHED STATE
------------------------------------------------------------
local stats = {
	Eggs            = 0,
	TotalEggs       = 0,
	SpeedLevel      = 0,
	MultiplierLevel = 0,
	JumpLevel       = 0,
	MagnetLevel     = 0,
}

local activeTab = "Speed" -- "Speed" or "Perks"

------------------------------------------------------------
-- CREATE MAIN SCREEN GUI
------------------------------------------------------------
local pGui = player:WaitForChild("PlayerGui")

-- Cleanup existing
if pGui:FindFirstChild("ChronosGUI") then
	pGui.ChronosGUI:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ChronosGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pGui

------------------------------------------------------------
-- TOP HUD: ROUND STATUS
------------------------------------------------------------
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(0, 420, 0, 44)
statusFrame.Position = UDim2.new(0.5, -210, 0.02, 0)
statusFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
statusFrame.BackgroundTransparency = 0.2
statusFrame.Parent = gui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = statusFrame

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(0, 200, 255)
statusStroke.Thickness = 1.5
statusStroke.Parent = statusFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 1, 0)
statusLabel.Position = UDim2.new(0, 10, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextScaled = true
statusLabel.Text = "Connecting to Chronos Vault..."
statusLabel.Parent = statusFrame

------------------------------------------------------------
-- LEFT HUD: EGG COUNTER & STATS
------------------------------------------------------------
local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsFrame"
statsFrame.Size = UDim2.new(0, 220, 0, 110)
statsFrame.Position = UDim2.new(0.02, 0, 0.08, 0)
statsFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
statsFrame.BackgroundTransparency = 0.25
statsFrame.Parent = gui

local sfCorner = Instance.new("UICorner")
sfCorner.CornerRadius = UDim.new(0, 12)
sfCorner.Parent = statsFrame

local sfStroke = Instance.new("UIStroke")
sfStroke.Color = Color3.fromRGB(255, 200, 0)
sfStroke.Thickness = 1.5
sfStroke.Parent = statsFrame

-- Egg counter title
local eggCounterLabel = Instance.new("TextLabel")
eggCounterLabel.Name = "EggCounter"
eggCounterLabel.Size = UDim2.new(1, -16, 0, 50)
eggCounterLabel.Position = UDim2.new(0, 10, 0, 6)
eggCounterLabel.BackgroundTransparency = 1
eggCounterLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
eggCounterLabel.Font = Enum.Font.GothamBlack
eggCounterLabel.TextScaled = true
eggCounterLabel.TextXAlignment = Enum.TextXAlignment.Left
eggCounterLabel.Text = "🥚 0 EGGS"
eggCounterLabel.Parent = statsFrame

-- Sub-stat summary
local statSubLabel = Instance.new("TextLabel")
statSubLabel.Name = "SubStats"
statSubLabel.Size = UDim2.new(1, -16, 0, 44)
statSubLabel.Position = UDim2.new(0, 10, 0, 56)
statSubLabel.BackgroundTransparency = 1
statSubLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
statSubLabel.Font = Enum.Font.GothamMedium
statSubLabel.TextScaled = true
statSubLabel.TextXAlignment = Enum.TextXAlignment.Left
statSubLabel.Text = "⚡ Spd: 16 | 💎 Mult: 1x\n🦘 Jump: 50"
statSubLabel.Parent = statsFrame

------------------------------------------------------------
-- HUD QUICK SHOP BUTTON
------------------------------------------------------------
local shopToggleBtn = Instance.new("TextButton")
shopToggleBtn.Name = "ShopToggleBtn"
shopToggleBtn.Size = UDim2.new(0, 140, 0, 44)
shopToggleBtn.Position = UDim2.new(0.02, 0, 0.23, 0)
shopToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
shopToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shopToggleBtn.Font = Enum.Font.GothamBold
shopToggleBtn.TextScaled = true
shopToggleBtn.Text = "🛒 OPEN SHOP"
shopToggleBtn.Parent = gui

local stbCorner = Instance.new("UICorner")
stbCorner.CornerRadius = UDim.new(0, 10)
stbCorner.Parent = shopToggleBtn

------------------------------------------------------------
-- INTERACTIVE SHOP MODAL
------------------------------------------------------------
local modal = Instance.new("Frame")
modal.Name = "ShopModal"
modal.Size = UDim2.new(0, 520, 0, 420)
modal.Position = UDim2.new(0.5, -260, 0.5, -210)
modal.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
modal.BackgroundTransparency = 0.05
modal.Visible = false
modal.Parent = gui

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 16)
modalCorner.Parent = modal

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(0, 200, 255)
modalStroke.Thickness = 2
modalStroke.Parent = modal

-- Title Bar
local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, -60, 0, 45)
titleBar.Position = UDim2.new(0, 20, 0, 10)
titleBar.BackgroundTransparency = 1
titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
titleBar.Font = Enum.Font.GothamBlack
titleBar.TextScaled = true
titleBar.TextXAlignment = Enum.TextXAlignment.Left
titleBar.Text = "🏛️ CHRONOS UPGRADE LAB"
titleBar.Parent = modal

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -48, 0, 14)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.Text = "✕"
closeBtn.Parent = modal

local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 8)
cbCorner.Parent = closeBtn

-- Tab Bar
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -40, 0, 40)
tabContainer.Position = UDim2.new(0, 20, 0, 65)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = modal

local speedTabBtn = Instance.new("TextButton")
speedTabBtn.Size = UDim2.new(0.48, 0, 1, 0)
speedTabBtn.Position = UDim2.new(0, 0, 0, 0)
speedTabBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
speedTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
speedTabBtn.Font = Enum.Font.GothamBold
speedTabBtn.TextScaled = true
speedTabBtn.Text = "⚡ SPEED LAB"
speedTabBtn.Parent = tabContainer

local stbCorner1 = Instance.new("UICorner")
stbCorner1.CornerRadius = UDim.new(0, 8)
stbCorner1.Parent = speedTabBtn

local perksTabBtn = Instance.new("TextButton")
perksTabBtn.Size = UDim2.new(0.48, 0, 1, 0)
perksTabBtn.Position = UDim2.new(0.52, 0, 0, 0)
perksTabBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 60)
perksTabBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
perksTabBtn.Font = Enum.Font.GothamBold
perksTabBtn.TextScaled = true
perksTabBtn.Text = "💎 VAULT PERKS"
perksTabBtn.Parent = tabContainer

local ptbCorner = Instance.new("UICorner")
ptbCorner.CornerRadius = UDim.new(0, 8)
ptbCorner.Parent = perksTabBtn

-- Items Scroll Container
local scrollList = Instance.new("ScrollingFrame")
scrollList.Size = UDim2.new(1, -40, 0, 290)
scrollList.Position = UDim2.new(0, 20, 0, 115)
scrollList.BackgroundTransparency = 1
scrollList.ScrollBarThickness = 6
scrollList.Parent = modal

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 12)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollList

------------------------------------------------------------
-- POPULATE UPGRADE CARDS
------------------------------------------------------------
local function createUpgradeCard(upKey, upDef)
	local card = Instance.new("Frame")
	card.Name = "Card_" .. upKey
	card.Size = UDim2.new(1, -8, 0, 80)
	card.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
	card.Parent = scrollList

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 10)
	cCorner.Parent = card

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(45, 52, 75)
	cStroke.Parent = card

	-- Icon & Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.55, 0, 0, 28)
	title.Position = UDim2.new(0, 12, 0, 8)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = upDef.Icon .. " " .. upDef.DisplayName
	title.Parent = card

	-- Description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(0.55, 0, 0, 20)
	desc.Position = UDim2.new(0, 12, 0, 36)
	desc.BackgroundTransparency = 1
	desc.TextColor3 = Color3.fromRGB(150, 165, 195)
	desc.Font = Enum.Font.Gotham
	desc.TextScaled = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Text = upDef.Description
	desc.Parent = card

	-- Level tag
	local lvlKey = upKey .. "Level"
	local curLvl = stats[lvlKey] or 0

	local lvlTag = Instance.new("TextLabel")
	lvlTag.Size = UDim2.new(0.55, 0, 0, 16)
	lvlTag.Position = UDim2.new(0, 12, 0, 56)
	lvlTag.BackgroundTransparency = 1
	lvlTag.TextColor3 = Color3.fromRGB(0, 220, 255)
	lvlTag.Font = Enum.Font.GothamBold
	lvlTag.TextSize = 13
	lvlTag.TextXAlignment = Enum.TextXAlignment.Left
	lvlTag.Text = "Level " .. curLvl .. " / " .. upDef.MaxLevel
	lvlTag.Parent = card

	-- Buy Button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyBtn"
	buyBtn.Size = UDim2.new(0.38, 0, 0, 48)
	buyBtn.Position = UDim2.new(0.6, 0, 0.5, -24)
	buyBtn.Font = Enum.Font.GothamBlack
	buyBtn.TextScaled = true
	buyBtn.Parent = card

	local bbCorner = Instance.new("UICorner")
	bbCorner.CornerRadius = UDim.new(0, 8)
	bbCorner.Parent = buyBtn

	-- Update button state
	local cost = Config.GetCost(upKey, curLvl)
	if curLvl >= upDef.MaxLevel then
		buyBtn.Text = "⭐ MAXED"
		buyBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 90)
		buyBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
	elseif stats.Eggs < cost then
		buyBtn.Text = "🥚 " .. cost .. " Eggs"
		buyBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
		buyBtn.TextColor3 = Color3.fromRGB(220, 140, 150)
	else
		buyBtn.Text = "BUY (" .. cost .. " 🥚)"
		buyBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 120)
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	-- Click event
	local debounce = false
	buyBtn.MouseButton1Click:Connect(function()
		if debounce then return end
		if curLvl >= upDef.MaxLevel or stats.Eggs < cost then return end
		debounce = true

		BuyUpgradeEvent:FireServer(upKey)

		-- Button click animation
		buyBtn.BackgroundColor3 = Color3.fromRGB(0, 240, 160)
		task.wait(0.25)
		debounce = false
	end)

	return card
end

local function refreshShopList()
	for _, child in ipairs(scrollList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if activeTab == "Speed" then
		createUpgradeCard("Speed", Config.UPGRADES.Speed)
	else
		createUpgradeCard("Multiplier", Config.UPGRADES.Multiplier)
		createUpgradeCard("Jump", Config.UPGRADES.Jump)
		createUpgradeCard("Magnet", Config.UPGRADES.Magnet)
	end
end

local function updateTabButtons()
	if activeTab == "Speed" then
		speedTabBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		speedTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		perksTabBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 60)
		perksTabBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
	else
		speedTabBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 60)
		speedTabBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
		perksTabBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
		perksTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	refreshShopList()
end

speedTabBtn.MouseButton1Click:Connect(function()
	activeTab = "Speed"
	updateTabButtons()
end)

perksTabBtn.MouseButton1Click:Connect(function()
	activeTab = "Perks"
	updateTabButtons()
end)

------------------------------------------------------------
-- OPEN / CLOSE SHOP LOGIC
------------------------------------------------------------
local function openShop(tabName)
	if tabName and (tabName == "Speed" or tabName == "Perks") then
		activeTab = tabName
	end
	updateTabButtons()
	modal.Visible = true

	-- Smooth zoom in
	modal.Size = UDim2.new(0, 480, 0, 390)
	modal.Position = UDim2.new(0.5, -240, 0.5, -195)
	local tw = TweenService:Create(modal, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 520, 0, 420),
		Position = UDim2.new(0.5, -260, 0.5, -210),
	})
	tw:Play()
end

local function closeShop()
	modal.Visible = false
end

closeBtn.MouseButton1Click:Connect(closeShop)
shopToggleBtn.MouseButton1Click:Connect(function()
	if modal.Visible then
		closeShop()
	else
		openShop("Speed")
	end
end)

-- Remote event triggered by Physical Shop ProximityPrompt or TouchPad in the map
OpenShopEvent.OnClientEvent:Connect(function(tabName)
	openShop(tabName)
end)

------------------------------------------------------------
-- DATA SYNC & DISPLAY UPDATES
------------------------------------------------------------
local function updateHUD()
	eggCounterLabel.Text = "🥚 " .. stats.Eggs .. " EGGS"

	local spdVal = Config.UPGRADES.Speed.BaseValue + (stats.SpeedLevel * Config.UPGRADES.Speed.Increment)
	local multVal = 1 + (stats.MultiplierLevel * Config.UPGRADES.Multiplier.Increment)
	local jumpVal = Config.UPGRADES.Jump.BaseValue + (stats.JumpLevel * Config.UPGRADES.Jump.Increment)

	statSubLabel.Text = string.format("⚡ Spd: %d | 💎 Mult: %dx\n🦘 Jump: %d", spdVal, multVal, jumpVal)

	if modal.Visible then
		refreshShopList()
	end
end

SyncDataEvent.OnClientEvent:Connect(function(newData)
	for k, v in pairs(newData) do
		stats[k] = v
	end
	updateHUD()
end)

StatusEvent.OnClientEvent:Connect(function(msg)
	statusLabel.Text = msg
end)

updateHUD()
print("[ChronosVault] ShopClient with physical & HUD shop triggers loaded ✓")
