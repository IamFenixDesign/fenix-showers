local CURRENT = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or "0.0.0"

local GITHUB_VERSION    = "https://raw.githubusercontent.com/IamFenixDesign/version/refs/heads/main/shower/shower-version.txt"
local GITHUB_CHANGELOG  = "https://raw.githubusercontent.com/IamFenixDesign/version/refs/heads/main/shower/shower-changelog.txt"

-- Cleans spaces, line breaks, and BOM if present
local function cleanText(str)
    if not str then return nil end
    str = str:gsub("\239\187\191", "") -- BOM
    return str:gsub("%s+", "")
end

-- Display changelog in server console
local function showChangelog()
    PerformHttpRequest(GITHUB_CHANGELOG, function(status, body)
        if status == 200 and body and body ~= "" then
            print("^3----- CHANGELOG -----^0")
            print(body)
            print("^3----------------------^0")
        else
            print("^1[fenix-shower]^0 Failed to retrieve remote changelog.")
        end
    end, "GET")
end

-- Version check
CreateThread(function()

    PerformHttpRequest(GITHUB_VERSION, function(status, body)

        if status ~= 200 or not body then
            print("^1[fenix-shower]^0 Failed to check for updates on GitHub.")
            return
        end

        local latest  = cleanText(body)
        local current = cleanText(CURRENT)

        if not latest then
            print("^1[fenix-shower]^0 Remote version file is invalid.")
            return
        end

        if latest ~= current then
            print(("^3[fenix-shower]^0 New version available: ^2%s^0 (current: ^1%s^0)"):format(latest, current or "unknown"))
            print("^3Download on Github: https://github.com/IamFenixDesign/fenix-showers^0")

            -- Only show changelog when version does NOT match
            showChangelog()
        else
            print(("^2[fenix-shower]^0 You are running the latest version (%s)"):format(current))
        end
    end, "GET")
end)
