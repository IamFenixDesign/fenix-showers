Bridge = Bridge or {}

local function isQBox()
    return GetResourceState('qbx_core') == 'started'
end

if not isQBox() then return end

Bridge.Framework = 'qbox'

function Bridge.Notify(msg, nType)
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
    -- Typically handled via illenium-appearance or other appearance systems.
end
