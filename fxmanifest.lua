name 'Prospecting Example'
author 'glitchdetector'
editor 'Nathan#8860'
contact 'Nathan#8860'

fx_version 'cerulean'
game 'gta5'

description 'QB-Prospecting'

shared_script '@qb-core/import.lua'
server_script 'interface.lua'

client_script 'scripts/cl_*.lua'
server_script 'scripts/sv_*.lua'

file 'stream/gen_w_am_metaldetector.ytyp'

server_exports {
    'AddProspectingTarget', -- x, y, z, data
    'AddProspectingTargets', -- list
    'StartProspecting', -- player
    'StopProspecting', -- player
    'IsProspecting', -- player
    'SetDifficulty', -- modifier
}