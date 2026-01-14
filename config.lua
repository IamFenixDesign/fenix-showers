Config = {}


-- Target config
Config.TargetSettings = {
    icon = "fas fa-shower",
    label = "Take a shower",
    namePrefix = "shower_zone_"
}

-- Progressbar and particles config
Config.Shower = {
    Duration = 15, -- seconds
    ProgressLabel = "Taking shower...",
    RestoreAnimation = {
        dict = "clothingtie", -- dict de animación
        anim = "try_tie_positive_a", -- nombre de la animación específica
        duration = 3 -- duración en segundos
    },
    IdleAnim = {
        dict = "mp_safehouseshower@male@", -- dict de animación idle
        anim = "male_shower_idle_d", -- nombre de la animación
    },
    Cooldown = 60, -- Time between showers
    ParticleInterval = 5.1 -- Time between particles reload (sync with actual duration)


-- Notify configuration
Config.Notifications = {
    Cooldown = {
        title = "Shower",
        message = "You already take a shower. Please wait",
        type = "error"
    },
    Finished = {
        title = "Shower",
        message = "You take a shower and know you smell pretty good",
        type = "success"
    }
}

-- Clothing during showers
Config.ShowerOutfits = {
    male = {
        ["t-shirt"] = { item = 15, texture = 0 },
        torso = { item = 15, texture = 0 },
        arms = { item = 15, texture = 0 },
        pants = { item = 14, texture = 0 },
        shoes = { item = 34, texture = 0 },
        mask = { item = -1, texture = 0 },
        bag = { item = 0, texture = 0 },
        vest = { item = 0, texture = 0 },
        accessory = { item = 0, texture = 0 },
        undershirt = { item = 15, texture = 0 },
        decals = { item = 0, texture = 0 },
        hat = { item = -1, texture = 0 },
        glasses = { item = -1, texture = 0 },
        ears = { item = -1, texture = 0 },
        watch = { item = -1, texture = 0 },
        bracelet = { item = -1, texture = 0 }
    },
    female = {
        ["t-shirt"] = { item = 14, texture = 0 },
        torso = { item = 629, texture = 0 },
        arms = { item = 376, texture = 0 },
        pants = { item = 69, texture = 0 },
        shoes = { item = 85, texture = 0 },
        mask = { item = 0, texture = 0 },
        bag = { item = 0, texture = 0 },
        vest = { item = 0, texture = 0 },
        accessory = { item = 0, texture = 0 },
        undershirt = { item = 0, texture = 0 },
        decals = { item = 0, texture = 0 },
        hat = { item = -1, texture = 0 },
        glasses = { item = -1, texture = 0 },
        ears = { item = -1, texture = 0 },
        watch = { item = -1, texture = 0 },
        bracelet = { item = -1, texture = }

-- Showers Locations -- duh
Config.ShowerLocations = {
    vector3(-767.04, 327.19, 170.97),
    vector3(254.65, -999.93, -99.01),
    vector3(346.89, -995.13, -100.11),
    vector3(-803.48, 335.74, 220.59),
    vector3(-32.47, -587.41, 82.95),
    vector3(-1453.75, -555.47, 71.88),
    vector3(-1461.38, -534.96, 49.77),
    vector3(-898.05, -368.57, 112.11),
    vector3(-591.71, 49.14, 96.04),
    vector3(-796.38, 333.36, 209.93),
    vector3(-168.89, 489.73, 132.87),
    vector3(335.91, 430.56, 145.6),
    vector3(373.9, 413.97, 141.13),
    vector3(-673.75, 588.4, 140.6),
    vector3(-765.49, 612.72, 139.36),
    vector3(-856.46, 682.36, 148.08),
    vector3(120.83, 551.01, 179.53),
    vector3(-1287.27, 440.41, 93.12)
}
