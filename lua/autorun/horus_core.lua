horus = horus or {}
horus.config = horus.config or {}
horus.commands = horus.commands or {}
horus.colors = {
    -- todo
}

-- Command registration function
function horus.command(name, help, args, func)
    horus.commands[name] = {args = args, func = func, help = help}
end

-- Load the client/server init files
-- This file acts as a basic shared init
if SERVER then
    AddCSLuaFile('horus/cl_init.lua')
    include('horus/sv_init.lua')
else
    include('horus/cl_init.lua')
end