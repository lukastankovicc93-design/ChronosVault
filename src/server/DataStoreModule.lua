--[[
    DataStoreModule (ServerScriptService)
    Handles player data persistence with:
    - pcall wrapping + exponential backoff
    - UpdateAsync for concurrency safety
    - BindToClose for safe shutdown saves
    - Periodic auto-save
]]

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)

local DataStore = DataStoreService:GetDataStore(Config.DATA_STORE_NAME)

local DataModule = {}

-- In-memory cache: [userId] = { Eggs = 0, SpeedLevel = 0, TotalEggs = 0 }
local playerCache = {}

------------------------------------------------------------
-- DEFAULTS
------------------------------------------------------------
local function getDefaultData()
	return {
		Eggs       = 0,
		SpeedLevel = 0,
		TotalEggs  = 0,
	}
end

------------------------------------------------------------
-- SAFE GET WITH RETRIES
------------------------------------------------------------
local function safeGet(key)
	local attempts = 0
	local success, result
	repeat
		attempts += 1
		success, result = pcall(function()
			return DataStore:GetAsync(key)
		end)
		if not success then
			warn("[DataModule] GetAsync failed attempt " .. attempts .. ": " .. tostring(result))
			task.wait(2 ^ attempts)
		end
	until success or attempts >= 4
	return success, result
end

------------------------------------------------------------
-- SAFE SAVE WITH UpdateAsync
------------------------------------------------------------
local function safeSave(key, data)
	local attempts = 0
	local success, err
	repeat
		attempts += 1
		success, err = pcall(function()
			DataStore:UpdateAsync(key, function()
				return data
			end)
		end)
		if not success then
			warn("[DataModule] UpdateAsync failed attempt " .. attempts .. ": " .. tostring(err))
			task.wait(2 ^ attempts)
		end
	until success or attempts >= 4
	return success
end

------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------

function DataModule.Load(player: Player)
	local key = tostring(player.UserId)
	local success, data = safeGet(key)

	if success and data then
		playerCache[player.UserId] = data
	else
		playerCache[player.UserId] = getDefaultData()
	end

	return playerCache[player.UserId]
end

function DataModule.Get(player: Player)
	return playerCache[player.UserId] or getDefaultData()
end

function DataModule.Set(player: Player, data)
	playerCache[player.UserId] = data
end

function DataModule.AddEggs(player: Player, amount: number)
	local d = DataModule.Get(player)
	d.Eggs      = d.Eggs + amount
	d.TotalEggs = d.TotalEggs + amount
	playerCache[player.UserId] = d
end

function DataModule.SpendEggs(player: Player, amount: number): boolean
	local d = DataModule.Get(player)
	if d.Eggs >= amount then
		d.Eggs = d.Eggs - amount
		playerCache[player.UserId] = d
		return true
	end
	return false
end

function DataModule.Save(player: Player)
	local data = playerCache[player.UserId]
	if not data then return end
	local key = tostring(player.UserId)
	safeSave(key, data)
end

function DataModule.RemoveCache(player: Player)
	playerCache[player.UserId] = nil
end

------------------------------------------------------------
-- AUTO-SAVE LOOP
------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(Config.AUTO_SAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				DataModule.Save(player)
			end)
		end
	end
end)

------------------------------------------------------------
-- BIND TO CLOSE (parallel saves on shutdown)
------------------------------------------------------------
game:BindToClose(function()
	if RunService:IsStudio() then
		task.wait(2)
		return
	end

	local threads = {}
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(threads, task.spawn(function()
			DataModule.Save(player)
		end))
	end
	task.wait(10)  -- give saves time to complete
end)

return DataModule
