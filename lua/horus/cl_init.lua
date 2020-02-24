-- Handle storage of local permissions
net.Receive('horus_sendperms', function()
    horus.myperms = net.ReadTable()
    horus.ranks = net.ReadTable()
    LocalPlayer().perms = horus.myperms
    LocalPlayer().isadmin = net.ReadBool()
    LocalPlayer().issuper = net.ReadBool()
end)

-- Formatting list of players
local function handle_player_table(t)
    local ret = {}
    for k,v in pairs(t) do
        table.insert(ret, v)
        table.insert(ret, color_white)
        if k == #t - 1 then
            table.insert(ret, ' and ')
        elseif k != #t then
            table.insert(ret, ', ')
        end
    end

    return ret
end

-- Handle display of chat messages
net.Receive('horus_message', function()
    local caller = net.ReadEntity()
    local msg = net.ReadTable()
    local new = {}
    for k,v in pairs(msg) do
        if type(v) == 'string' then
            table.insert(new, color_white)
        end

        if type(v) == 'table' then
            if type(v[1]) == 'Player' then
                table.Add(new, handle_player_table(v))
            else
                table.Add(new, v)
            end
        end

        table.insert(new, v)
    end
    
    chat.AddText(unpack(new))
end)