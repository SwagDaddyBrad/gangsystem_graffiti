Config = {}
Config.Graffitis = {}
QBCore = exports['qb-core']:GetCoreObject()

Config.BlacklistedZones = {
    --{coords = vector3(455.81, -997.04, 43.69), radius = 200.0}, -- Police
    --{coords = vector3(324.76, -585.72, 59.15), radius = 300.0}, -- Hospital
    --{coords = vector3(-376.73, -119.47, 40.73), radius = 400.0}, -- Mechanic
}

Config.SprayDuration = 5000 -- How long it takes to spray a graffiti
Config.RemoveDuration = 5000 -- How long it takes to remove a graffiti
Config.CheckForNearbyGraffitis = {
    enabled = false,
    distance = 100.0
}

Config.Sprays = {
    [GetHashKey('sprays_angels')] = {
        name = 'Spray Angels',
        price = 5000,
        blip = false,
        blipcolor = 1,
        gang = nil
    },
}