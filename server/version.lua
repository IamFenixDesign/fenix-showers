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

local function NotifyAuto(notif)
    if HAS_OX_LIB and lib and lib.notify then
        print("[SHOWER] Notification sent via ox_lib")
        lib.notify({
            title = notif.title,
            description = notif.message,
            type = notif.type
        })
        return
    end

    if HAS_QB_CORE and EnsureQBCore() and QBCore.Functions.Notify then
        print("[SHOWER] Notification sent via QBCore")
        QBCore.Functions.Notify(notif.message, notif.type)
        return
    end
end

local function ProgressAuto(durationMs, label)
    if HAS_OX_LIB and lib and lib.progressBar then
        print("[SHOWER] Progress bar using ox_lib")
        return lib.progressBar({
            duration = durationMs,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true }
        }) == true
    end

    if HAS_QB_CORE and EnsureQBCore() and QBCore.Functions.Progressbar then
        print("[SHOWER] Progress bar using QBCore")
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

    print("[SHOWER] No progress bar system found, using fallback timer.")
    Wait(durationMs)
    return true
end

local function RestoreQbSkin()
    print("[SHOWER] Restoring outfit via qb-clothing")
    if GetResourceState('qb-clothing') == 'started' then
        TriggerServerEvent("qb-clothes:loadPlayerSkin")
        TriggerServerEvent("qb-clothing:loadPlayerSkin")
    elseif GetResourceState('qb-clothes') == 'started' then
        TriggerServerEvent("qb-clothes:loadPlayerSkin")
    end
end

local function RestoreOutfit(ped, originalOutfit)
    if HAS_ILLENIUM and originalOutfit then
        print("[SHOWER] Restoring outfit via illenium-appearance")
        exports['illenium-appearance']:setPedAppearance(ped, originalOutfit)
        return
    end

    if HAS_QB_CLOTHES then
        RestoreQbSkin()
        return
    end

    print("[SHOWER] No clothing system detected, using native ped components.")
end

local takingShower = false
local originalOutfit = nil
local lastShowerTime = 0
local showerActive = false

CreateThread(function()
    if HAS_OX_TARGET then
        print("[SHOWER] Using ox_target")
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
        print("[SHOWER] Using qb-target")
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
        end
        return
    end

    print("[SHOWER] ERROR: No target system detected (ox_target or qb-target).")
end)

RegisterNetEvent("shower:start", function()
    StartShower()
end)

function StartShower()
    if takingShower then return end

    local currentTime = GetGameTimer()
    if currentTime - lastShowerTime < (Config.Shower.Cooldown * 1000) then
        NotifyAuto(Config.Notifications.Cooldown)
        return
    end

    print("[SHOWER] Shower started.")

    takingShower = true
    lastShowerTime = currentTime

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)

    originalOutfit = nil
    if HAS_ILLENIUM then
        print("[SHOWER] Saving outfit via illenium-appearance")
        originalOutfit = exports['illenium-appearance']:getPedAppearance(ped)
    end

    local gender = (GetEntityModel(ped) == `mp_m_freemode_01`) and "male" or "female"
    local outfit = Config.ShowerOutfits[gender]
    if not outfit then
        print("[SHOWER] ERROR: No shower outfit found for gender: " .. gender)
        takingShower = false
        FreezeEntityPosition(ped, false)
        return
    end

    if HAS_ILLENIUM then
        print("[SHOWER] Applying shower outfit via illenium-appearance")
    elseif HAS_QB_CLOTHES then
        print("[SHOWER] Applying shower outfit via native components (qb-clothing fallback)")
    else
        print("[SHOWER] Applying shower outfit via native ped components")
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

    local success = ProgressAuto(Config.Shower.Duration * 1000, Config.Shower.ProgressLabel)
    if not success then
        print("[SHOWER] Shower cancelled.")
        showerActive = false
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, false)
        RestoreOutfit(ped, originalOutfit)
        takingShower = false
        return
    end

    print("[SHOWER] Shower finished successfully.")

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

    RestoreOutfit(ped, originalOutfit)
    NotifyAuto(Config.Notifications.Finished)
    takingShower = false
end
