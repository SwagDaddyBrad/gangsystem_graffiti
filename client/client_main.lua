rotationCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', 0)
sprayingParticle = nil
placingObject = nil
sprayingCan = nil
isPlacing = false
canPlace = false
isLoaded = false

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        print(isLoaded)

        if isLoaded then
            for k, v in pairs(Config.Graffitis) do
                local information = GetInfo(tonumber(v.model))

                if information then
                    if #(coords - v.coords) < 100.0 then
                        if not DoesEntityExist(v.entity) then
                            RequestModel(tonumber(v.model))
                            while not HasModelLoaded(tonumber(v.model)) do
                                Wait(0)
                            end
                            print("Creating Graffiti")
                            v.entity = CreateObjectNoOffset(tonumber(v.model), v.coords, false, false)
                            SetEntityRotation(v.entity, v.rotation.x, v.rotation.y, v.rotation.z)
                            FreezeEntityPosition(v.entity, true)
                        end
                    else
                        if DoesEntityExist(v.entity) then
                            print("Deleting Graffiti")
                            DeleteEntity(v.entity)
                            v.entity = nil
                        end
                    end

                    if information.blip == true then
                        if not DoesBlipExist(v.blip) then
                            v.blip = AddBlipForRadius(v.coords, 100.0)
                            SetBlipAlpha(v.blip, 100)
                            SetBlipColour(v.blip, information.blipcolor)
                        end
                    end
                end
            end
        end
        Wait(1000)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if not isLoaded then
        QBCore.Functions.TriggerCallback('qb-graffiti:server:getGraffitiData', function(data)
            Config.Graffitis = data
            isLoaded = true
            SpawnExistingGraffiti()
        end)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if isLoaded then
        isLoaded = false

        for k,v in pairs(Config.Graffitis) do
            if v then
                if DoesEntityExist(v.entity) then
                    DeleteEntity(v.entity)
                end
    
                if DoesBlipExist(v.blip) then
                    RemoveBlip(v.blip)
                end
            end
        end
    
        Config.Graffitis = {}
    end
end)

RegisterNetEvent('gangsystem_graffiti:client:setGraffitiData', function(data)
    if isLoaded then
        for k,v in pairs(Config.Graffitis) do
            if v then
                if DoesEntityExist(v.entity) then
                    DeleteEntity(v.entity)
                end

                if DoesBlipExist(v.blip) then
                    RemoveBlip(v.blip)
                end
            end
        end
        Config.Graffitis = data
        SpawnExistingGraffiti()
    end
end)

RegisterNetEvent('qb-graffiti:client:placeGraffiti', function(model)
    local ped = PlayerPedId()
    if isPlacing then
        return
    end
    if isLoaded then
        PlaceGraffiti(model, function(result, coords, rotation)
            if result then
                local allowed = lib.callback.await('cb-gangsystem:server:CanSprayGraffiti')
                if not allowed then
                    Notify("Not Enough Prevalence", "You don't have enough prevalence to spray graffiti", "error")
                    return
                end
                local tempAlpha = 0
                local tempSpray = CreateObjectNoOffset(model, coords, false, false, false)
                SetEntityRotation(tempSpray, rotation.x, rotation.y, rotation.z)
                FreezeEntityPosition(tempSpray, true)
                SetEntityAlpha(tempSpray, 0, false)

                CreateThread(function()
                    while tempAlpha < 255 do
                        tempAlpha = tempAlpha + 51
                        SetEntityAlpha(tempSpray, tempAlpha, false)
                        Wait(Config.SprayDuration / 5)
                    end
                end)

                SprayingAnim()
                local progress = lib.progressBar({
                    duration = Config.SprayDuration,
                    label = Lang:t('progressbar.spraying_on_wall'),
                    useWhileMoving = true,
                    canCancel = true,
                    disable = {
                        move = true,
                        car = true,
                        combat = true,
                    },                    
                })
                if progress then
                    ClearPedTasks(ped)
                    StopParticleFxLooped(sprayingParticle, true)
                    DeleteObject(sprayingCan)
                    DeleteObject(tempSpray)
                    sprayingParticle = nil
                    sprayingCan = nil
                    TriggerServerEvent('qb-graffiti:client:addServerGraffiti', model, coords, rotation)
                    local playerPed = PlayerPedId()
                    local gangID = exports['cb-gangsystem']:GetGangIDClient()
                    if gangID ~= nil then
                        local zonePlayerIn = exports['cb-gangsystem']:GetGangZonePlayer(GetEntityCoords(playerPed))
                        if zonePlayerIn ~= nil then
                            TriggerServerEvent("cb-gangsystem:server:SprayGraffiti")
                        end
                    end
                else
                    ClearPedTasks(ped)
                    StopParticleFxLooped(sprayingParticle, true)
                    DeleteObject(sprayingCan)
                    DeleteObject(tempSpray)
                    sprayingParticle = nil
                    sprayingCan = nil
                end
            end
        end)
    end
end)

RegisterNetEvent('qb-graffiti:client:removeClosestGraffiti', function()
    local ped = PlayerPedId()
    local graffiti = GetClosestGraffiti(5.0)
    if isLoaded then
        if not graffiti then
            QBCore.Functions.Notify(Lang:t('error.not_found'), 'error')
        else
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_MAID_CLEAN", 0, true)
            local progress = lib.progressBar({
                duration = Config.RemoveDuration,
                label = Lang:t('progressbar.washing_the_wall'),
                useWhileMoving = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    combat = true,
                },
            })
            if progress then
                ClearPedTasks(ped)
                TriggerServerEvent('qb-graffiti:server:removeServerGraffitiByKey', tonumber(graffiti))
            else
                ClearPedTasks(ped)
            end
        end
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    Wait(2000)

    if not isLoaded then
        local data = lib.callback.await('qb-graffiti:server:getGraffitiData')
        Config.Graffitis = data
        isLoaded = true
        SpawnExistingGraffiti()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    for k,v in pairs(Config.Graffitis) do
        if v then
            if DoesEntityExist(v.entity) then
                DeleteEntity(v.entity)
            end
            
            if DoesBlipExist(v.blip) then
                RemoveBlip(v.blip)
            end
        end
    end
end)

RegisterCommand('spray', function()
    TriggerEvent('qb-graffiti:client:placeGraffiti', GetHashKey('sprays_angels'), 1)
end, false)

-- Function to spawn existing graffiti
function SpawnExistingGraffiti()
    if not isLoaded or not Config.Graffitis then return end
    
    for k, v in pairs(Config.Graffitis) do
        if v and v.model and v.coords and v.rotation then
            -- Load the model
            lib.requestModel(v.model, 10000)
            
            -- Create the graffiti object
            local graffiti = CreateObject(v.model, v.coords.x, v.coords.y, v.coords.z-2, false, false, false)
            
            -- Set the rotation
            SetEntityRotation(graffiti, v.rotation.x, v.rotation.y, v.rotation.z)
            
            -- Freeze the entity
            FreezeEntityPosition(graffiti, true)
            
            -- Store the entity in the Config.Graffitis table
            Config.Graffitis[k].entity = graffiti
            
            -- Create blip if needed
            if Config.Sprays[v.model] and Config.Sprays[v.model].blip then
                local blip = AddBlipForEntity(graffiti)
                SetBlipSprite(blip, 1)
                SetBlipDisplay(blip, 4)
                SetBlipScale(blip, 0.8)
                SetBlipColour(blip, Config.Sprays[v.model].blipcolor)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(Config.Sprays[v.model].name)
                EndTextCommandSetBlipName(blip)
                
                -- Store the blip in the Config.Graffitis table
                Config.Graffitis[k].blip = blip
            end
        end
    end
end
