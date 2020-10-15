require("mysqloo")
include("db_config.lua")

horus_sql = horus_sql or {}

-- Get a stored prepared query with the given ID
function horus_sql:GetPreparedQuery(id)
    if not self.PreparedQueries then return end
    return self.PreparedQueries[id]
end

-- Create a prepared query with the given ID
function horus_sql:CreatePreparedQuery(id, query)
    if not self.PreparedQueries then self.PreparedQueries = {} end
    if not self.PreparedQueries[id] then
        self.PreparedQueries[id] = db:prepare(query)
    end
    return self.PreparedQueries[id]
end

-- Run a prepared query
function horus_sql:RunPreparedQuery(id, callback, ...)
    local query = self:GetPreparedQuery(id)
    if not query then return end

    -- Set the arguments in the query
    for i,v in ipairs(arg) do
        if type(v) == "string" then
            q:setString(i, v)
        elseif type(v) == "number" then
            q:setNumber(i, v)
        end
    end

    function query:onSuccess(data)
        callback(data)
    end
    query:start()
    return query
end

-- Run a raw SQL query string
function horus_sql:RunRawQuery(string, callback)
    local query = self.Databse:query(string)

    function query:onSuccess(data)
        callback(data)
    end
    query:start()
    return query
end

-- Run a connection to the database
function horus_sql:GetConnection()
    if not self.Database then
        -- Start a new database connection
        local hsql = self
        local config = self.config
        local port = self.config.port or 3306
        self.Database = mysqloo.connect(config.host, config.username, config.password, config.database, port)
        self.Database:connect()

        function self.Database:onConnected()
            hsql:OnConnected()
        end

        function self.Database:onConnectionFailed(err)
            hsql:OnConnectionFailed(err)
        end

        return self.Database
    elseif self.Database:status() != mysqloo.DATABASE_CONNECTED then
        -- Attempt reconnection
        self.Database:connect()
        return self.Database
    else
        -- Everything is going smoothly
        return self.Database
    end
end

-- Handle a successful database connection
function horus_sql:OnConnected()
    self.Connected = true
    hook.Call("HorusDatabaseConnected", nil)
    hook.Call("HorusSetupQueries", nil)
end

-- Handle a failed database connection
function horus_sql:OnConnectionFailed(err)
    self.Connected = false
    ErrorNoHalt("[Horus] Could not connect to the database")
    hook.Call("HorusDatabaseConnectionFailed", nil, err)
end

-- Check if the database is currently connected
function horus_sql:IsConnected()
    return self.Connected
end

-- Immediately attempt to connect to the database
horus_sql:GetConnection()