fx_version 'cerulean'
game 'gta5'

author 'Kalajiqta - Matrix Development'
description 'QBCore Graffiti'
version '1.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    '@qbx_core/modules/playerdata.lua', -- For QBOX users
    'client/framework.lua',
    'client/client_main.lua',
    'client/client_functions.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/server_main.lua',
    'server/server_functions.lua'
}

lua54 'yes'