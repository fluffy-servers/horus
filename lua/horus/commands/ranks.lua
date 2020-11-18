horus.command("userrank", "Set the rank of a given user", {"player_one:player", "rank"}, function(caller, target, rank)
    if target:GetUserGroup() == rank then
        return false, "Target is already that rank"
    end
    
    horus:setrank(target, rank)
end)