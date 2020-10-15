horus.command("rcon", "Run a given command in server console", {"string"}, function(caller, cmd)
	game.ConsoleCommand(cmd .. "\n")
	return true, "%c ran command %1 on the server"
end)

horus.command("lua", "Run a given Lua script on the server", {"string"}, function(caller, cmd)
	RunString(cmd)
	return true, "%c ran Lua code"
end)