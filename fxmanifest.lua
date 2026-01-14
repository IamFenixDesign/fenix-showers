fx_version 'cerulean'
game 'gta5'

author 'FenixDesign'
description 'Shower script'
version '1.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'bridge/qb/client.lua',
    'bridge/esx/client.lua',
    'bridge/qbox/client.lua',
    'client/cl_main.lua'
}

server_scripts {
    'bridge/qb/server.lua',
    'bridge/esx/server.lua',
    'bridge/qbox/server.lua',
    'server/version.lua'
}

lua54 'yes'
