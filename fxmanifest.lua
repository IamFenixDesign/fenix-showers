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
    'client/cl_main.lua'
}

server_scripts {
    'server/version.lua'
}

lua54 'yes'

