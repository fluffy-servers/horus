include('sv_database.lua')
--include('sv_logging.lua')
include('sv_parser.lua')
include('sv_ranks.lua')

util.AddNetworkString('horus_sendperms')
util.AddNetworkString('horus_command')
util.AddNetworkString('horus_message')
util.AddNetworkString('horus_menu')