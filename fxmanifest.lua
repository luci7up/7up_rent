fx_version 'cerulean'
game 'gta5'

author 'Squizer#3020'
description 'Script that allows you to borrow vehicles.'
version '1.0.0'

client_scripts {
    "@vrp/client/Proxy.lua",
"@vrp/client/Tunnel.lua",
    'warmenu.lua',
    'config.lua',
    'client.lua'
}

server_scripts {
    "@vrp/lib/utils.lua",
    'config.lua',
    'server.lua'
}