horus.config.database = {}

local config = horus.config.database
include('db_config.lua')

-- Configuration of tables to use
-- TODO: Lua code to build these if they don't already exist?
config.tables = {}
config.tables.bans = 'horus_bans'
config.tables.users = 'horus_users'
config.tables.ranks = 'horus_ranks'
config.tables.perms = 'horus_perms'
config.tables.notes = 'horus_notes'

hook.Add('DatabaseConnection', 'Horus_CreateTables', function(db)
    local transaction = db:createTransaction()

    -- Add queries here
    
    function transaction:onSuccess()
        -- Tables are built!
        hook.Call('HorusPostTables', nil)
    end

    function transaction:onError()
        Error('Horus tables could not be initialised')
    end
    transaction:start()
end)