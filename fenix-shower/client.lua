local QBCore = exports['qb-core']:GetCoreObject()
local takingShower = false
local originalOutfit = nil
local lastShowerTime = 0
local showerActive = false

function ShowNotification(notif)
    if Config.Notify == "ox" then
        lib.notify({
            title = notif.title,
            description = notif.message,
            type = notif.type
        })
    else
        QBCore.Functions.Notify(notif.message, notif.type)
    end
end

CreateThread(function()
    if Config.Target == "ox" then
        for i, pos in pairs(Config.ShowerLocations) do
            exports.ox_target:addSphereZone({
                coords = pos,
                radius = 0.5,
                debug = false,
                options = {
                    {
                        name = Config.TargetSettings.namePrefix .. i,
                        icon = Config.TargetSettings.icon,
                        label = Config.TargetSettings.label,
                        onSelect = function()
                            StartShower()
                        end
                    }
                }
            })
        end
    elseif Config.Target == "qb" then
        for i, pos in pairs(Config.ShowerLocations) do
            exports['qb-target']:AddBoxZone(Config.TargetSettings.namePrefix .. i, pos, 1.5, 1.5, {
                name = Config.TargetSettings.namePrefix .. i,
                heading = 0,
                debugPoly = false,
                minZ = pos.z - 1,
                maxZ = pos.z + 1,
            }, {
                options = {
                    {
                        type = "client",
                        event = "shower:start",
                        icon = Config.TargetSettings.icon,
                        label = Config.TargetSettings.label
                    }
                },
                distance = 0.5
            })
        end
    end
end)

RegisterNetEvent("shower:start", function()
    StartShower()
end)

function StartShower()
    if takingShower then return end

    local currentTime = GetGameTimer()
    if currentTime - lastShowerTime < (Config.Shower.Cooldown * 1000) then
        ShowNotification(Config.Notifications.Cooldown)
        return
    end

    takingShower = true
    lastShowerTime = currentTime

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    
    if Config.ClothingSystem == "illenium" then
        originalOutfit = exports['illenium-appearance']:getPedAppearance(ped)
    else
        TriggerEvent("qb-clothing:client:saveOutfitData", function(data)
            originalOutfit = data
        end)
        while originalOutfit == nil do Wait(100) end
    end

    local gender = GetEntityModel(ped) == `mp_m_freemode_01` and "male" or "female"
    local outfit = Config.ShowerOutfits[gender]

    if not outfit then
        print("^1[ERROR] No se encontró outfit para el género: " .. gender .. "^7")
        takingShower = false
        FreezeEntityPosition(ped, false)
        return
    end

    local componentMap = {
        ["mask"] = 1,
        ["arms"] = 3,
        ["pants"] = 4,
        ["bag"] = 5,
        ["shoes"] = 6,
        ["accessory"] = 7,
        ["t-shirt"] = 8,
        ["vest"] = 9,
        ["decals"] = 10,
        ["torso"] = 11,
        ["undershirt"] = 8 
    }

    local propMap = {
        ["hat"] = 0,
        ["glasses"] = 1,
        ["ears"] = 2,
        ["watch"] = 6,
        ["bracelet"] = 7
    }


    local outfitData = {}
    local components = {}
    local props = {}

    for k, v in pairs(outfit) do
        if type(v) == "table" and v.item ~= nil and v.texture ~= nil then
            outfitData[k] = { item = v.item, texture = v.texture }

            if componentMap[k] then
                table.insert(components, {
                    component_id = componentMap[k],
                    drawable = v.item,
                    texture = v.texture
                })
            elseif propMap[k] then
                table.insert(props, {
                    prop_id = propMap[k],
                    drawable = v.item,
                    texture = v.texture
                })
            end
        end
    end

    if Config.ClothingSystem == "illenium" then
        exports['illenium-appearance']:setPedAppearance(ped, {
            components = components,
            props = props
        })
    else
        TriggerEvent("qb-clothing:client:loadOutfit", {
            outfitData = outfitData
        })
    end

    RequestAnimDict(Config.Shower.IdleAnim.dict)
    while not HasAnimDictLoaded(Config.Shower.IdleAnim.dict) do Wait(0) end
    TaskPlayAnim(ped, Config.Shower.IdleAnim.dict, Config.Shower.IdleAnim.anim, 8.0, -8.0, Config.Shower.Duration * 1000, 1, 0, false, false, false)

    RequestNamedPtfxAsset("core")
    while not HasNamedPtfxAssetLoaded("core") do Wait(1) end

    showerActive = true
    CreateThread(function()
        while showerActive do
            local coords = GetEntityCoords(ped)
            UseParticleFxAssetNextCall("core")
            StartParticleFxNonLoopedAtCoord("ent_sht_water", coords.x, coords.y, coords.z + 1.2, 0.0, 180.0, 0.0, 5.0, false, false, false)
            Wait(Config.Shower.ParticleInterval * 1000)
        end
    end)

    local success = true
    if Config.ProgressBar == "ox" then
        success = lib.progressBar({
            duration = Config.Shower.Duration * 1000,
            label = Config.Shower.ProgressLabel,
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true }
        })
    elseif Config.ProgressBar == "qb" then
        QBCore.Functions.Progressbar("shower_action", Config.Shower.ProgressLabel, Config.Shower.Duration * 1000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        }, {}, {}, {}, function()
            success = true
        end, function()
            success = false
        end)

        while success == true do Wait(100) end
    elseif Config.ProgressBar == "none" then
        Wait(Config.Shower.Duration * 1000)
        success = true
    end

    if not success then
        showerActive = false
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, false)

        if originalOutfit then
            if Config.ClothingSystem == "illenium" then
                exports['illenium-appearance']:setPedAppearance(ped, originalOutfit)
            else
                TriggerEvent("qb-clothing:client:loadOutfit", {
                    outfitData = originalOutfit
                })
            end
        end

        takingShower = false
        return
    end

    showerActive = false
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedDecorations(ped)

    RequestAnimDict(Config.Shower.RestoreAnimation.dict)
    while not HasAnimDictLoaded(Config.Shower.RestoreAnimation.dict) do Wait(0) end
    TaskPlayAnim(ped, Config.Shower.RestoreAnimation.dict, Config.Shower.RestoreAnimation.anim, 8.0, -8.0, Config.Shower.RestoreAnimation.duration * 1000, 1, 0, false, false, false)
    Wait(Config.Shower.RestoreAnimation.duration * 1000)
    ClearPedTasks(ped)

    if originalOutfit then
        if Config.ClothingSystem == "illenium" then
            exports['illenium-appearance']:setPedAppearance(ped, originalOutfit)
        else
            TriggerEvent("qb-clothing:client:loadOutfit", {
                outfitData = originalOutfit
            })
        end
    end

    ShowNotification(Config.Notifications.Finished)
    takingShower = false
end
