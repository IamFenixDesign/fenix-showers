Bridge = Bridge or {}

local HAS_OX_LIB     = (GetResourceState('ox_lib') == 'started')
local HAS_OX_TARGET  = (GetResourceState('ox_target') == 'started')
local HAS_QB_TARGET  = (GetResourceState('qb-target') == 'started')
local HAS_QB_CORE    = (GetResourceState('qb-core') == 'started')
local HAS_ILLENIUM   = (GetResourceState('illenium-appearance') == 'started')
local HAS_QB_CLOTHES = (GetResourceState('qb-clothing') == 'started' or GetResourceState('qb-clothes') == 'started')

local function NotifyAuto(notif)
    if Bridge and Bridge.Notify then
        Bridge.Notify(notif.message, notif.type)
        return
    end

    if HAS_OX_LIB and lib and lib.notify then
        lib.notify({ title = "Shower", description = notif.message, type = notif.type or "inform" })
        return
    end
end

local function ProgressAuto(durationMs, label)
    if Bridge and Bridge.Progress then
        return Bridge.Progress(durationMs, label) == true
    end

    if HAS_OX_LIB and lib and lib.progressBar then
        return lib.progressBar({
            duration = durationMs,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true }
        }) == true
    end

    print(("[SHOWER] Progress fallback (%dms): %s"):format(durationMs, tostring(label)))
    Wait(durationMs)
    return true
end

local function RestoreOutfit(ped, originalOutfit)
    if HAS_ILLENIUM and originalOutfit then
        exports['illenium-appearance']:setPedAppearance(ped, originalOutfit)
        return
    end

    if Bridge and Bridge.RestoreSkin then
        Bridge.RestoreSkin()
        return
    end
end

-- =========================
--  NEW: helpers (autowalk)
-- =========================
local function GetNearestShowerPos(ped)
    local pcoords = GetEntityCoords(ped)
    local nearest, nearestDist = nil, 999999.0

    for _, pos in pairs(Config.ShowerLocations) do
        local d = #(pcoords - pos)
        if d < nearestDist then
            nearestDist = d
            nearest = pos
        end
    end

    return nearest, nearestDist
end

local function WalkIntoRadius(ped, targetPos, radius)
    local dist = #(GetEntityCoords(ped) - targetPos)
    if dist <= radius then return true end

    TaskGoStraightToCoord(ped, targetPos.x, targetPos.y, targetPos.z, 1.0, -1, 0.0, 0.5)

    local start = GetGameTimer()
    local timeout = 8000 -- ms
    while true do
        Wait(50)

        if not DoesEntityExist(ped) then return false end
        dist = #(GetEntityCoords(ped) - targetPos)
        if dist <= radius then
            ClearPedTasks(ped)
            return true
        end

        if GetGameTimer() - start > timeout then
            ClearPedTasks(ped)
            return false
        end
    end
end

-- =========================
--  State
-- =========================
local takingShower = false
local originalOutfit = nil
local lastShowerTime = 0
local showerActive = false

-- =========================
--  Targets
-- =========================
CreateThread(function()
    if HAS_OX_TARGET then
        print("[SHOWER] Target system detected: ox_target")

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
                            StartShower(pos) -- NEW: pass pos
                        end
                    }
                }
            })
        end
        return
    end

    if HAS_QB_TARGET then
        print("[SHOWER] Target system detected: qb-target")

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
                            icon = Config.TargetSettings.icon,
                            label = Config.TargetSettings.label,
                            action = function()
                                StartShower(pos) -- NEW: pass pos
                            end
                        }
                    },
                    distance = 1.5
                }
            )
        end
        return
    end

    print("[SHOWER] ERROR: No target system detected (ox_target / qb-target).")
end)

-- Keep event for compatibility (no pos -> nearest)
RegisterNetEvent("shower:start", function()
    StartShower(nil)
end)

-- =========================
--  Main
-- =========================
function StartShower(showerPos)
    if takingShower then return end

    local ped = PlayerPedId()

    -- Choose shower position
    if not showerPos then
        showerPos = select(1, GetNearestShowerPos(ped))
    end
    if not showerPos then return end

    -- Force player into <= 0.5 radius (silent)
    local ok = WalkIntoRadius(ped, showerPos, 0.5)
    if not ok then return end

    -- Cooldown check (silent) - do not notify
    local currentTime = GetGameTimer()
    if currentTime - lastShowerTime < (Config.Shower.Cooldown * 1000) then
        return
    end

    takingShower = true

    -- IMPORTANT CHANGE:
    -- Do NOT set lastShowerTime here.
    -- Only set it when the shower FINISHES successfully.
    -- This way canceling will not trigger cooldown.

    FreezeEntityPosition(ped, true)

    originalOutfit = nil
    if HAS_ILLENIUM then
        originalOutfit = exports['illenium-appearance']:getPedAppearance(ped)
    end

    local gender = (GetEntityModel(ped) == `mp_m_freemode_01`) and "male" or "female"
    local outfit = Config.ShowerOutfits[gender]

    if not outfit then
        takingShower = false
        FreezeEntityPosition(ped, false)
        return
    end

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
        exports['illenium-appearance']:setPedAppearance(ped, { components = components, props = props })
    else
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

    -- NEW: cancelable shower (progressBar already canCancel = true)
    local success = ProgressAuto(Config.Shower.Duration * 1000, Config.Shower.ProgressLabel)

    if not success then
        -- canceled: NO cooldown set
        showerActive = false
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, false)
        RestoreOutfit(ped, originalOutfit)
        takingShower = false
        return
    end

    -- Completed successfully: set cooldown timestamp now
    lastShowerTime = GetGameTimer()

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
