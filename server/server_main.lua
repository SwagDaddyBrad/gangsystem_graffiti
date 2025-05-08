isLoaded = false

CreateThread(function()
    print("loading graffiti data")
    MySQL.query('Select `key`, `owner`, `model`, `coords`, `rotation` from `graffitis`', {}, function(result)
        for k,v in pairs(result) do
            if v then
                local coords = json.decode(v.coords)
                local rotation = json.decode(v.rotation)

                Config.Graffitis[tonumber(v.key)] = {
                    key = tonumber(v.key),
                    model = tonumber(v.model),
                    coords = vector3(QBCore.Shared.Round(coords.x, 2), QBCore.Shared.Round(coords.y, 2), QBCore.Shared.Round(coords.z, 2)),
                    rotation = vector3(QBCore.Shared.Round(rotation.x, 2), QBCore.Shared.Round(rotation.y, 2), QBCore.Shared.Round(rotation.z, 2)),
                    entity = nil,
                    blip = nil
                }
            end
        end
        isLoaded = true
    end)
end)

lib.callback.register('qb-graffiti:server:getGraffitiData', function(source)
    while not isLoaded do
        Wait(0)
    end
    return Config.Graffitis
end)

RegisterServerEvent('qb-graffiti:client:addServerGraffiti', function(model, coords, rotation)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if Player and isLoaded then
        if RemoveItem(source, 'spraycan', 1) then
            MySQL.insert('Insert into `graffitis` (owner, model, `coords`, `rotation`) values (@owner, @model, @coords, @rotation)', {
                ['@owner'] = Player.PlayerData.citizenid,
                ['@model'] = tostring(model),
                ['@coords'] = json.encode(vector3(QBCore.Shared.Round(coords.x, 2), QBCore.Shared.Round(coords.y, 2), QBCore.Shared.Round(coords.z, 2))),
                ['@rotation'] = json.encode(vector3(QBCore.Shared.Round(rotation.x, 2), QBCore.Shared.Round(rotation.y, 2), QBCore.Shared.Round(rotation.z, 2)))
            }, function(key)
                Config.Graffitis[tonumber(key)] = {
                    key = tonumber(key),
                    model = tonumber(model),
                    coords = vector3(QBCore.Shared.Round(coords.x, 2), QBCore.Shared.Round(coords.y, 2), QBCore.Shared.Round(coords.z, 2)),
                    rotation = vector3(QBCore.Shared.Round(rotation.x, 2), QBCore.Shared.Round(rotation.y, 2), QBCore.Shared.Round(rotation.z, 2)),
                    entity = nil,
                    blip = nil
                }
                UpdateGraffitiData()
            end)
        else
            TriggerClientEvent('cb-gangsystem:client:Notify', source, "Missing Spraycan", "You don't have a spraycan!", "error")
        end
    end
end)

RegisterServerEvent('qb-graffiti:server:removeServerGraffitiByKey', function(key)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)

    if Player and isLoaded then
        MySQL.query('Delete from `graffitis` where `key` = @key', {
            ['@key'] = tonumber(key)
        }, function()
            Config.Graffitis[key] = nil
            UpdateGraffitiData()
        end)
    end
end)

AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId, metadata)
    if name == "spraycan" then
        print("spraycan")
        TriggerClientEvent('qb-graffiti:client:placeGraffiti', playerId, GetHashKey('sprays_angels'))
    end
end)

AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId, metadata)
    if name == "sprayremover" then
        print("sprayremover")
        TriggerClientEvent('qb-graffiti:client:removeClosestGraffiti', playerId)
    end
end)