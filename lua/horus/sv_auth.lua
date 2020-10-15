-- Remove default stuff
hook.Remove("PlayerInitialSpawn", "PlayerAuthSpawn")

-- Load ranks on player connection
hook.Add("PlayerInitialSpawn", "Horus_SendRank", function(ply)
    -- Listen server hosts get full perms by default
    if ply:IsListenServerHost() then
        ply:SetUserGroup("root")
        horus:sendperms(ply, "root")
        return
    end

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
        horus.ranks[rank.rank] = {ismod = ismod, isadmin = isadmin, issuper = issuper, perms = {}}
    end

    -- Now that the ranks table is created, fetch the permissions from the database
    horus_sql:RunPreparedQuery("LoadPerms", LoadPerms, horus.config.serverid)
end

-- On database connection, load all the rank data locally
hook.Add("HorusDatabaseConnected", "Horus_LoadRanks", function()
    -- Load from DB
    horus_sql:CreatePreparedQuery("LoadRanks", "SELECT * FROM horus_ranks WHERE server = ? OR server = 'global'")
    horus_sql:CreatePreparedQuery("LoadPerms", "SELECT * FROM horus_perms WHERE server = ? OR server = 'global'")
    
    print("SERVER ID:", horus.config.serverid)
    horus_sql:RunPreparedQuery("LoadRanks", LoadRanks, horus.config.serverid)
end)