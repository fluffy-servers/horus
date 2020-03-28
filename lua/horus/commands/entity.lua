horus.command('entity', 'Spawn an entity', {'string'}, function(caller, class)
    local pos = caller:GetEyeTrace().HitPos
    local ent = ents.Create(class)
    if not IsValid(ent) then return false, 'Invalid entity!'
    ent:SetPos(pos)
    ent:Spawn()

	return true, '%c spawned %1'
end)