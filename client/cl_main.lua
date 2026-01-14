local QBCore = nil

local function EnsureQBCore()
    if QBCore then return true end
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        print("[SHOWER] QBCore detected and loaded.")
        return true
    end
    return false
end

local HAS_OX_LIB     = (GetResourceState('ox_lib') == 'started')
local HAS_OX_TARGET  = (GetResourceState('ox_target') == 'started')
local HAS_QB_TARGET  = (GetResourceState('qb-target') == 'started')
local HAS_QB_CORE    = (GetResourceState('qb-core') == 'started')
local HAS_ILLENIUM   = (GetResourceState('illenium-appearance') == 'started')
local HAS_QB_CLOTHES = (GetResourceState('qb-clothing') == 'started' or GetResourceState('qb-clothes') == 'started')

-- Startup info (one-time)
CreateThread(function()
    print(("[SHOWER] Startup: ox_lib=%s | ox_target=%s | qb-target=%s | qb-core=%s | illenium=%s | qb-clothes=%s")
        :format(tostring(HAS_OX_LIB), tostring(HAS_OX_TARGET), tostring(HAS_QB_TARGET), tostring(HAS_QB_CORE), tostring(HAS_ILLENIUM), tostring(HAS_QB_CLOTHES)))
end)

local function NotifyAuto(notif)
    if HAS_OX_LIB and lib and lib.notify then
        print("[SHOWER] Notification via ox_lib: " .. tostring(notif.message))
        lib.notify({
            title = notif.title,
            description = notif.message,
            type = notif.type
        })
        return
    end

    if HAS_QB_CORE and EnsureQBCore() and QBCore and QBCore.Functions and QBCore.Functions.Notify then
        print("[SHOWER] Notification via QBCore: " .. tostring(notif.message))
        QBCore.Functions.Notify(notif.message, notif.type)
        return
    end

    print("[SHOWER] Notification fallback (no notify system): " .. tostring(notif.message))
end

local function ProgressAuto(durationMs, label)
    if HAS_OX_LIB and lib and lib.progressBar then
        print(("[SHOWER] Progress bar via ox_lib (%dms): %s"):format(durationMs, tostring(label)))
        return lib.progressBar({
            duration = durationMs,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true }
        }) == true
    end

    if HAS_QB_CORE and EnsureQBCore() and QBCore and QBCore.Functions and QBCore.Functions.Progressbar then
        print(("[SHOWER] Progress bar via QBCore (%dms): %s"):format(durationMs, tostring(label)))
        local done, success = false, false
        QBCore.Functions.Progressbar(
            "shower_action",
            label,
            durationMs,
            false,
            true,
            {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true
            },
            {}, {}, {},
            function()
                success = true
                done = true
            end,
            function()
                success = false
                done = true
            end
        )
        while not done do Wait(50) end
        return success
    end

    print(("[SHOWER] Progress fallback (no progress system) (%dms): %s"):format(durationMs, tostring(label)))
    Wait(durationMs)
    return true
end

local function RestoreQbSkin()
    if GetResourceState('qb-clothing') == 'started' then
        print("[SHOWER] Restoring outfit via qb-clothing (qb-clothing started).")
        TriggerServerEvent("qb-clothes:loadPlayerSkin")
        TriggerServerEvent("qb-clothing:loadPlayerSkin")
    elseif GetResourceState('qb-clothes') == 'started' then
        print("[SHOWER] Restoring outfit via qb-clothes (qb-clothes started).")
        TriggerServerEvent("qb-clothes:loadPlayerSkin")
    else
        print("[SHOWER] RestoreQbSkin called but qb clothing resources are not started.")
    end
end

local function RestoreOutfit(ped, originalOutfit)
    if HAS_ILLENIUM and originalOutfit then
        print("[SHOWER] Restoring outfit via illenium-appearance.")
        exports['illenium-appearance']:setPedAppearance(ped, originalOutfit)
        return
    end
    if HAS_QB_CLOTHES then
        print("[SHOWER] Restoring outfit via qb-clothing/qb-clothes.")
        RestoreQbSkin()
        return
    end
    print("[SHOWER] No clothing system detected for restore (illenium/qb-clothes not available).")
end

local takingShower = false
local originalOutfit = nil
local lastShowerTime = 0
local showerActive = false

CreateThread(function()
    if HAS_OX_TARGET then
        print("[SHOWER] Target system: ox_target")
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
        return
    end

    if HAS_QB_TARGET then
        print("[SHOWER] Target system: qb-target")
        for i, pos in pairs(Config.ShowerLocations) do
            exports['qb-target']:AddBoxZone(
                Config.TargetSettings.namePrefix .. i,
                pos,
                1.5,
                1.5,
                {
                    name = Config.TargetSettings.namePrefix .. i,
                    heading = 0,
                    debugPoly = false,
                    minZ = pos.z - 1,
                    maxZ = pos.z + 1,
                },
                {
                    options = {
                        {
                            type = "client",
                            event = "shower:start",
                            icon = Config.TargetSettings.icon,
                            label = Config.TargetSettings.label
                        }
                    },
                    distance = 1.5
                }
            )
            print(("[SHOWER] Registered qb-target zone #%s at (%.2f, %.2f, %.2f)")
                :format(tostring(i), pos.x, pos.y, pos.z))
        end
        return
    end

    print("[SHOWER] ERROR: No target system detected (ox_target / qb-target).")
end)

RegisterNetEvent("shower:start", function()
    print("[SHOWER] Event received: shower:start")
    StartShower()
end)

function StartShower()
    if takingShower then
        print("[SHOWER] StartShower ignored: already showering.")
        return
    end

    local currentTime = GetGameTimer()
    if currentTime - lastShowerTime < (Config.Shower.Cooldown * 1000) then
        print("[SHOWER] Cooldown active: shower denied.")
        NotifyAuto(Config.Notifications.Cooldown)
        return
    end

    takingShower = true
    lastShowerTime = currentTime

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)

    print("[SHOWER] Shower started. Freezing player position.")

    originalOutfit = nil
    if HAS_ILLENIUM then
        print("[SHOWER] Saving outfit via illenium-appearance.")
        originalOutfit = exports['illenium-appearance']:getPedAppearance(ped)
    else
        if HAS_QB_CLOTHES then
            print("[SHOWER] illenium not found. Outfit will be restored via qb-clothing/qb-clothes.")
        else
            print("[SHOWER] illenium/qb-clothes not found. Outfit restore will be limited.")
        end
    end

    local gender = (GetEntityModel(ped) == `mp_m_freemode_01`) and "male" or "female"
    local outfit = Config.ShowerOutfits[gender]
    if not outfit then
        print("[SHOWER] ERROR: No shower outfit found for gender: " .. tostring(gender))
        takingShower = false
        FreezeEntityPosition(ped, false)
        return
    end
    print("[SHOWER] Selected shower outfit for gender: " .. tostring(gender))

    local componentMap = {
        ["mask"] = 1, ["arms"] = 3, ["pants"] = 4, ["bag"] = 5, ["shoes"] = 6,
        ["accessory"] = 7, ["t-shirt"] = 8, ["vest"] = 9, ["decals"] = 10,
        ["torso"] = 11, ["undershirt"] = 8
    }

    local propMap = {
        ["hat"] = 0, ["glasses"] = 1, ["ears"] = 2, ["watch"] = 6, ["bracelet"] = 7
    }

    local components, props = {}, {}

    for k, v in pairs(outfit) do
        if type(v) == "table" and v.item ~= nil and v.texture ~= nil then
            if componentMap[k] then
                components[#components + 1] = { component_id = componentMap[k], drawable = v.item, texture = v.texture }
            elseif propMap[k] then
                props[#props + 1] = { prop_id = propMap[k], drawable = v.item, texture = v.texture }
            end
        end
    end

    if HAS_ILLENIUM then
        print("[SHOWER] Applying shower outfit via illenium-appearance.")
        exports['illenium-appearance']:setPedAppearance(ped, { components = components, props = props })
    else
        print("[SHOWER] Applying shower outfit via native ped components/props.")
        for k, v in pairs(outfit) do
            if type(v) == "table" and v.item ~= nil and v.texture ~= nil then
                local compId = componentMap[k]
                local propId = propMap[k]

                if compId then
                    if v.item == -1 then
                        SetPedComponentVariation(ped, compId, 0, 0, 2)
                    else
                        SetPedComponentVariation(ped, compId, v.item, v.texture, 2)
                    end
                elseif propId then
                    if v.item == -1 then
                        ClearPedProp(ped, propId)
                    else
                        SetPedPropIndex(ped, propId, v.item, v.texture, true)
                    end
                end
            end
        end
    end

    RequestAnimDict(Config.Shower.IdleAnim.dict)
    while not HasAnimDictLoaded(Config.Shower.IdleAnim.dict) do Wait(0) end
    TaskPlayAnim(ped, Config.Shower.IdleAnim.dict, Config.Shower.IdleAnim.anim, 8.0, -8.0, Config.Shower.Duration * 1000, 1, 0, false, false, false)
    print("[SHOWER] Playing idle shower animation.")

    RequestNamedPtfxAsset("core")
    while not HasNamedPtfxAssetLoaded("core") do Wait(1) end

    showerActive = true
    CreateThread(function()
        print("[SHOWER] Water particles enabled.")
        while showerActive do
            local coords = GetEntityCoords(ped)
            UseParticleFxAssetNextCall("core")
            StartParticleFxNonLoopedAtCoord("ent_sht_water", coords.x, coords.y, coords.z + 1.2, 0.0, 180.0, 0.0, 5.0, false, false, false)
            Wait(Config.Shower.ParticleInterval * 1000)
        end
        print("[SHOWER] Water particles disabled.")
    end)

    local success = ProgressAuto(Config.Shower.Duration * 1000, Config.Shower.ProgressLabel)
    if not success then
        print("[SHOWER] Shower cancelled by player.")
        showerActive = false
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, false)
        RestoreOutfit(ped, originalOutfit)
        takingShower = false
        return
    end

    print("[SHOWER] Shower completed successfully.")

    showerActive = false
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, false)

    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedDecorations(ped)
    print("[SHOWER] Player cleaned (damage/blood/decorations cleared).")

    RequestAnimDict(Config.Shower.RestoreAnimation.dict)
    while not HasAnimDictLoaded(Config.Shower.RestoreAnimation.dict) do Wait(0) end
    TaskPlayAnim(ped, Config.Shower.RestoreAnimation.dict, Config.Shower.RestoreAnimation.anim, 8.0, -8.0, Config.Shower.RestoreAnimation.duration * 1000, 1, 0, false, false, false)
    Wait(Config.Shower.RestoreAnimation.duration * 1000)
    ClearPedTasks(ped)
    print("[SHOWER] Played restore animation.")

    RestoreOutfit(ped, originalOutfit)
    NotifyAuto(Config.Notifications.Finished)

    takingShower = false
    print("[SHOWER] Shower flow ended. Player unfrozen and outfit restored.")
end
