local config = horus.config.database
horus.ranks = horus.ranks or {}

-- Make sure that the "user" and "root" ranks always exist
horus.ranks["user"] = {ismod = false, isadmin = false, issuper = false, perms = {}, global = true}
horus.ranks["root"] = {ismod = true, isadmin = true, issuper = true, perms = {}, global = true}

-- Given a player or rank, check if the target has the given permission
-- This is a recursive function pls be careful
function horus:permission(target, perm)
    if type(target) == "Player" then
        -- Get the rank of the player and check with that
        local rank = target:GetUserGroup()
        return horus:permission(rank, perm)
    elseif type(target) == "string" then
        if target == "root" then
            return true -- Root always has permission
        elseif !horus.ranks[target] then
            ErrorNoHalt("[Horus] Invalid permission target")
            return false
        else
            -- Check if the rank has permission for this
            if horus.ranks[target].perms then
                if horus.ranks[target].perms[perm] then return true end
            end

            -- Check rank inheritance
            if horus.ranks[horus.ranks[target].inherits] and target != "user" then
                return horus:permission(horus.ranks[target].inherits, perm)
            end

            -- Doesn't have the permission and does not inherit any furhter
            return false
        end
    else
        ErrorNoHalt("[Horus] Invalid permission target")
        return false
    end
end

function horus:cantarget(caller, target)
    if type(target) == "Player" then
        -- Use the rank of the target
        target = target:GetUserGroup()
    end

    if type(caller) == "Player" then
        -- Run the function with the rank of the player
        local rank = caller:GetUserGroup()
        return horus:cantarget(rank, target)
    elseif type(target) == "string" then
        if caller == "root" then
            return true
        elseif !horus.ranks[target] or !horus.ranks[caller] then
            ErrorNoHalt("[Horus] Invalid permission target")
            return false
        else
            if caller == target then return true end    -- Players of the same rank can target each other
            if target == "root" then return false end   -- Root cannot be targeted
            if target == "user" then return true end    -- User can be targeted
            if caller == "user" then return false end   -- Users are the bottom of the food chain

            -- Check down the hierarchy
            if horus.ranks[caller].inherits == target then
                return true
            else
                return horus:cantarget(horus.ranks[caller].inherits, target)
            end
        end
    end
end

-- Return a table with every permission a given target has
-- This goes through inherited ranks
function horus:allperms(target)
    if type(target) == "Player" then
        local rank = target:GetUserGroup()
        return horus:allperms(rank)
    elseif type(target) == "string" then
        if target == "root" then
            -- Root has all permissions
            return table.GetKeys(horus.commands)
        elseif !horus.ranks[target] then
            ErrorNoHalt("[Horus] Invalid permission target")
            return {}
        else
            -- Loop through this rank and all inherits to build the table
            if horus.ranks[horus.ranks[target].inherits] then
                return table.Add(table.GetKeys(horus.ranks[target].perms), horus:allperms(horus.ranks[target].inherits))
            else
                return table.GetKeys(horus.ranks[target].perms) or {}
            end
        end
    else
        ErrorNoHalt("[Horus] Invalid permission target")
        return {}
    end
end

-- Get all staff
function horus:getstaff(level)
    if not level then level = 0 end

    local res = {}
    for _, v in pairs(player.GetAll()) do
        local rank = v:GetUserGroup()
        if level <= 0 and horus.ranks[rank].ismod then table.insert(res, v) continue end
        if level <= 1 and horus.ranks[rank].isadmin then table.insert(res, v) continue end
        if level <= 2 and horus.ranks[rank].issuper then table.insert(res, v) continue end
    end
    return res
end

-- Update the rank of a player
function horus:setrank(ply, rank)
    if !horus.ranks[rank] then return end
    if !IsValid(ply) then return end
    if !ply:IsPlayer() then return end
    if ply:IsBot() then return end

    -- Store this into the database
    horus_sql:RunPreparedQuery("SetPlayerRank", nil, ply:SteamID64(), rank, horus.config.serverid)

    -- Network
    ply:SetUserGroup(rank)
    horus:sendperms(ply, rank)
end

-- Create a new rank
function horus:createrank(rank, inherits)
    -- Don't create ranks that already exist
    if horus.ranks[rank] then return end

    -- We have to inherit from something
    if not horus.ranks[inherits] then return end

    -- Add it to our local table
    -- All flags init to false by default
    horus.ranks[rank] = {ismod = false, isadmin = false, issuper = false, perms = {}, global = false, inherits = inherits}

    -- Save to database
    horus_sql:RunPreparedQuery("CreateRank", nil, rank, inherits, 0, 0, 0, horus.config.serverid)
end

-- Set a rank
function horus:deleterank(rank)
    -- We can't delete a rank that doesn't exist
    if not horus.ranks[rank] then return end

    -- We can't delete global ranks
    if horus.ranks[rank].global then return end

    -- Delete locally
    horus.ranks[rank] = nil

    -- Save to database
    horus_sql:RunPreparedQuery("DeleteRank", rank, horus.config.serverid)
end

-- Get more useful information about a command
function horus:commandinfo(perm)
    local command = horus.commands[perm]
    if not command then return end

    return {perm, command.args, command.help}
end

-- Build a client command table
function horus:commandtable(perms)
    local res = {}
    for _,v in pairs(perms) do
        local info = horus:commandinfo(v)
        if info then
            table.insert(res, info)
        end
    end
    return res
end

-- Send permissions info to clients
function horus:sendperms(ply, rank, isadmin, issuper)
    if !IsValid(ply) then return end
    if !ply:IsPlayer() then return end
    if ply:IsBot() then return end

    -- hi my name is Robert and I love edge cases
    local rank_table = {}
    if type(rank) == "string" then
        rank_table = horus:commandtable(horus:allperms(rank))
    elseif type(rank) == "table" then
        rank_table = horus:commandtable(rank)
    end
    
    -- Not sure why these parameters are important
    if !isadmin or !issuper then
        isadmin = horus.ranks[rank].isadmin
        issuper = horus.ranks[rank].issuper
    end

    -- Build client ranks table if it doesn't already exist
    -- This is basically the server ranks table but with stripped out permissions
    -- The user knows their own permissions - they don't need to know other details
    local client_ranks = {}
    for k,v in pairs(horus.ranks) do
        client_ranks[k] = {}
        client_ranks[k].inherits = v.inherits or nil
        client_ranks[k].isadmin = v.isadmin or false
        client_ranks[k].issuper = v.issuper or false
    end

    -- Send all this information to the client
    net.Start("horus_sendperms")
        net.WriteTable(rank_table)
        net.WriteTable(client_ranks)
        net.WriteBool(isadmin)
        net.WriteBool(issuper)
    net.Send(ply)
end

-- On database connection, prepare the rank queries
hook.Add("HorusDatabaseConnected", "Horus_CreatePlayerRankQueries", function()
    -- Load from DB
    horus_sql:CreatePreparedQuery("LoadPlayerRank", "SELECT * FROM horus_users WHERE steamid64 = ? AND (server = ? OR server = 'global')")
    horus_sql:CreatePreparedQuery("SetPlayerRank", "INSERT INTO horus_users VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE rank = VALUES(rank)")
    
    horus_sql:CreatePreparedQuery("CreateRank", "INSERT INTO horus_ranks VALUES (?, ?, ?, ?, ?, ?)")
    horus_sql:CreatePreparedQuery("DeleteRank", "DELETE FROM horus_ranks WHERE rank = ? AND server = ?")
    horus_sql:CreatePreparedQuery("UpdateRankFlags", "UPDATE horus_ranks SET ismod=?, isadmin=?, issuper=? WHERE rank = ? AND server = ?")
    horus_sql:CreatePreparedQuery("UpdateRankInherits", "UPDATE horus_ranks SET inherits=? WHERE rank = ? AND server = ?")
end)