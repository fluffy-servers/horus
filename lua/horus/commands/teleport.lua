horus.command('tp', 'Teleport a player to where you are looking', {'player_one'}, function(caller, target)
    local tr = util.TraceHull({
        start = caller:GetShootPos(),
        endpos = caller:GetShootPos() + caller:EyeAngles():Forward() * 4096,
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        filter = caller,
    })
    if not tr.HitPos then
        return false, 'No room!'
    end
    
    if target:Alive() then
        target:SetPos(tr.HitPos)
    else
        return false, 'Target is dead!'
    end
    
	return true, '%c teleported %1'
end)