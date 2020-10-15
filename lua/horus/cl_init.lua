include('cl_autocomplete.lua')

-- Shared files
include("sh_auth.lua")

-- Handle storage of local permissions
net.Receive('horus_sendperms', function()
    local commandinfo = net.ReadTable()
    horus.ranks = net.ReadTable()

    -- We reassemble the commands we know clientside
    -- This is a lot more secure than having everyone know everything
    horus.commands = {}
    horus.myperms = {}
    for _, v in pairs(commandinfo) do
        local perm = v[1]

        -- Precalculate argument names for faster autocomplete
        local names = {}
        for _, arg in pairs(v[2]) do
            local split = string.Split(arg, ":")
            table.insert(names, split[#split])
        end

        horus.commands[perm] = {
            args = v[2],
            names = names,
            help = v[3]
        }
        table.insert(horus.myperms, perm)
    end

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
    local silent = net.ReadBool()
    local new = {}

    -- Add a silent tag if command silent
    if silent then
        table.insert(new, horus.colors.orange)
        table.insert(new, '(silent) ')
        table.insert(new, color_white)
    end
    
    -- Handle argument display
    for k,v in pairs(msg) do
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

net.Receive('horus_error', function()
    chat.AddText(unpack(net.ReadTable()))
end)