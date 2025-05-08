function UpdateGraffitiData()
    local Players = GetPlayers()
    if Players and isLoaded then
        for k,v in pairs(Players) do
            if v then
                TriggerClientEvent('qb-graffiti:client:setGraffitiData', k, Config.Graffitis)
            end
        end
    end
end