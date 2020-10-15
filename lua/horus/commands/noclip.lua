local function apply_noclip(ply, state)
    if state == nil then
        local noclipping = ply:GetMoveType() == MOVETYPE_NOCLIP
        ply:SetMoveType(noclipping and MOVETYPE_WALK or MOVETYPE_NOCLIP)
    else
        ply:SetMoveType(state and MOVETYPE_NOCLIP or MOVETYPE_WALK)
    end
end

horus.command("noclip", "Makes a player noclip.", {"player_many", "boolean"}, function(caller, targets, state)
    print(targets, state)
    for _, v in pairs(targets) do
        apply_noclip(v, state)
    end

    -- Output message based on state
    if state == nil then
        return true, "%c toggled noclip on %1"
    elseif state == false then
        return true, "%c disabled noclip on %1"
    else
        return true, "%c enabled noclip on %1"
    end
end)

-- If anyone has access to !noclip, they can noclip with V
hook.Add("PlayerNoClip", "horus_noclip", function(ply, state)
	if ply:GetMoveType() == MOVETYPE_NOCLIP then return true end
    
    return horus:permission(ply, "noclip")
end)