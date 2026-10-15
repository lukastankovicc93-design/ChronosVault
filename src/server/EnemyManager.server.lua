--[[
    EnemyManager.server.lua (ServerScriptService)
    Chronos Vault: Multi-Zone Guardian AI System
    - Dedicated Monster for EACH of the 4 Zones
    - Zone 1: Stardust Drone (Speed 19)
    - Zone 2: Solar Fiend (Speed 25)
    - Zone 3: Void Reaper (Speed 32)
    - Zone 4: Chronos Titan Prime (Speed 38)
    - Progression Requirement: Players must upgrade speed to outrun higher-tier monsters!
    - Dynamic Ocular Laser Scanning (Cyan -> Aggressive Red) & Egg Scatter Attack
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ScatterEvent = ReplicatedStorage:FindFirstChild("ScatterEggs")
if not ScatterEvent then
	ScatterEvent = Instance.new("BindableEvent")
	ScatterEvent.Name = "ScatterEggs"
	ScatterEvent.Parent = ReplicatedStorage
end

local enemyFolder = workspace:FindFirstChild("ChronosSentinels") or Instance.new("Folder")
enemyFolder.Name = "ChronosSentinels"
enemyFolder.Parent = workspace

------------------------------------------------------------
-- MONSTER GENERATOR
------------------------------------------------------------
local function spawnZoneMonster(zoneKey, zoneDef)
	local mDef = zoneDef.Monster
	local center = zoneDef.Center

	local model = Instance.new("Model")
	model.Name = "Guardian_" .. zoneKey
	model.Parent = enemyFolder

	-- Root Part
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = mDef.Size
	root.Position = center + Vector3.new(0, mDef.Size.Y/2 + 2, 0)
	root.Color = Color3.fromRGB(24, 18, 32)
	root.Material = Enum.Material.Metal
	root.CanCollide = true
	root.Parent = model
	model.PrimaryPart = root

	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.MaxHealth = 999999
	hum.Health = 999999
	hum.WalkSpeed = mDef.Speed
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	-- Glowing Core / Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(mDef.Size.X * 0.75, mDef.Size.Y * 0.45, mDef.Size.Z * 0.75)
	head.Position = root.Position + Vector3.new(0, mDef.Size.Y * 0.55, 0)
	head.Color = mDef.Color
	head.Material = Enum.Material.Neon
	head.CanCollide = false
	head.Parent = model

	local wHead = Instance.new("WeldConstraint")
	wHead.Part0 = root
	wHead.Part1 = head
	wHead.Parent = head

	-- Rotating Energy Ring
	local ring = Instance.new("Part")
	ring.Name = "EnergyRing"
	ring.Size = Vector3.new(mDef.Size.X * 1.4, 0.4, mDef.Size.Z * 1.4)
	ring.Position = root.Position
	ring.Color = mDef.Color
	ring.Material = Enum.Material.Neon
	ring.CanCollide = false
	ring.Parent = model

	local wRing = Instance.new("WeldConstraint")
	wRing.Part0 = root
	wRing.Part1 = ring
	wRing.Parent = ring

	-- Ocular Laser Searchlight
	local eye = Instance.new("SpotLight")
	eye.Name = "OcularEye"
	eye.Color = zoneDef.Color
	eye.Brightness = 6
	eye.Range = mDef.SightRange
	eye.Angle = 75
	eye.Face = Enum.NormalId.Front
	eye.Parent = head

	-- Thruster Emitter
	local thruster = Instance.new("ParticleEmitter")
	thruster.Color = ColorSequence.new(mDef.Color, Color3.fromRGB(255, 50, 0))
	thruster.Size = NumberSequence.new(1.2, 0.1)
	thruster.Lifetime = NumberRange.new(0.4, 0.8)
	thruster.Rate = 22
	thruster.Speed = NumberRange.new(4, 9)
	thruster.Parent = root

	-- Holographic Status Tag
	local bg = Instance.new("BillboardGui")
	bg.Name = "StatusHolo"
	bg.Size = UDim2.new(0, 240, 0, 54)
	bg.StudsOffset = Vector3.new(0, mDef.Size.Y + 2.5, 0)
	bg.AlwaysOnTop = true
	bg.Adornee = head
	bg.Parent = head

	local tLbl = Instance.new("TextLabel")
	tLbl.Size = UDim2.new(1, 0, 0.6, 0)
	tLbl.BackgroundTransparency = 1
	tLbl.TextColor3 = mDef.Color
	tLbl.Font = Enum.Font.GothamBlack
	tLbl.TextScaled = true
	tLbl.Text = mDef.Name .. " [Spd: " .. mDef.Speed .. "]"
	tLbl.Parent = bg

	local sLbl = Instance.new("TextLabel")
	sLbl.Name = "StateLabel"
	sLbl.Size = UDim2.new(1, 0, 0.4, 0)
	sLbl.Position = UDim2.new(0, 0, 0.6, 0)
	sLbl.BackgroundTransparency = 1
	sLbl.TextColor3 = Color3.fromRGB(0, 220, 255)
	sLbl.Font = Enum.Font.GothamBold
	sLbl.TextScaled = true
	sLbl.Text = "🛡️ PATROLLING ZONE"
	sLbl.Parent = bg

	------------------------------------------------------------
	-- AI BRAIN
	------------------------------------------------------------
	task.spawn(function()
		local lastAttack = 0
		local isChasing = false
		local patrolTimer = tick()

		local function getRandomZonePatrol()
			local halfX = zoneDef.Size.X / 2 - 8
			local halfZ = zoneDef.Size.Z / 2 - 8
			return center + Vector3.new(
				math.random(-halfX, halfX),
				0,
				math.random(-halfZ, halfZ)
			)
		end

		local currentPatrolTarget = getRandomZonePatrol()

		while model and model.Parent do
			-- Find nearest player inside or near this zone
			local targetPlayer = nil
			local closestDist = mDef.SightRange

			for _, p in ipairs(Players:GetPlayers()) do
				local char = p.Character
				local pHrp = char and char:FindFirstChild("HumanoidRootPart")
				local pHum = char and char:FindFirstChild("Humanoid")
				if pHrp and pHum and pHum.Health > 0 then
					-- Cannot attack inside Safe Zone
					if pHrp.Position.Z > -70 then
						local dist = (root.Position - pHrp.Position).Magnitude
						if dist < closestDist then
							closestDist = dist
							targetPlayer = p
						end
					end
				end
			end

			if targetPlayer and targetPlayer.Character then
				local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				if targetHrp then
					if not isChasing then
						isChasing = true
						eye.Color = Color3.fromRGB(255, 30, 60)
						sLbl.Text = "🚨 INTRUDER DETECTED!"
						sLbl.TextColor3 = Color3.fromRGB(255, 40, 60)
					end

					hum:MoveTo(targetHrp.Position)

					-- Attack & Scatter
					if closestDist <= mDef.AttackRange and (tick() - lastAttack > 2.0) then
						lastAttack = tick()
						local dir = (targetHrp.Position - root.Position).Unit
						targetHrp.AssemblyLinearVelocity = Vector3.new(dir.X * 55, 35, dir.Z * 55)

						ScatterEvent:Fire(targetPlayer, mDef.ScatterCount, targetHrp.Position)

						local oldC = eye.Color
						eye.Color = Color3.fromRGB(255, 255, 255)
						task.wait(0.2)
						eye.Color = oldC
					end
				end
			else
				if isChasing then
					isChasing = false
					eye.Color = zoneDef.Color
					sLbl.Text = "🛡️ PATROLLING ZONE"
					sLbl.TextColor3 = Color3.fromRGB(0, 220, 255)
				end

				if tick() - patrolTimer > 6 or (root.Position - currentPatrolTarget).Magnitude < 8 then
					currentPatrolTarget = getRandomZonePatrol()
					patrolTimer = tick()
					hum:MoveTo(currentPatrolTarget)
				end
			end

			task.wait(0.25)
		end
	end)
end

------------------------------------------------------------
-- INITIALIZE ALL 4 ZONE GUARDIANS
------------------------------------------------------------
task.spawn(function()
	task.wait(2.5)
	for zKey, zDef in pairs(Config.ZONES) do
		spawnZoneMonster(zKey, zDef)
	end
	print("[ChronosVault] 4 Tiered Zone Guardians Deployed Across Map ✓")
end)
