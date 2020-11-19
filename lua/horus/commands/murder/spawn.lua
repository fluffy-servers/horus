horus.command("physgun", "Give yourself a physgun", {}, function(caller)
    caller:Give("weapon_physgun")
    return false, " gave themselves a physgun"
end)

horus.command("spawngun", "Spawn a new magnum", {}, function(caller)
    local ent = ents.Create("weapon_mu_magnum")
    ent:SetPos(caller:GetEyeTrace().HitPos + Vector(0, 0, 25))
    ent:Spawn()
    ent:Activate()
    return false, " spawned a new gun"
end)