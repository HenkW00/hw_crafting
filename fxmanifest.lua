fx_version 'adamant'
game 'gta5'
lua54 'yes'

ui_page 'html/ui.html'

author 'HenkW'
description 'Simple crafting system'
version '1.2.2'


client_scripts {
    'client/main.lua',
    'config.lua',
}

server_scripts {
    'config.lua',
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua',
    'server/version.lua',
}

files {
    'html/ui.html',
    'html/css/main.css',
    'html/js/app.js',
}

escrow_ignore {
    'config.lua',
    'fxmanifest.lua',
}

shared_script '@es_extended/imports.lua'