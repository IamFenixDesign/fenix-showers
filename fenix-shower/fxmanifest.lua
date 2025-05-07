fx_version 'cerulean'
game 'gta5'

author 'FenixDesign'
description 'Ducha con ropa temporal, target, partículas y sistema de ropa configurable'
version '1.1.0'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    -- Change depending on what you want
    -- 'qb-target',
    -- 'ox_target',
    -- 'illenium-appearance',
    -- 'qb-clothing'
}

lua54 'yes'

