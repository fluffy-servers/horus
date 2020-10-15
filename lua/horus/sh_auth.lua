local meta = FindMetaTable("Player")

function meta:IsMod()
    local rank = self:GetUserGroup()
    if not horus.ranks[rank] then return false end
    return horus.ranks[rank].ismod
end

function meta:IsAdmin()
    local rank = self:GetUserGroup()
    if not horus.ranks[rank] then return false end
    return horus.ranks[rank].isadmin
end

function meta:IsSuperAdmin()
    local rank = self:GetUserGroup()
    if not horus.ranks[rank] then return false end
    return horus.ranks[rank].issuper
end