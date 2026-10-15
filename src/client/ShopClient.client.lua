--[[
    ShopClient.client.lua (StarterPlayerScripts)
    Chronos Vault: Complete Client UI & Progression Interface
    - Backpack capacity gauge with real-time visual progress
    - Rebirth Altar Modal & Quick HUD Rebirth Trigger
    - Plot Hatchery integration with celebratory crack & burst animations
    - 3D Floating Reward Texts (+X Eggs, Rebirth Fanfare, Guardian Attack alerts)
    - Full Cyberpunk Shop UI with tabs
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Remotes
local BuyUpgradeEvent     = ReplicatedStorage:WaitForChild("BuyUpgrade")
local SyncDataEvent       = ReplicatedStorage:WaitForChild("SyncData")
local StatusEvent         = ReplicatedStorage:WaitForChild("RoundStatus")
local OpenShopEvent       = ReplicatedStorage:WaitForChild("OpenShop")
local OpenRebirthEvent    = ReplicatedStorage:WaitForChild("OpenRebirth")
local PerformRebirthEvent = ReplicatedStorage:WaitForChild("PerformRebirth")
local EggEffectEvent      = ReplicatedStorage:WaitForChild("EggEffect")

------------------------------------------------------------
-- CLIENT STATE
------------------------------------------------------------
local state = {
	Eggs            = 0,
	TotalEggs       = 0,
	Rebirths        = 0,
	HatchedEggs     = 0,
	SpeedLevel      = 0,
	BackpackLevel   = 0,
	MultiplierLevel = 0,
	JumpLevel       = 0,
	CarriedCount    = 0,
	CarriedValue    = 0,
	Capacity        = Config.BASE_CAPACITY,
	RebirthCost     = 100,
	RebirthSpeedReq = 4,
	PlotIndex       = 0,
}

local activeTab = "Speed"

------------------------------------------------------------
-- AUDIO
------------------------------------------------------------
local function playSnd(soundId, pitch)
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = 0.8
	s.PlaybackSpeed = pitch or 1.0
	s.Parent = SoundService
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
end

------------------------------------------------------------
-- FLOATING 3D TEXT
------------------------------------------------------------
local function spawnFloatingText(text, color, worldPos)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Position = worldPos + Vector3.new(0, 1.5, 0)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Parent = workspace

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 240, 0, 52)
	bb.AlwaysOnTop = true
	bb.Adornee = part
	bb.Parent = part

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = color or Color3.fromRGB(255, 215, 0)
	lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lbl.TextStrokeTransparency = 0.1
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.Text = text
	lbl.Parent = bb

	local tw1 = TweenService:Create(bb, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 4.5, 0),
	})
	local tw2 = TweenService:Create(lbl, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tw1:Play()
	tw2:Play()
	tw2.Completed:Connect(function() part:Destroy() end)
end

------------------------------------------------------------
-- GUI CREATION
------------------------------------------------------------
local pGui = player:WaitForChild("PlayerGui")
if pGui:FindFirstChild("ChronosUI") then
	pGui.ChronosUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChronosUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = pGui

------------------------------------------------------------
-- 1. ROUND BANNER
------------------------------------------------------------
local roundBanner = Instance.new("Frame")
roundBanner.Name = "RoundBanner"
roundBanner.Size = UDim2.new(0, 480, 0, 42)
roundBanner.Position = UDim2.new(0.5, -240, 0.015, 0)
roundBanner.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
roundBanner.BackgroundTransparency = 0.2
roundBanner.Parent = screenGui

local rbCorner = Instance.new("UICorner")
rbCorner.CornerRadius = UDim.new(0, 10)
rbCorner.Parent = roundBanner

local rbStroke = Instance.new("UIStroke")
rbStroke.Color = Color3.fromRGB(0, 210, 255)
rbStroke.Thickness = 1.5
rbStroke.Parent = roundBanner

local roundLabel = Instance.new("TextLabel")
roundLabel.Size = UDim2.new(1, -20, 1, 0)
roundLabel.Position = UDim2.new(0, 10, 0, 0)
roundLabel.BackgroundTransparency = 1
roundLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roundLabel.Font = Enum.Font.GothamBold
roundLabel.TextScaled = true
roundLabel.Text = "Welcome to Chronos Vault!"
roundLabel.Parent = roundBanner

------------------------------------------------------------
-- 2. HUD: BANKED EGGS + BACKPACK GAUGE + PLOT INFO
------------------------------------------------------------
local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUDFrame"
hudFrame.Size = UDim2.new(0, 250, 0, 185)
hudFrame.Position = UDim2.new(0.02, 0, 0.08, 0)
hudFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
hudFrame.BackgroundTransparency = 0.2
hudFrame.Parent = screenGui

local hfCorner = Instance.new("UICorner")
hfCorner.CornerRadius = UDim.new(0, 14)
hfCorner.Parent = hudFrame

local hfStroke = Instance.new("UIStroke")
hfStroke.Color = Color3.fromRGB(255, 200, 0)
hfStroke.Thickness = 1.8
hfStroke.Parent = hudFrame

local bankLabel = Instance.new("TextLabel")
bankLabel.Size = UDim2.new(1, -16, 0, 36)
bankLabel.Position = UDim2.new(0, 10, 0, 6)
bankLabel.BackgroundTransparency = 1
bankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
bankLabel.Font = Enum.Font.GothamBlack
bankLabel.TextScaled = true
bankLabel.TextXAlignment = Enum.TextXAlignment.Left
bankLabel.Text = "💰 0 BANKED"
bankLabel.Parent = hudFrame

local bpHeader = Instance.new("TextLabel")
bpHeader.Size = UDim2.new(1, -16, 0, 20)
bpHeader.Position = UDim2.new(0, 10, 0, 44)
bpHeader.BackgroundTransparency = 1
bpHeader.TextColor3 = Color3.fromRGB(200, 230, 255)
bpHeader.Font = Enum.Font.GothamBold
bpHeader.TextScaled = true
bpHeader.TextXAlignment = Enum.TextXAlignment.Left
bpHeader.Text = "🎒 Backpack: 0 / 3"
bpHeader.Parent = hudFrame

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, -20, 0, 12)
barBg.Position = UDim2.new(0, 10, 0, 68)
barBg.BackgroundColor3 = Color3.fromRGB(30, 35, 52)
barBg.Parent = hudFrame

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(40, 240, 120)
barFill.Parent = barBg

local statsSummary = Instance.new("TextLabel")
statsSummary.Size = UDim2.new(1, -16, 0, 42)
statsSummary.Position = UDim2.new(0, 10, 0, 86)
statsSummary.BackgroundTransparency = 1
statsSummary.TextColor3 = Color3.fromRGB(150, 200, 255)
statsSummary.Font = Enum.Font.GothamMedium
statsSummary.TextScaled = true
statsSummary.TextXAlignment = Enum.TextXAlignment.Left
statsSummary.Text = "⚡ Spd: 18 | 🌀 Rebirth: 0\n💎 Mult: 1x"
statsSummary.Parent = hudFrame

local plotBadge = Instance.new("TextLabel")
plotBadge.Size = UDim2.new(1, -16, 0, 22)
plotBadge.Position = UDim2.new(0, 10, 0, 132)
plotBadge.BackgroundColor3 = Color3.fromRGB(25, 32, 50)
plotBadge.TextColor3 = Color3.fromRGB(0, 255, 180)
plotBadge.Font = Enum.Font.GothamBold
plotBadge.TextScaled = true
plotBadge.Text = "🏡 Hatchery: Plot #1"
plotBadge.Parent = hudFrame
local pbC = Instance.new("UICorner")
pbC.CornerRadius = UDim.new(0, 6)
pbC.Parent = plotBadge

------------------------------------------------------------
-- BUTTON CONTROLS (Shop & Rebirth)
------------------------------------------------------------
local quickShopBtn = Instance.new("TextButton")
quickShopBtn.Size = UDim2.new(0, 140, 0, 42)
quickShopBtn.Position = UDim2.new(0.02, 0, 0.33, 0)
quickShopBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
quickShopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
quickShopBtn.Font = Enum.Font.GothamBlack
quickShopBtn.TextScaled = true
quickShopBtn.Text = "🛒 UPGRADES"
quickShopBtn.Parent = screenGui
local qbC = Instance.new("UICorner")
qbC.CornerRadius = UDim.new(0, 8)
qbC.Parent = quickShopBtn

local quickRebirthBtn = Instance.new("TextButton")
quickRebirthBtn.Size = UDim2.new(0, 140, 0, 42)
quickRebirthBtn.Position = UDim2.new(0.02, 0, 0.40, 0)
quickRebirthBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 180)
quickRebirthBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
quickRebirthBtn.Font = Enum.Font.GothamBlack
quickRebirthBtn.TextScaled = true
quickRebirthBtn.Text = "🌀 REBIRTH"
quickRebirthBtn.Parent = screenGui
local rbC2 = Instance.new("UICorner")
rbC2.CornerRadius = UDim.new(0, 8)
rbC2.Parent = quickRebirthBtn

------------------------------------------------------------
-- 3. THE REBIRTH ALTAR MODAL
------------------------------------------------------------
local rebirthModal = Instance.new("Frame")
rebirthModal.Name = "RebirthModal"
rebirthModal.Size = UDim2.new(0, 480, 0, 360)
rebirthModal.Position = UDim2.new(0.5, -240, 0.5, -180)
rebirthModal.BackgroundColor3 = Color3.fromRGB(22, 16, 36)
rebirthModal.BackgroundTransparency = 0.05
rebirthModal.Visible = false
rebirthModal.Parent = screenGui

local rmCorner = Instance.new("UICorner")
rmCorner.CornerRadius = UDim.new(0, 16)
rmCorner.Parent = rebirthModal

local rmStroke = Instance.new("UIStroke")
rmStroke.Color = Color3.fromRGB(255, 60, 200)
rmStroke.Thickness = 2.4
rmStroke.Parent = rebirthModal

local rmTitle = Instance.new("TextLabel")
rmTitle.Size = UDim2.new(1, -60, 0, 40)
rmTitle.Position = UDim2.new(0, 20, 0, 14)
rmTitle.BackgroundTransparency = 1
rmTitle.TextColor3 = Color3.fromRGB(255, 80, 220)
rmTitle.Font = Enum.Font.GothamBlack
rmTitle.TextScaled = true
rmTitle.TextXAlignment = Enum.TextXAlignment.Left
rmTitle.Text = "🌀 COSMIC REBIRTH ALTAR"
rmTitle.Parent = rebirthModal

local rmClose = Instance.new("TextButton")
rmClose.Size = UDim2.new(0, 34, 0, 34)
rmClose.Position = UDim2.new(1, -44, 0, 16)
rmClose.BackgroundColor3 = Color3.fromRGB(220, 45, 65)
rmClose.TextColor3 = Color3.fromRGB(255, 255, 255)
rmClose.Font = Enum.Font.GothamBold
rmClose.TextSize = 18
rmClose.Text = "✕"
rmClose.Parent = rebirthModal
local rmcC = Instance.new("UICorner")
rmcC.CornerRadius = UDim.new(0, 8)
rmcC.Parent = rmClose

local rmDesc = Instance.new("TextLabel")
rmDesc.Size = UDim2.new(1, -40, 0, 60)
rmDesc.Position = UDim2.new(0, 20, 0, 65)
rmDesc.BackgroundTransparency = 1
rmDesc.TextColor3 = Color3.fromRGB(200, 190, 220)
rmDesc.Font = Enum.Font.GothamMedium
rmDesc.TextScaled = true
rmDesc.Text = "Ascend your mortal form! Resets your current Eggs and Speed, but grants a PERMANENT +150% EGG MULTIPLIER on all future deposits!"
rmDesc.Parent = rebirthModal

local rmStatsBox = Instance.new("Frame")
rmStatsBox.Size = UDim2.new(1, -40, 0, 100)
rmStatsBox.Position = UDim2.new(0, 20, 0, 140)
rmStatsBox.BackgroundColor3 = Color3.fromRGB(30, 22, 48)
rmStatsBox.Parent = rebirthModal
local sbC = Instance.new("UICorner")
sbC.CornerRadius = UDim.new(0, 10)
sbC.Parent = rmStatsBox

local rmReqLabel = Instance.new("TextLabel")
rmReqLabel.Size = UDim2.new(1, -20, 1, 0)
rmReqLabel.Position = UDim2.new(0, 10, 0, 0)
rmReqLabel.BackgroundTransparency = 1
rmReqLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
rmReqLabel.Font = Enum.Font.GothamBold
rmReqLabel.TextScaled = true
rmReqLabel.Text = "Cost: 100 Eggs | Required: Speed Level 4\nCurrent: 0 Eggs | Speed Level 0"
rmReqLabel.Parent = rmStatsBox

local rmAscendBtn = Instance.new("TextButton")
rmAscendBtn.Size = UDim2.new(1, -40, 0, 52)
rmAscendBtn.Position = UDim2.new(0, 20, 0, 260)
rmAscendBtn.BackgroundColor3 = Color3.fromRGB(255, 40, 180)
rmAscendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rmAscendBtn.Font = Enum.Font.GothamBlack
rmAscendBtn.TextScaled = true
rmAscendBtn.Text = "✨ ASCEND & REBIRTH"
rmAscendBtn.Parent = rebirthModal
local abC = Instance.new("UICorner")
abC.CornerRadius = UDim.new(0, 10)
abC.Parent = rmAscendBtn

------------------------------------------------------------
-- 4. SHOP MODAL
------------------------------------------------------------
local modal = Instance.new("Frame")
modal.Name = "ShopModal"
modal.Size = UDim2.new(0, 540, 0, 440)
modal.Position = UDim2.new(0.5, -270, 0.5, -220)
modal.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
modal.BackgroundTransparency = 0.05
modal.Visible = false
modal.Parent = screenGui

local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0, 16)
mCorner.Parent = modal

local mStroke = Instance.new("UIStroke")
mStroke.Color = Color3.fromRGB(0, 220, 255)
mStroke.Thickness = 2.2
mStroke.Parent = modal

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 0, 44)
title.Position = UDim2.new(0, 20, 0, 12)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "🏛️ CHRONOS UPGRADE LAB"
title.Parent = modal

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -48, 0, 16)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 45, 65)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.Text = "✕"
closeBtn.Parent = modal
local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 8)
cbCorner.Parent = closeBtn

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -40, 0, 42)
tabContainer.Position = UDim2.new(0, 20, 0, 68)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = modal

local speedTab = Instance.new("TextButton")
speedTab.Size = UDim2.new(0.48, 0, 1, 0)
speedTab.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
speedTab.TextColor3 = Color3.fromRGB(255, 255, 255)
speedTab.Font = Enum.Font.GothamBold
speedTab.TextScaled = true
speedTab.Text = "⚡ SPEED LAB"
speedTab.Parent = tabContainer
local stCorner = Instance.new("UICorner")
stCorner.CornerRadius = UDim.new(0, 8)
stCorner.Parent = speedTab

local perksTab = Instance.new("TextButton")
perksTab.Size = UDim2.new(0.48, 0, 1, 0)
perksTab.Position = UDim2.new(0.52, 0, 0, 0)
perksTab.BackgroundColor3 = Color3.fromRGB(32, 38, 56)
perksTab.TextColor3 = Color3.fromRGB(180, 190, 210)
perksTab.Font = Enum.Font.GothamBold
perksTab.TextScaled = true
perksTab.Text = "🎒 EQUIPMENT & PERKS"
perksTab.Parent = tabContainer
local ptCorner = Instance.new("UICorner")
ptCorner.CornerRadius = UDim.new(0, 8)
ptCorner.Parent = perksTab

local scrollList = Instance.new("ScrollingFrame")
scrollList.Size = UDim2.new(1, -40, 0, 305)
scrollList.Position = UDim2.new(0, 20, 0, 120)
scrollList.BackgroundTransparency = 1
scrollList.ScrollBarThickness = 6
scrollList.Parent = modal

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 12)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollList

------------------------------------------------------------
-- CARDS
------------------------------------------------------------
local function createCard(upKey, upDef)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 0, 84)
	card.BackgroundColor3 = Color3.fromRGB(24, 28, 44)
	card.Parent = scrollList

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 10)
	cCorner.Parent = card

	local cardTitle = Instance.new("TextLabel")
	cardTitle.Size = UDim2.new(0.55, 0, 0, 26)
	cardTitle.Position = UDim2.new(0, 12, 0, 8)
	cardTitle.BackgroundTransparency = 1
	cardTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	cardTitle.Font = Enum.Font.GothamBold
	cardTitle.TextScaled = true
	cardTitle.TextXAlignment = Enum.TextXAlignment.Left
	cardTitle.Text = upDef.Icon .. " " .. upDef.DisplayName
	cardTitle.Parent = card

	local cardDesc = Instance.new("TextLabel")
	cardDesc.Size = UDim2.new(0.55, 0, 0, 20)
	cardDesc.Position = UDim2.new(0, 12, 0, 34)
	cardDesc.BackgroundTransparency = 1
	cardDesc.TextColor3 = Color3.fromRGB(150, 170, 205)
	cardDesc.Font = Enum.Font.Gotham
	cardDesc.TextScaled = true
	cardDesc.TextXAlignment = Enum.TextXAlignment.Left
	cardDesc.Text = upDef.Description
	cardDesc.Parent = card

	local curLvl = state[upKey .. "Level"] or 0
	local lvlTag = Instance.new("TextLabel")
	lvlTag.Size = UDim2.new(0.55, 0, 0, 18)
	lvlTag.Position = UDim2.new(0, 12, 0, 56)
	lvlTag.BackgroundTransparency = 1
	lvlTag.TextColor3 = Color3.fromRGB(0, 220, 255)
	lvlTag.Font = Enum.Font.GothamBold
	lvlTag.TextSize = 13
	lvlTag.TextXAlignment = Enum.TextXAlignment.Left
	lvlTag.Text = "Level " .. curLvl .. " / " .. upDef.MaxLevel
	lvlTag.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0.38, 0, 0, 50)
	buyBtn.Position = UDim2.new(0.6, 0, 0.5, -25)
	buyBtn.Font = Enum.Font.GothamBlack
	buyBtn.TextScaled = true
	buyBtn.Parent = card
	local bbCorner = Instance.new("UICorner")
	bbCorner.CornerRadius = UDim.new(0, 8)
	bbCorner.Parent = buyBtn

	local cost = Config.GetCost(upKey, curLvl)
	if curLvl >= upDef.MaxLevel then
		buyBtn.Text = "⭐ MAXED"
		buyBtn.BackgroundColor3 = Color3.fromRGB(60, 65, 80)
		buyBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
	elseif state.Eggs < cost then
		buyBtn.Text = "🥚 " .. cost .. " Eggs"
		buyBtn.BackgroundColor3 = Color3.fromRGB(65, 30, 42)
		buyBtn.TextColor3 = Color3.fromRGB(240, 150, 160)
	else
		buyBtn.Text = "BUY (" .. cost .. " 🥚)"
		buyBtn.BackgroundColor3 = Color3.fromRGB(0, 190, 120)
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	buyBtn.MouseButton1Click:Connect(function()
		if curLvl >= upDef.MaxLevel or state.Eggs < cost then return end
		BuyUpgradeEvent:FireServer(upKey)
		buyBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
		task.wait(0.25)
	end)

	return card
end

local function refreshCards()
	for _, child in ipairs(scrollList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	if activeTab == "Speed" then
		createCard("Speed", Config.UPGRADES.Speed)
	else
		createCard("Backpack", Config.UPGRADES.Backpack)
		createCard("Multiplier", Config.UPGRADES.Multiplier)
		createCard("Jump", Config.UPGRADES.Jump)
	end
end

local function setTab(tabName)
	activeTab = tabName
	if tabName == "Speed" then
		speedTab.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
		speedTab.TextColor3 = Color3.fromRGB(255, 255, 255)
		perksTab.BackgroundColor3 = Color3.fromRGB(32, 38, 56)
		perksTab.TextColor3 = Color3.fromRGB(180, 190, 210)
	else
		speedTab.BackgroundColor3 = Color3.fromRGB(32, 38, 56)
		speedTab.TextColor3 = Color3.fromRGB(180, 190, 210)
		perksTab.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
		perksTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	refreshCards()
end

speedTab.MouseButton1Click:Connect(function() setTab("Speed") end)
perksTab.MouseButton1Click:Connect(function() setTab("Perks") end)

local function openShop(tab)
	setTab(tab or "Speed")
	modal.Visible = true
	local tw = TweenService:Create(modal, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 540, 0, 440),
	})
	tw:Play()
end

closeBtn.MouseButton1Click:Connect(function() modal.Visible = false end)
quickShopBtn.MouseButton1Click:Connect(function()
	if modal.Visible then modal.Visible = false else openShop("Speed") end
end)
OpenShopEvent.OnClientEvent:Connect(function(tab) openShop(tab) end)

------------------------------------------------------------
-- REBIRTH MODAL CONTROLLER
------------------------------------------------------------
local function updateRebirthModal()
	local cost = state.RebirthCost or 100
	local reqSpd = state.RebirthSpeedReq or 4
	local curSpd = state.SpeedLevel or 0
	local curEggs = state.Eggs or 0

	rmReqLabel.Text = string.format(
		"Requirements:\n🥚 Eggs: %d / %d  |  ⚡ Speed Level: %d / %d\n\nReward: +150%% Permanent Egg Multiplier!",
		curEggs, cost, curSpd, reqSpd
	)

	if curEggs >= cost and curSpd >= reqSpd then
		rmAscendBtn.Text = "✨ ASCEND & REBIRTH NOW!"
		rmAscendBtn.BackgroundColor3 = Color3.fromRGB(0, 220, 140)
	else
		rmAscendBtn.Text = "🔒 REQUIREMENTS NOT MET"
		rmAscendBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 70)
	end
end

local function openRebirth()
	updateRebirthModal()
	rebirthModal.Visible = true
end

rmClose.MouseButton1Click:Connect(function() rebirthModal.Visible = false end)
quickRebirthBtn.MouseButton1Click:Connect(function()
	if rebirthModal.Visible then rebirthModal.Visible = false else openRebirth() end
end)
OpenRebirthEvent.OnClientEvent:Connect(openRebirth)

rmAscendBtn.MouseButton1Click:Connect(function()
	local cost = state.RebirthCost or 100
	local reqSpd = state.RebirthSpeedReq or 4
	if state.Eggs >= cost and state.SpeedLevel >= reqSpd then
		PerformRebirthEvent:FireServer()
		rebirthModal.Visible = false
	end
end)

------------------------------------------------------------
-- HUD UPDATER
------------------------------------------------------------
local function updateHUD()
	bankLabel.Text = "💰 " .. state.Eggs .. " BANKED"

	bpHeader.Text = string.format("🎒 Backpack: %d / %d", state.CarriedCount, state.Capacity)
	local ratio = math.clamp(state.CarriedCount / math.max(1, state.Capacity), 0, 1)

	TweenService:Create(barFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
		Size = UDim2.new(ratio, 0, 1, 0),
		BackgroundColor3 = (ratio >= 1.0) and Color3.fromRGB(255, 50, 80) or Color3.fromRGB(40, 240, 120),
	}):Play()

	local spd = Config.UPGRADES.Speed.BaseValue + (state.SpeedLevel * Config.UPGRADES.Speed.Increment)
	local mult = (1 + (state.MultiplierLevel * Config.UPGRADES.Multiplier.Increment)) * (1 + ((state.Rebirths or 0) * Config.REBIRTH.MultiplierPerReb))

	statsSummary.Text = string.format("⚡ Spd: %d | 🌀 Rebirth: %d\n💎 Mult: %.1fx | 🐣 Hatched: %d", spd, state.Rebirths or 0, mult, state.HatchedEggs or 0)

	if state.PlotIndex and state.PlotIndex > 0 then
		plotBadge.Text = "🏡 Hatchery: Plot #" .. state.PlotIndex
	else
		plotBadge.Text = "🏡 Searching for Plot..."
	end

	if modal.Visible then refreshCards() end
	if rebirthModal.Visible then updateRebirthModal() end
end

------------------------------------------------------------
-- LISTENERS
------------------------------------------------------------
SyncDataEvent.OnClientEvent:Connect(function(data)
	for k, v in pairs(data) do state[k] = v end
	updateHUD()
end)

StatusEvent.OnClientEvent:Connect(function(msg)
	roundLabel.Text = msg
end)

EggEffectEvent.OnClientEvent:Connect(function(action, arg1, arg2, arg3, arg4)
	if action == "EggCollected" then
		playSnd(Config.SOUNDS.EggPickup, arg3)
		spawnFloatingText("+" .. arg2 .. " 🥚 " .. arg1, Color3.fromRGB(255, 215, 0), arg4)

	elseif action == "DepositSuccess" then
		playSnd(Config.SOUNDS.DepositBank, 1.0)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			spawnFloatingText("💰 +" .. arg1 .. " EGGS BANKED!", Color3.fromRGB(0, 255, 150), hrp.Position)
		end

	elseif action == "BackpackFull" then
		playSnd(Config.SOUNDS.BackpackFull, 1.0)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			spawnFloatingText("⚠️ BACKPACK FULL! GO TO BANK!", Color3.fromRGB(255, 60, 80), hrp.Position)
		end

	elseif action == "AttackedScatter" then
		playSnd(Config.SOUNDS.EnemyAttack, 0.9)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			spawnFloatingText("💥 TACKLED BY GUARDIAN! -" .. arg1 .. " EGGS DROPPED!", Color3.fromRGB(255, 40, 60), hrp.Position)
		end

	elseif action == "RebirthSuccess" then
		playSnd(Config.SOUNDS.RebirthSFX, 1.2)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			spawnFloatingText("🌟 ASCENDED! REBIRTH #" .. arg1 .. " (+150% BOOST)!", Color3.fromRGB(255, 50, 220), hrp.Position)
		end

	elseif action == "EggHatched" then
		playSnd(Config.SOUNDS.HatchBurst, 1.3)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			spawnFloatingText("🐣 EGG HATCHED! +" .. arg1 .. " EGGS!", Color3.fromRGB(255, 220, 0), hrp.Position)
		end

	elseif action == "PlaySound" then
		playSnd(arg1, arg2)
	end
end)

updateHUD()
print("[ChronosVault] Complete UI with Plots & Rebirth Initialized ✓")
