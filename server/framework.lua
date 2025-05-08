if GetResourceState('qbx_core') == 'started' then
    Framework = "qbox"
elseif GetResourceState('qb-core') == 'started' then

    Framework = "qb-core"
    QBCore = exports['qb-core']:GetCoreObject()
end
if GetResourceState('qb-target') == 'started' then
    Target = "qb"
elseif GetResourceState('ox_target') == 'started' then
    Target = "ox"
end
UsingOxInventory = GetResourceState('ox_inventory') == 'started'

function SQLQuery(query, params)
    print(string.format("\27[33mSQL Query: %s\27[0m", query))
    if params then
        return MySQL.query.await(query, params)
    else
        return MySQL.query.await(query)
    end
end

---@return number[]           -- Returns an array of player server IDs, or an empty array if no players are found
function GetPlayers()
    if Framework == "qb-core" then
        return QBCore.Functions.GetPlayers()
    elseif Framework == "qbox" then
        local sources = {}
        local players = exports.qbx_core:GetQBPlayers()
        for k in pairs(players) do
            sources[#sources+1] = k
        end
        return sources
    end
    return {}
end

---@param target number        -- The target player's unique identifier (server ID)
---@return table|nil           -- Returns the player object as a table if found, or nil if the player is not found or the framework is unrecognized
function GetPlayer(target)
    if Framework == "qb-core" then
        return QBCore.Functions.GetPlayer(target)
    elseif Framework == "qbox" then
        return exports.qbx_core:GetPlayer(target)
    end
    return nil
end

function GetFirstName(target)
    local Player = GetPlayer(target)
    if Player == nil then return nil end
    return Player.PlayerData.charinfo.firstname
end

function GetLastName(target)
    local Player = GetPlayer(target)
    if Player == nil then return nil end
    return Player.PlayerData.charinfo.lastname
end

function GetFullName(target)
    local Player = GetPlayer(target)
    if Player == nil then return nil end
    return Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
end

function Split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        result[#result+1] =string.sub(str, from, delim_from - 1)
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    result[#result+1] = string.sub(str, from)
    return result
end

---@param source number       -- The player's unique identifier (server ID)
---@param item string         -- The name of the item to remove
---@param amount number       -- The quantity of the item to remove
function RemoveItem(source, item, amount)
    print(source, item, amount)
    if not UsingOxInventory then
        local Player = GetPlayer(source)
        if Player == nil then return end
        Player.Functions.RemoveItem(item, amount)
    elseif UsingOxInventory then
        return exports.ox_inventory:RemoveItem(source, item, amount)
    end
end

---@param source number       -- The player's unique identifier (server ID)
---@param item string         -- The name of the item to add
---@param amount number       -- The quantity of the item to add
---@return boolean            -- Returns true if the item was added successfully
function AddItem(source, item, amount)
    if not UsingOxInventory then
        local Player = GetPlayer(source)
        if not Player then return false end
        Player.Functions.AddItem(item, amount)
        return true
    elseif UsingOxInventory then
        local canCarryItem = exports.ox_inventory:CanCarryItem(source, item, amount)
        if canCarryItem then
            exports.ox_inventory:AddItem(source, item, amount)
            return true
        else
            return false
        end
    end
    return false
end

function GetPlayerCoords(target)
    local playerPed = GetPlayerPed(target)
    return GetEntityCoords(playerPed)
end

---@param source number       -- The player's unique identifier (server ID)
---@param item string         -- The name of the item to check
---@param amount number       -- The quantity of the item to check for
---@return boolean            -- Returns true if the player has the item in the specified amount, false otherwise
function HasItem(source, item, amount)
    print(source, item, amount)
    local Player = GetPlayer(source)
    if Player == nil then return false end
    if not UsingOxInventory and Framework == "qb-core" then
        return Player.Functions.HasItem(item, amount)
    elseif UsingOxInventory then
        local itemCount = exports.ox_inventory:Search(source, "count", item)
        print(itemCount)
        if type(itemCount) == "table" then
            for k, v in pairs(itemCount) do
                itemCount = v
            end
        end
        if not itemCount then
            return false
        elseif itemCount >= amount then
            return true
        else
            return false
        end
    end
    return false
end