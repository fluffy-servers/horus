local handlers = {}
handlers['player_one'] = function(arg, caller)
    local res = {}
    print(arg)
    if arg == '^' then
        res = {caller}
    else
        for k,v in pairs(player.GetAll()) do
            print(v:Nick():lower(), arg)
            if string.find(v:Nick():lower(), arg) then
                table.insert(res, v)
            end
        end
    end

    print(res)

    if #res == 0 then return false, 'No matching player found' end
    if #res > 1 then return false, 'More than one player matched!' end
    if !horus:cantarget(caller, res[1]) then return false, 'You cannot target that player!' end
    return res[1]
end

function horus:runcmd(cmd, caller, args, silent)
    if !horus.commands[cmd] then return false end
    local params = horus.commands[cmd].args

    -- First things first: Check player access and arguments
    if !horus:permission(caller, cmd) then caller:ChatPrint('You do not have permission to use this command!') return false end

    -- Handle all parameters safely
    local handled = {}
    for i=1, #params do
        local p = params[i]
        local r, err
        if handlers[p] then
            r, err = handlers[p](args[i], caller)
            if err then caller:ChatPrint(err) end
            if !r then return end
        else
            r = args[i]
        end
        table.insert(handled, r)
    end

    -- WTF is this code
    local success, msg = horus.commands[cmd].func(caller, unpack(handled))
    if success and msg then
        msg = string.Explode(' ', msg)
        for k,v in pairs(msg) do
            if v == '%c' then
                msg[k] = caller
            elseif string.StartWith(v, '%') then
                local n =tonumber(string.sub(v, 2))
                msg[k] = handled[n]
            else
                msg[k] = ' ' .. v .. ' '
            end
        end

        net.Start('horus_message')
        net.WriteEntity(caller)
        net.WriteTable(msg)
        net.Broadcast()
    elseif msg then
        caller:ChatPrint(msg)
    end
end

net.Receive('horus_command', function(len, ply)
    local args = net.ReadTable(args)
    local caller = ply
    local cmd = args[1]
    table.remove(args, 1)

    horus:runcmd(cmd, caller, args, false)
end)

hook.Add('PlayerSay', 'Horus_ChatCommand', function(ply, txt, team)
    print('Testing Horus commands')
    if txt:sub(1, 1) == '!' then
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