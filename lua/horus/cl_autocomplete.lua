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
horus.autocompletes['player_any'] = horus.autocompletes['player_one']
horus.autocompletes['player_many'] = horus.autocompletes['player_one']

horus.autocompletes['boolean'] = function(arg)
    return {"true", "false"}
end

function horus.consolecomplete(base, str, nospace)
    if SERVER then return end
    if !horus.myperms then return {} end

    -- Cleanup and split the string
    str = string.Trim(str)
    str = string.lower(str)
    if not nospace then
        base = base .. ' '
    end
    local args = horus:split(str)
    local tbl = {}

    -- First argument should be the name of the command
    if #args == 0 then
        -- List all commands
        for k,v in pairs(horus.myperms) do
            table.insert(tbl, base .. v)
        end
    elseif #args == 1 then
        -- List all matching commands
        local c = args[1]
        local l = #args[1]
        for k,v in pairs(horus.myperms) do
            if string.find(v, c) then
                table.insert(tbl, base .. v)
            end
        end
    else
        -- Handle argument processing
        for i=1,#args-1 do base = base .. args[i] .. ' ' end

        local cmd = args[1]:lower()
        if !horus.commands[cmd] then return end
        cmd = horus.commands[cmd]

        -- Autocomplete arguments
        local p = cmd.args[#args - 1]
        p = string.Split(p, ":")[1]
        if horus.autocompletes[p] then
            local results = horus.autocompletes[p](args[#args])
            for k,v in pairs(results) do
                table.insert(tbl, base .. v)
            end
        end
    end

    return tbl
end

-- Similar to the above, but with additional help text
function horus.helptext(base, str, nospace)
    if !horus.myperms then return {} end

    -- Cleanup and split the string
    str = string.Trim(str)
    str = string.lower(str)
    if not nospace then
        base = base .. ' '
    end
    local args = horus:split(str)
    local tbl = {}

    if #args == 1 then
        -- List all matching commands
        local c = args[1]
        local l = #args[1]
        for k,v in pairs(horus.myperms) do
            if string.find(v, c) then
                table.insert(tbl, base .. v)
            end
        end

        -- If we only have one command, display helptext for it!
        if #tbl == 1 then
            local command = string.sub(tbl[1], 2)
            if horus.commands[command] then
                local names = horus.commands[command].names
                local str = tbl[1]
                for _, name in pairs(names) do
                    str = str .. " <" .. name .. ">"
                end

                return {str}
            end
        end
    end

    return horus.consolecomplete(base, str, nospace)
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

-- Autocomplete but for chatboxes
hook.Add("StartChat", "HorusOpenChat", function()
    horus.chatOpen = true
end)

hook.Add("FinishChat", "HorusCloseChat", function()
    horus.chatOpen = false
    horus.chatSuggestions = nil
end)

hook.Add("OnChatTab", "HorusChatAutocomplete", function(str)
    local autocompletes = horus.consolecomplete("!", str, true)
    if string.Left(str, 1) == "!" and autocompletes and #autocompletes >= 1 then
        return autocompletes[1]
    end
end)

hook.Add("ChatTextChanged", "HorusSuggestions", function(str)
    if string.Left(str, 1) == '!' then
        str = string.sub(str, 2)
        horus.chatSuggestions = horus.helptext("!", str, true)
    end
end)

local function drawSuggestionText(text, x, y)
    draw.SimpleText(text, 'ChatFont', x+1, y+1, Color(0, 0, 0, 100))
    draw.SimpleText(text, 'ChatFont', x+2, y+2, Color(0, 0, 0, 50))
    draw.SimpleText(text, 'ChatFont', x, y, color_white)
end

hook.Add("HUDPaint", "HorusDrawSuggestions", function()
    if chat and horus.chatOpen and horus.chatSuggestions then
        -- Adjust positioning
        local cx, cy = chat.GetChatBoxPos()
        cx = cx + 32
        cy = cy + 4 + ScrH() * 0.25

        -- Draw suggestions underneath chat
        surface.SetFont('ChatFont')
        for _,v in pairs(horus.chatSuggestions) do
            local tx, ty = surface.GetTextSize(v)
            drawSuggestionText(v, cx, cy)
            cy = cy + ty
        end
    end
end)