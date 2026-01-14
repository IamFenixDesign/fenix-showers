Bridge = Bridge or {}

local function isESX()
    return GetResourceState('es_extended') == 'started'
end

if not isESX() then return end

local ESX = nil

if exports and exports['es_extended'] and exports['es_extended'].getSharedObject then
    ESX = exports['es_extended']:getSharedObject()
else
    CreateThread(function()
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Wait(200)
        end
    end)
end

Bridge.Framework = 'esx'

function Bridge.Notify(msg, nType)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
        return
    end

    if GetResourceState('ox_lib') == 'started' and lib and lib.notify then
        lib.notify({ title = 'Shower', description = msg, type = nType or 'inform' })
        return
    end

    print("[SHOWER] Notification fallback: " .. tostring(msg))
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

    Wait(durationMs)
    return true
end

function Bridge.RestoreSkin()
    if GetResourceState('esx_skin') == 'started' then
        TriggerEvent('esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('skinchanger:loadSkin', skin)
        end)
    end
end
