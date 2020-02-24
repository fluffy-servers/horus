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

-- Load all the command plugins from the folder
function horus:loadCommands()
    local path = 'horus/commands/'

	local files, folders = file.Find(path .. '*.lua', 'LUA')
	for k,v in pairs(files) do
		if SERVER then AddCSLuaFile(path .. v) end
		include(path .. v)
	end
end

-- Fix this it's awful
function horus:split(str)
    str = str:lower()
	local tbl = {}
	
	-- Split the string arguments
    local quote = true
	for chunk in string.gmatch(str, '[^"]+') do	
		quote = not quote
		if quote then
			table.insert(tbl, chunk)
		else
			for chunk2 in string.gmatch(chunk, '%S+') do
				table.insert(tbl, chunk2)
			end
		end
	end
    
	return tbl
end

-- Load the client/server init files
-- This file acts as a basic shared init
if SERVER then
    AddCSLuaFile('horus/cl_init.lua')
    include('horus/sv_init.lua')
else
    include('horus/cl_init.lua')
end
horus:loadCommands()