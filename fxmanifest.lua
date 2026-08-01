fx_version 'cerulean'

game "gta5"

author "Project Sloth & OK1ez"
version '2.2.2'

lua54 'yes'

ui_page 'html/index.html'
-- ui_page 'http://localhost:5173/' --for dev

client_script {
  -- Sail: stock used PolyZone; current code uses ox_lib zones only.
  -- Load Sail QBCore/PlayerData shim before other client scripts.
  'sail_bridge_client.lua',
  'client/**',
}
server_script {
  "server/**",
}
shared_script {
  "shared/**",
  '@ox_lib/init.lua',
}

files {
  'html/**',
  'locales/*.json',
}

ox_lib 'locale' -- v3.8.0 or above
