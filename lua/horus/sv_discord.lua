horus.discordcolors = {
    red = 15221016,
    yellow = 16500017,
    purple = 10258687,
    blue = 43263,
    green = 5034295
}

function horus:discordlog(data, level)
    local url = horus.config.discord[level]

    local body = util.TableToJSON(data, true)
    local request = {
        method = "POST",
        url = url,
        body = body,
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = body:len() or "0"
        },
        type = "application/json"
    }
    HTTP(request)
end

function horus:discordSimple(message)
    return {
        ["content"] = message,
        ["username"] = "Horus - " .. horus.config.servername
    }
end

function horus:discordPunishEmbed(title, description, victim, caller, color)
    return {
        ["content"] = "",
        ["username"] = "Horus - " .. horus.config.servername,
        ["embeds"] = {{
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or horus.discordcolors['red'],
            ["author"] = {
                ["icon_url"] = 'https://fluffyservers.com/api/steam/avatar/' .. victim:SteamID64(),
                ["url"] = 'https://steamcommunity.com/profiles/' .. victim:SteamID64(),
                ["name"] = victim:Nick()
            },
            ["footer"] = {
                ["icon_url"] = 'https://fluffyservers.com/api/steam/avatar/' .. caller:SteamID64(),
                ["text"] = caller:Nick() .. ' (' .. caller:SteamID() .. ')'
            }
        }}
    }
end