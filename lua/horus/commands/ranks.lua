horus.command("userrank", "Set the rank of a given user", {"player_one:player", "rank:rank"}, function(caller, target, rank)
    if target:GetUserGroup() == rank then
        return false, "Target is already that rank"
    end
    
    horus:setrank(target, rank)
end)

horus.command("rankadd", "Create a new rank", {"string:name", "rank:inherits"}, function(caller, name, inherits)
    if horus.ranks[name] then return false, "New rank already exists!" end
    if not horus.ranks[inherits] then return false, "Inherited rank does not exist!" end
    
    horus:createrank(name, inherits)
end)

horus.command("rankremove", "Remove a rank", {"rank:rank"}, function(caller, rank)
    if horus.ranks[rank].global then
        return false, "Global ranks cannot be removed"
    end
    
    horus:deleterank(rank)
end)

horus.command("rankaddperm", "Add a permission to a rank", {"rank:rank", "permission:permission"}, function(caller, rank)

end)

horus.command("rankremoveperm", "Remove a permission from a rank", {"rank:rank", "permission:permission"}, function(caller, rank)

end)