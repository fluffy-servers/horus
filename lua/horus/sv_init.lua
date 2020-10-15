include('sv_sql.lua')
--include('sv_logging.lua')
include('sv_parser.lua')
include('sv_ranks.lua')
include('sv_discord.lua')

-- Shared files
AddCSLuaFile("sh_auth.lua")
include("sh_auth.lua")

util.AddNetworkString('horus_sendperms')
util.AddNetworkString('horus_command')
util.AddNetworkString('horus_message')
util.AddNetworkString('horus_error')
util.AddNetworkString('horus_menu')