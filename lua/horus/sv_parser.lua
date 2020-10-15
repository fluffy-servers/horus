horus.handlers = {}

-- Helper functions!
-- Check if the argument matches a player by ID
local function checkIDTarget(arg, caller)
    -- this is a weird edge case please ignore
    if arg:lower() == "bot" then return end

    -- Check for standard SteamID
    local p = player.GetBySteamID(arg)
    if p and IsValid(p) then return {p} end

    -- Check for SteamID64
    p = player.GetBySteamID64(arg)
    if p and IsValid(p) then return {p} end

    -- Check for standard ID
    if string.StartWith(arg, "$") then
        local id = tonumber(string.sub(arg, 2))
        if id ~= nil then
            p = player.GetByID(id)
            if p and IsValid(p) then return {p} end
        end
    end

    return false
end

-- Find all targetable players
local function findAllTargetablePlayers(arg, caller)
    -- Find all targetable players with names that match
    local res = {}
    for k,v in pairs(player.GetAll()) do
        if string.find(v:Nick():lower(), arg:lower(), 1, true) and horus:cantarget(caller, v) then
            table.insert(res, v)
        end
    end

    return res
end

-- Check if this is a self-target
local function checkSpecialTargets(arg, caller)
    if arg == "^" then return {caller} end
    if arg == "*" then return findAllTargetablePlayers("", caller) end
    return false
end

-- Check a table of players to ensure that they can all be targeted
local function checkCanTargetTableOfPlayers(tbl, caller)
    for k,v in pairs(tbl) do
        if not v or not v:IsPlayer() then return false end
        if not horus:cantarget(caller, v) then return false end
    end
    return true
end

-- Return a single player
horus.handlers["player_one"] = function(arg, caller)
    local res
    if arg == "" then
        return false, "No target specified"
    end

    -- Run helper functions to find a target
    if not res then res = checkSpecialTargets(arg, caller) end
    if not res then res = checkIDTarget(arg, caller) end
    if not res then res = findAllTargetablePlayers(arg, caller) end

    -- Verify validity
    if #res == 0 then return false, "No matching player found" end
    if #res > 1 then return false, "More than one player matched!" end
    if !horus:cantarget(caller, res[1]) then return false, "You cannot target that player!" end
    return res[1]
end

-- Same as the above, but skips permission check
horus.handlers["player_any"] = function(arg, caller)
    local res
    if arg == "" then
        return false, "No target specified"
    end

    -- Run helper functions to find a target
    if not res then res = checkSpecialTargets(arg, caller) end
    if not res then res = checkIDTarget(arg, caller) end
    if not res then res = findAllTargetablePlayers(arg, caller) end

    -- Verify validity
    if #res == 0 then return false, "No matching player found" end
    if #res > 1 then return false, "More than one player matched!" end
    return res[1]
end

-- Return a table of players
horus.handlers["player_many"] = function(arg, caller)
    local res
    if arg == "" then
        return false, "No target specified"
    end

    -- Engage safety mode with !, check single player case
    if string.StartWith(arg, "!") then
        return horus.handlers["player_one"](string.sub(arg, 2), caller)
    end

    -- Run helper functions to find a target
    if not res then res = checkSpecialTargets(arg, caller) end
    if not res then res = checkIDTarget(arg, caller) end
    if not res then res = findAllTargetablePlayers(arg, caller) end

    -- Verify validity
    if #res == 0 then return false, "No matching players found" end
    if !checkCanTargetTableOfPlayers(res, caller) then return false, "Targeting error!" end
    return res
end

horus.handlers["boolean"] = function(arg, caller)
    if not arg or arg == "" then return nil, false end
    if arg == "0" or arg == "f" or arg == "false" then return false, false end
    return true, false
end

function horus:runcmd(cmd, caller, args, silent)
    if !horus.commands[cmd] then return false end
    local params = horus.commands[cmd].args

    -- First things first: Check player access and arguments
    if !horus:permission(caller, cmd) then caller:ChatPrint("You do not have permission to use this command!") return false end

    -- Handle all parameters safely
    local handled = {}
    for i=1, #params do
        local p = string.Split(params[i], ":")[1]
        local r, err
        if horus.handlers[p] then
            r, err = horus.handlers[p](args[i] or "", caller)
            if err then horus:senderror(caller, err) end
            if p ~= "boolean" and !r then return end
        else
            r = args[i]
        end
        table.insert(handled, r)
    end

    -- If there's any "extra" arguments and the last thing was a string, wack em on
    if #args > #params then
        if params[#params] == "string" then
            for i=#params+1, #args do
                handled[#handled] = handled[#handled] .. " " .. args[i]
            end
        end
    end

    -- Result string substitution
    -- This is unpleasant code I know I'm sorry
    local success, msg = horus.commands[cmd].func(caller, unpack(handled))
    if success and msg then
        local i = 1
        local res = {}
        msg = string.Explode(" ", msg)
        for k,v in pairs(msg) do
            if v == "%c" then
                if i > 1 then
                    i = i + 1
                end
                res[i] = caller
                i = i + 1
            elseif string.StartWith(v, "%") then
                local n = tonumber(string.sub(v, 2))
                if i > 1 then
                    i = i + 2
                end
                res[i-1] = horus.colors.blue
                res[i] = handled[n]
                res[i+1] = color_white
                i = i + 2
            else
                res[i] = (res[i] or " ") .. v .. " "
            end
        end

        net.Start("horus_message")
        net.WriteEntity(caller)
        net.WriteTable(res)
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