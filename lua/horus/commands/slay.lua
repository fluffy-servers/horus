horus.command("slay", "Eliminate a player", {"player_many:players"}, function(caller, targets)
	for _,v in pairs(targets) do
		if v:Alive() then
			v:Kill()
		end
	end
	return true, "%c killed %1"
end)

horus.command("explode", "Detonate a player", {"player_one:player"}, function(caller, target)
	if target:Alive() then
		local boom = ents.Create("env_explosion")
		boom:SetPos( target:GetPos() )
		boom:Spawn()
		boom:SetKeyValue("iMagnitude", "150")
		boom:Fire("Explode")
		target:Kill()
        return true, "%c exploded %1"
	else
        return false, "Target is already dead!"
    end
end)