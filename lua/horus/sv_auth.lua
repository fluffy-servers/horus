-- Remove default stuff
hook.Remove("PlayerInitialSpawn", "PlayerAuthSpawn")

local function AuthenticateUser(data)
    if #data < 1 then return end 

    -- Global rank takes precedence
    local row = data[1]
    if #data == 2 then
        if data[1].server ~= "global" then
            row = data[2]
        end
    end

    -- Apply the rank
    local ply = player.GetBySteamID64(row.steamid64)
    if not ply then return end
    horus:setrank(ply, row.rank)
end

-- Load ranks on player connection
hook.Add("PlayerInitialSpawn", "Horus_SendRank", function(ply)
    -- Bots shouldn't have permissions - have you seen Terminator??
    if ply:IsBot() then
        ply:SetUserGroup("user")
        return
    end

    -- Listen server hosts get full perms by default
    if ply:IsListenServerHost() then
        ply:SetUserGroup("root")
        horus:sendperms(ply, "root")
        return
    end

    -- Attempt to load permissions from the database
    horus_sql:RunPreparedQuery("LoadPlayerRank", AuthenticateUser, ply:SteamID64(), horus.config.serverid)

    -- Attempt to load permissions from the database
    ply:SetUserGroup("user")
    horus:sendperms(ply, "user")
end)

local function LoadPerms(data)
    for _, perm in pairs(data) do
        if not horus.ranks[perm.rank] then continue end
        horus.ranks[perm.rank].perms[perm.perm] = true
    end
end

local function LoadRanks(data)
    for _, rank in pairs(data) do
        local ismod = rank.ismod == 1
        local isadmin = rank.isadmin == 1
        local issuper = rank.issuper == 1
        horus.ranks[rank.rank] = {ismod = ismod, isadmin = isadmin, issuper = issuper, perms = {}, inherits=rank.inherits}

        -- Mark global ranks as such so we don't alter them too badly
        if rank.server == "global" then
            horus.ranks[rank.rank].global = true
        end
    end

    -- Now that the ranks table is created, fetch the permissions from the database
    horus_sql:RunPreparedQuery("LoadPerms", LoadPerms, horus.config.serverid)
end

-- On database connection, load all the rank data locally
hook.Add("HorusDatabaseConnected", "Horus_LoadRanks", function()
    -- Load from DB
    horus_sql:CreatePreparedQuery("LoadRanks", "SELECT * FROM horus_ranks WHERE server = ? OR server = 'global'")
    horus_sql:CreatePreparedQuery("LoadPerms", "SELECT * FROM horus_perms WHERE server = ? OR server = 'global'")
    horus_sql:RunPreparedQuery("LoadRanks", LoadRanks, horus.config.serverid)
end)