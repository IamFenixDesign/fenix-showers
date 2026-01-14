Bridge = Bridge or {}

local function isQB()
    return GetResourceState('qb-core') == 'started'
end

if not isQB() then return end

local QBCore = exports['qb-core']:GetCoreObject()

Bridge.Framework = 'qb'

function Bridge.Notify(msg, nType)
    QBCore.Functions.Notify(msg, nType or 'primary')
end

function Bridge.Progress(durationMs, label)
    if GetResourceState('ox_lib') == 'started' and lib and lib.progressBar then
        return lib.progressBar({
            duration = durationMs,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true }
        }) == true
    end

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

function Bridge.RestoreSkin()
    if GetResourceState('qb-clothing') == 'started' then
        TriggerServerEvent("qb-clothes:loadPlayerSkin")
        TriggerServerEvent("qb-clothing:loadPlayerSkin")
    elseif GetResourceState('qb-clothes') == 'started' then
        TriggerServerEvent("qb-clothes:loadPlayerSkin")
    end
end
