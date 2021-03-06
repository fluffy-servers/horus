horus = horus or {}
horus.config = horus.config or {}
horus.commands = horus.commands or {}

-- Colors!
horus.colors = {
    ["orange"] = Color(255, 140, 0),
	["blue"] = Color(0, 140, 255)
}

-- Command registration function
function horus.command(name, help, args, func)
    horus.commands[name] = {args = args, func = func, help = help}
end

-- Load the default and gamemode commands
function horus:loadCommands(root)
	horus:loadCommandFiles("horus/" .. root .. "/")

	if GAMEMODE.IsMinigames then
		horus:loadCommandFiles("horus/" .. root .. "/minigames/")
	end
	horus:loadCommandFiles("horus/" .. root .. "/" .. GAMEMODE_NAME .. "/")
end

-- Load all commands in a given file path
function horus:loadCommandFiles(path)
	local files = file.Find(path .. "*.lua", "LUA")
	if not files then return end

	for k,v in pairs(files) do
		if SERVER then AddCSLuaFile(path .. v) end
		include(path .. v)
	end
end

-- Fix this it's awful
function horus:split(str)
    --str = str:lower()
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
	AddCSLuaFile("horus/cl_init.lua")
	AddCSLuaFile("horus/cl_autocomplete.lua")

    include("horus/sv_init.lua")
else
    include("horus/cl_init.lua")
end

hook.Add("OnGamemodeLoaded", "LoadHorusCommands", function()
	if CLIENT then 
		horus:loadCommands("client")
	else
		horus:loadCommands("commands")
	end
end)