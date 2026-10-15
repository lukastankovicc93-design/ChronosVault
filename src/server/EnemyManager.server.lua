--[[
    EnemyManager.server.lua (ServerScriptService)
    Chronos Sentinel AI System:
    - Spawns & animates 3 Cyber Sentinels (Titan Guardian, Alpha, Beta)
    - Dynamic Ocular Laser Light (Cyan when patrolling, Crimson Red when chasing)
    - Pathfinding & proximity chase with speed scaling
    - Attack Tackle & SCATTER MECHANIC: Knocks back player and scatters their carried eggs!
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Bindable Event to tell GameManager to scatter player's eggs
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
-- SENTINEL MODEL CONSTRUCTOR
------------------------------------------------------------
local function createSentinel(enemyKey, def)
	local model = Instance.new("Model")
	model.Name = "Sentinel_" .. enemyKey
	model.Parent = enemyFolder

	-- Core Chassis
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = def.Size
	root.Position = def.SpawnPos + Vector3.new(0, 4, 0)
	root.Color = Color3.fromRGB(25, 20, 35)
	root.Material = Enum.Material.Metal
	root.CanCollide = true
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.Parent = model
	model.PrimaryPart = root

	-- Humanoid for movement
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.MaxHealth = 999999
	hum.Health = 999999
	hum.WalkSpeed = def.WalkSpeed
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	-- Glowing Cyber Head / Core
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(def.Size.X * 0.7, def.Size.Y * 0.4, def.Size.Z * 0.7)
	head.Position = root.Position + Vector3.new(0, def.Size.Y * 0.5, 0)
	head.Color = def.Color
	head.Material = Enum.Material.Neon
	head.CanCollide = false
	head.Parent = model

	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = root
	headWeld.Part1 = head
	headWeld.Parent = head

	-- Rotating Cyber Energy Ring
	local ring = Instance.new("Part")
	ring.Name = "EnergyRing"
	ring.Size = Vector3.new(def.Size.X * 1.3, 0.4, def.Size.Z * 1.3)
	ring.Position = root.Position
	ring.Color = def.Color
	ring.Material = Enum.Material.Neon
	ring.CanCollide = false
	ring.Parent = model

	local ringWeld = Instance.new("WeldConstraint")
	ringWeld.Part0 = root
	ringWeld.Part1 = ring
	ringWeld.Parent = ring

	-- Ocular Scanning Searchlight (Cyan -> Red)
	local eye = Instance.new("SpotLight")
	eye.Name = "OcularEye"
	eye.Color = Color3.fromRGB(0, 240, 255)
	eye.Brightness = 5
	eye.Range = def.SightRange
	eye.Angle = 70
	eye.Face = Enum.NormalId.Front
	eye.Parent = head

	-- Plasma Thruster Particle Emitter
	local thruster = Instance.new("ParticleEmitter")
	thruster.Color = ColorSequence.new(def.Color, Color3.fromRGB(255, 50, 0))
	thruster.Size = NumberSequence.new(1.0, 0.1)
	thruster.Lifetime = NumberRange.new(0.4, 0.8)
	thruster.Rate = 20
	thruster.Speed = NumberRange.new(4, 8)
	thruster.SpreadAngle = Vector2.new(15, 15)
	thruster.Parent = root

	-- Holographic Status Billboard
	local bg = Instance.new("BillboardGui")
	bg.Name = "StatusHolo"
	bg.Size = UDim2.new(0, 220, 0, 50)
	bg.StudsOffset = Vector3.new(0, def.Size.Y + 2, 0)
	bg.AlwaysOnTop = true
	bg.Adornee = head
	bg.Parent = head

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, 0, 0.6, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextColor3 = def.Color
	titleLbl.Font = Enum.Font.GothamBlack
	titleLbl.TextScaled = true
	titleLbl.Text = def.Name
	titleLbl.Parent = bg

	local stateLbl = Instance.new("TextLabel")
	stateLbl.Name = "StateLabel"
	stateLbl.Size = UDim2.new(1, 0, 0.4, 0)
	stateLbl.Position = UDim2.new(0, 0, 0.6, 0)
	stateLbl.BackgroundTransparency = 1
	stateLbl.TextColor3 = Color3.fromRGB(0, 220, 255)
	stateLbl.Font = Enum.Font.GothamBold
	stateLbl.TextScaled = true
	stateLbl.Text = "🛡️ PATROLLING"
	stateLbl.Parent = bg

	return model, def
end

------------------------------------------------------------
-- AI BRAIN CONTROLLER
------------------------------------------------------------
local function runSentinelBrain(model, def)
	local root = model:WaitForChild("HumanoidRootPart")
	local hum = model:WaitForChild("Humanoid")
	local eye = model.Head:WaitForChild("OcularEye")
	local stateLbl = model.Head.StatusHolo.StateLabel

	local spawnPos = def.SpawnPos
	local lastAttack = 0
	local isChasing = false

	-- Patrol Waypoint Generator
	local function getPatrolPoint()
		local angle = math.random() * math.pi * 2
		local dist = math.random(5, def.PatrolRadius)
		return spawnPos + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
	end

	-- Find Nearest Target Player in Sight
	local function findTarget()
		local nearest = nil
		local closestDist = def.SightRange

		for _, p in ipairs(Players:GetPlayers()) do
			local char = p.Character
			local pHrp = char and char:FindFirstChild("HumanoidRootPart")
			local pHum = char and char:FindFirstChild("Humanoid")
			if pHrp and pHum and pHum.Health > 0 then
				-- Safe zone check (Lobby is safe!)
				if pHrp.Position.Z < -70 then
					-- Player is in Safe Zone / Lobby — Sentinels cannot enter!
				else
					local dist = (root.Position - pHrp.Position).Magnitude
					if dist < closestDist then
						closestDist = dist
						nearest = p
					end
				end
			end
		end
		return nearest, closestDist
	end

	-- Main Loop
	task.spawn(function()
		local currentPatrolTarget = getPatrolPoint()
		local patrolTimer = tick()

		while model and model.Parent do
			local targetPlayer, dist = findTarget()

			if targetPlayer and targetPlayer.Character then
				local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				if targetHrp then
					-- AGGRESSION STATE (Red Eye, Alarm)
					if not isChasing then
						isChasing = true
						eye.Color = Color3.fromRGB(255, 30, 60)
						stateLbl.Text = "🚨 PURSUING INTRUDER!"
						stateLbl.TextColor3 = Color3.fromRGB(255, 40, 60)
					end

					-- Move toward player
					hum:MoveTo(targetHrp.Position)

					-- Attack / Tackle & Scatter
					if dist <= def.AttackRange and (tick() - lastAttack > def.AttackCooldown) then
						lastAttack = tick()

						-- Knockback
						local dir = (targetHrp.Position - root.Position).Unit
						targetHrp.AssemblyLinearVelocity = Vector3.new(dir.X * def.KnockbackPower, 35, dir.Z * def.KnockbackPower)

						-- Trigger Egg Scatter via BindableEvent
						ScatterEvent:Fire(targetPlayer, def.EggScatterCount, targetHrp.Position)

						-- Visual attack burst
						local origCol = eye.Color
						eye.Color = Color3.fromRGB(255, 255, 255)
						task.wait(0.2)
						eye.Color = origCol
					end
				end
			else
				-- PATROL STATE (Cyan Eye, Smooth wandering)
				if isChasing then
					isChasing = false
					eye.Color = Color3.fromRGB(0, 240, 255)
					stateLbl.Text = "🛡️ PATROLLING"
					stateLbl.TextColor3 = Color3.fromRGB(0, 220, 255)
				end

				if tick() - patrolTimer > 5 or (root.Position - currentPatrolTarget).Magnitude < 6 then
					currentPatrolTarget = getPatrolPoint()
					patrolTimer = tick()
					hum:MoveTo(currentPatrolTarget)
				end
			end

			task.wait(0.25)
		end
	end)
end

------------------------------------------------------------
-- INITIALIZE SENTINELS
------------------------------------------------------------
task.spawn(function()
	task.wait(2) -- Wait for map to construct
	for key, def in pairs(Config.ENEMIES) do
		local m, d = createSentinel(key, def)
		runSentinelBrain(m, d)
	end
	print("[ChronosVault] Chronos Sentinels Deployed & Patrolling Vault ✓")
end)
