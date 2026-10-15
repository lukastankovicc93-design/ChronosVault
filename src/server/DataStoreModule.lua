--[[
    DataStoreModule.lua (ServerScriptService)
    Persistence Engine for Chronos Vault:
    - Stores Eggs, TotalEggs, Rebirths, HatchedEggs, SpeedLevel, BackpackLevel, MultiplierLevel, JumpLevel
    - Rebirth transaction logic with requirement validation & stat resets
    - Concurrency safety with UpdateAsync, retries, and BindToClose
]]

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)

local DataStore = DataStoreService:GetDataStore(Config.DATA_STORE_NAME)

local DataModule = {}
local playerCache = {}

local function getDefaultData()
	return {
		Eggs            = 0,
		TotalEggs       = 0,
		Rebirths        = 0,
		HatchedEggs     = 0,
		SpeedLevel      = 0,
		BackpackLevel   = 0,
		MultiplierLevel = 0,
		JumpLevel       = 0,
	}
end

local function reconcile(loaded)
	local defaults = getDefaultData()
	if type(loaded) ~= "table" then
		return defaults
	end
	for key, val in pairs(defaults) do
		if loaded[key] == nil then
			loaded[key] = val
		end
	end
	return loaded
end

local function safeGet(key)
	local attempts = 0
	local success, result
	repeat
		attempts += 1
		success, result = pcall(function()
			return DataStore:GetAsync(key)
		end)
		if not success then
			warn("[DataModule] GetAsync retry " .. attempts .. ": " .. tostring(result))
			task.wait(2 ^ attempts)
		end
	until success or attempts >= 4
	return success, result
end

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
			warn("[DataModule] UpdateAsync retry " .. attempts .. ": " .. tostring(err))
			task.wait(2 ^ attempts)
		end
	until success or attempts >= 4
	return success
end

function DataModule.Load(player: Player)
	local key = tostring(player.UserId)
	local success, data = safeGet(key)
	if success and data then
		playerCache[player.UserId] = reconcile(data)
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
	return d
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

-- Rebirth Transaction
function DataModule.PerformRebirth(player: Player): boolean
	local d = DataModule.Get(player)
	local currentRebirths = d.Rebirths or 0
	local cost, speedReq = Config.GetRebirthCost(currentRebirths)

	if d.Eggs >= cost and d.SpeedLevel >= speedReq then
		d.Eggs = 0
		d.SpeedLevel = 0
		d.Rebirths = currentRebirths + 1
		playerCache[player.UserId] = d
		DataModule.Save(player)
		return true
	end
	return false
end

function DataModule.Save(player: Player)
	local data = playerCache[player.UserId]
	if not data then return end
	safeSave(tostring(player.UserId), data)
end

function DataModule.RemoveCache(player: Player)
	playerCache[player.UserId] = nil
end

task.spawn(function()
	while true do
		task.wait(Config.AUTO_SAVE_INTERVAL)
		for _, p in ipairs(Players:GetPlayers()) do
			task.spawn(function() DataModule.Save(p) end)
		end
	end
end)

game:BindToClose(function()
	if RunService:IsStudio() then
		task.wait(2)
		return
	end
	local threads = {}
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(threads, task.spawn(function() DataModule.Save(p) end))
	end
	task.wait(8)
end)

return DataModule
