horus.autocompletes = {}

horus.autocompletes['player_one'] = function(arg)
    local res = {}
    for k,v in pairs(player.GetAll()) do
        if string.find(v:Nick():lower() or '?', arg) then
            table.insert(res, '"' .. v:Nick() .. '"')
        end
    end
    return res
end
horus.autocompletes['player_many'] = horus.autocompletes['player_one']

function horus.consolecomplete(base, str)
    if SERVER then return end
    if !horus.myperms then return end

    -- Cleanup and split the string
    str = string.Trim(str)
    str = string.lower(str)
    local args = horus:split(str)
    local tbl = {}

    -- First argument should be the name of the command
    if #args == 0 then
        -- List all commands
        for k,v in pairs(horus.myperms) do
            table.insert(tbl, 'horus ' .. v)
        end
    elseif #args == 1 then
        -- List all matching commands
        local c = args[1]
        local l = #args[1]
        for k,v in pairs(horus.myperms) do
            if string.find(v, c) then
                table.insert(tbl, 'horus ' .. v)
            end
        end
    else
        -- Handle argument processing
        local base = 'horus '
        for i=1,#args-1 do base = base .. args[i] .. ' ' end

        local cmd = args[1]:lower()
        if !horus.commands[cmd] then return end
        cmd = horus.commands[cmd]

        -- Autocomplete arguments
        local p = cmd.args[#args - 1]
        if horus.autocompletes[p] then
            local results = horus.autocompletes[p](args[#args])
            for k,v in pairs(results) do
                table.insert(tbl, base .. v)
            end
        end
    end

    return tbl
end

local function command(ply, cmd, args, str)
    net.Start('horus_command')
        net.WriteTable(args)
        net.WriteBool(false)
    net.SendToServer()
end
concommand.Add('hor', command, horus.consolecomplete, nil, FCVAR_USERINFO)

local function command_silent(ply, cmd, args, str)
    net.Start('horus_command')
        net.WriteTable(args)
        net.WriteBool(true)
    net.SendToServer()
end
concommand.Add('hor_silent', command_silent, horus.consolecomplete, nil, FCVAR_USERINFO)