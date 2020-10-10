horus.handlers = {}
horus.handlers["player_one"] = function(arg, caller)
    local res = {}
    if arg == "" then
        return false, "No target specified"
    elseif arg == "^" then
        -- Use ^ as shorthand for self-inflicted commands
        res = {caller}
    elseif string.StartWith(arg, "steam_0:") then
        -- Find players with specific steam ID
        local p = player.GetBySteamID(arg)
        if p then
            res = {p}
        else
            return false, "SteamID not found"
        end
    else
        -- Find all players with names matching the argument
        for k,v in pairs(player.GetAll()) do
            if string.find(v:Nick():lower(), arg:lower()) then
                table.insert(res, v)
            end
        end
    end

    -- Check validity of arguments
    if #res == 0 then return false, "No matching player found" end
    if #res > 1 then return false, "More than one player matched!" end
    if !horus:cantarget(caller, res[1]) then return false, "You cannot target that player!" end
    return res[1]
end

function horus:runcmd(cmd, caller, args, silent)
    if !horus.commands[cmd] then return false end
    local params = horus.commands[cmd].args

    -- First things first: Check player access and arguments
    if !horus:permission(caller, cmd) then caller:ChatPrint("You do not have permission to use this command!") return false end

    -- Handle all parameters safely
    local handled = {}
    for i=1, #params do
        local p = params[i]
        local r, err
        if horus.handlers[p] then
            r, err = horus.handlers[p](args[i] or "", caller)
            if err then horus:senderror(caller, err) end
            if !r then return end
        else
            r = args[i]
        end
        table.insert(handled, r)
    end

    -- Result string substitution
    -- This is unpleasant code I know I'm sorry
    local success, msg = horus.commands[cmd].func(caller, unpack(handled))
    if success and msg then
        msg = string.Explode(" ", msg)
        for k,v in pairs(msg) do
            if v == "%c" then
                msg[k] = caller
            elseif string.StartWith(v, "%") then
                local n = tonumber(string.sub(v, 2))
                msg[k] = handled[n]
            else
                msg[k] = " " .. v .. " "
            end
        end

        net.Start("horus_message")
        net.WriteEntity(caller)
        net.WriteTable(msg)
        net.WriteBool(silent)

        -- Broadcast to all players
        if silent then
            net.Send(caller)
        else
            net.Broadcast()
        end
    elseif msg then
        caller:ChatPrint(msg)
    end
end

function horus:senderror(ply, text)
    local msg = {horus.colors.orange, text}
    net.Start("horus_error")
    net.WriteTable(msg)
    net.Send(ply)
end

net.Receive("horus_command", function(len, ply)
    local args = net.ReadTable(args)
    local silent = net.ReadBool()
    local caller = ply
    local cmd = args[1]
    table.remove(args, 1)

    horus:runcmd(cmd, caller, args, silent)
end)

hook.Add("PlayerSay", "Horus_ChatCommand", function(ply, txt, team)
    if txt:sub(1, 1) == "!" then
        txt = txt:sub(2)
        local args = horus:split(txt)
        local cmd = args[1]
        table.remove(args, 1)

        -- Run the command if it exists
        if horus.commands[cmd] then
            horus:runcmd(cmd, ply, args, team)
            return false
        end
    end
end)