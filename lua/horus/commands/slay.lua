horus.command('slay', 'Eliminate a player', {'player_one'}, function(caller, target)
	if target:Alive() then
		target:Kill()
	end
	return true, '%c killed %1'
end)

horus.command('explode', 'Detonate a player', {'player_one'}, function(caller, target)
	if target:Alive() then
		local boom = ents.Create('env_explosion')
		boom:SetPos( target:GetPos() )
		boom:Spawn()
		boom:SetKeyValue('iMagnitude', '150')
		boom:Fire('Explode')
		target:Kill()
	end

	return true, '%c exploded %1'
end)