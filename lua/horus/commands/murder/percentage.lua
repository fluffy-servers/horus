horus.command("percentage", "Check the shooting percentage of a player", {"player_one:player"}, function(caller, target)
    if not target.MurderStats then return end
    
    local m = target.MurderStats['shot_murderer']
    local i = target.MurderStats['shot_innocent']
    local percent = math.floor(((m/m+1) or 0) * 100)
    caller:ChatPrint('Percentage of ' .. ply:Nick() .. ': ' .. percentage .. '%')
    caller:ChatPrint(m .. ' murderers shot | ' .. i .. ' innocents shot')
end)