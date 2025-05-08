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

function GetPlayerData()
    if Framework == "qb-core" then
        return QBCore.Functions.GetPlayerData()
    elseif Framework == "qbox" then
        return QBX.PlayerData
    end
end

function GetFirstName()
    local PlayerData = GetPlayerData()
    if PlayerData == nil then return nil end
    return PlayerData.charinfo.firstname
end

function GetLastName()
    local PlayerData = GetPlayerData()
    if PlayerData == nil then return nil end
    return PlayerData.charinfo.lastname
end

function GetFullName()
    local PlayerData = GetPlayerData()
    if PlayerData == nil then return nil end
    return PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname
end

function Notify(label, message, notifyType, time)
    if not time then time = 7500 end
    if Config.Notify == "ox" then
        if notifyType == "info" then
            lib.notify({
                title = label,
                description = message,
                duration = time,
                position = 'center-right',
                icon = 'circle-info',
                iconColor = 'teal'
            })
        elseif notifyType == "success" then
            lib.notify({
                title = label,
                description = message,
                duration = time,
                position = 'center-right',
                icon = 'circle-check',
                iconColor = '#008000'
            })
        elseif notifyType == "error" then
            lib.notify({
                title = label,
                description = message,
                duration = time,
                position = 'center-right',
                icon = 'ban',
                iconColor = '#C53030'
            })
        elseif notifyType == "warning" then
            lib.notify({
                title = label,
                description = message,
                duration = time,
                position = 'center-right',
                icon = 'circle-exclamation',
                iconColor = '#FFA500'
            })
        end
    elseif Config.Notify == "qb" then
        QBCore.Functions.Notify(message, notifyType, time)
    elseif Config.Notify == "okok" then
        exports['okokNotify']:Alert(label, message, time, notifyType, true)
    elseif Config.Notify == "other" then
        -- Place your custom notify event here
    end
end

RegisterNetEvent('cb-gangsystem:client:Notify', function(label, message, notifyType, time)
    Notify(label, message, notifyType, time)
end)

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

function HasItemClient(item, amount)
    if not UsingOxInventory and Framework == "qb-core" then
        return QBCore.Functions.HasItem(item, amount)
    elseif UsingOxInventory then
        if UsingOxInventory then
            local itemCount = exports.ox_inventory:Search("count", item)
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
        else
            return QBCore.Functions.HasItem(item, amount)
        end
    end
    return false
end

function HasCashClient(amount)
    local PlayerData = GetPlayerData()
    local cash = PlayerData.money.cash
    return cash >= amount
end

function GetPeds()
    local pedPool = GetGamePool('CPed')
    local ignoreList = {}
    local peds = {}
    for i = 1, #pedPool, 1 do
        local found = false
        for j=1, #ignoreList, 1 do
            if ignoreList[j] == pedPool[i] then
                found = true
            end
        end
        if not found then
            peds[#peds+1] = pedPool[i]
        end
    end
    return peds
end

function AlertCops()
    if Config.DispatchSystem == "cd_dispatch" then
        local data = exports['cd_dispatch']:GetPlayerInfo()
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = Config.PoliceJobs,
            coords = data.coords,
            title = '10-15 - Drug Sale',
            message = 'A ' .. data.sex .. ' Selling Drugs at ' .. data.street,
            flash = 0,
            unique_id = data.unique_id,
            sound = 1,
            blip = {
                sprite = 51,
                scale = 1.2,
                colour = 3,
                flashes = false,
                text = '911 - Drug Sale',
                time = 5,
                radius = 0,
            }
        })
    elseif Config.DispatchSystem == "ps-dispatch" then
        exports['ps-dispatch']:DrugSale()
    elseif Config.DispatchSystem == "qs-dispatch" then
        exports['qs-dispatch']:DrugSale()
    elseif Config.DispatchSystem == "codem" then
        local Data = {
            type = 'Drug',
            header = 'Drug Sale',
            text = "Reports of Drug Sales in the area!",
            code = "911",
        }
        exports['codem-dispatch']:CustomDispatch(Data)
    elseif Config.DispatchSystem == "custom" then
        print("Did you put something in the CustomDispatchNotify function?")
    end
end

function ShowTextUI(text)
    lib.showTextUI(text, {
        position = "left-center",
        icon = 'mask',
        style = {
            borderRadius = 0,
            backgroundColor = '#41e5ff',
            color = 'black'
        }
    })
end

function HideTextUI()
    lib.hideTextUI()
end

function GetGangIDClient(GangMembers)
    if next(GangMembers) == nil then -- This means there are no gang members. Typically after a fresh install.
        return nil
    end
    local PlayerData = GetPlayerData()
    if PlayerData == nil then 
        return nil 
    end
    local citizenID = PlayerData.citizenid
    if GangMembers == nil then 
        return nil 
    end
    if GangMembers[citizenID] == nil then
        return nil
    end
    for k, v in pairs(GangMembers[citizenID]) do
        if k == "gang_id" then
            return v
        end
    end
    return nil
end

function GetGangNameClient(GangMembers)
    local PlayerData = GetPlayerData()
    if PlayerData == nil then return nil end
    local citizenID = PlayerData.citizenid
    for k, v in pairs(GangMembers[citizenID]) do
        if k == "gang_name" then
            return v
        end
    end
    return nil
end

function GetGangRankClient(GangMembers)
    local PlayerData = GetPlayerData()
    if PlayerData == nil then return nil end
    local citizenID = PlayerData.citizenid
    for k, v in pairs(GangMembers[citizenID]) do
        if k == "rank" then
            return v
        end
    end
    return nil
end

function GetMaxCleanCash()
    local PlayerData = GetPlayerData()
    return PlayerData.money.cash
end

function GetMaxDirtyCash()
    local serverConfig = lib.callback.await('cb-gangsystem:server:GetServerConfig', false)
    local itemAmount = exports.ox_inventory:Search("count", serverConfig.GangFund.dirtyCash.item)
    -- TODO: This will need to work with multiple inventory systems
    return itemAmount
end

function OpenStash(stashID)
    local stashName = "gangsystem_stash_" .. stashID
    if UsingOxInventory then
        exports.ox_inventory:openInventory('stash', stashName)
    end
end