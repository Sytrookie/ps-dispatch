--- ps-dispatch server (Sail).
--- Active calls are session-scoped (GlobalState rehydrate on resource restart).
--- Attach/detach identity is always Player(src).state.sailCharacterId.

local calls = {}
local callCount = 0

local STATE_CALLS = 'psDispatchCalls'
local STATE_COUNT = 'psDispatchCallCount'

local function characterIdOf(src)
    src = tonumber(src)
    if not src then return nil end
    local cid = Player(src).state.sailCharacterId
    if cid == nil or cid == '' then return nil end
    return tostring(cid)
end

local function persistSession()
    -- Session-only: survives resource restart, not full FXServer reboot (documented in SAIL.md).
    GlobalState:set(STATE_CALLS, calls, false)
    GlobalState:set(STATE_COUNT, callCount, false)
end

local function rehydrateSession()
    local bag = GlobalState[STATE_CALLS]
    local count = GlobalState[STATE_COUNT]
    if type(bag) == 'table' then
        calls = bag
        callCount = math.floor(tonumber(count) or #calls)
        print(('[ps-dispatch] rehydrated %s session call(s)'):format(#calls))
    end
end

local function unitFromSource(src, clientPlayer)
    local cid = characterIdOf(src)
    if not cid then return nil end

    local unit = {
        citizenid = cid,
        source = src,
        charinfo = {
            firstname = 'Unknown',
            lastname = '',
        },
        job = {
            name = 'unemployed',
            type = 'none',
            label = 'Unemployed',
        },
        metadata = {
            callsign = nil,
        },
    }

    -- Prefer authoritative client snapshot for name/job/callsign display, but never trust citizenid.
    if type(clientPlayer) == 'table' then
        if type(clientPlayer.charinfo) == 'table' then
            unit.charinfo.firstname = tostring(clientPlayer.charinfo.firstname or unit.charinfo.firstname)
            unit.charinfo.lastname = tostring(clientPlayer.charinfo.lastname or '')
        end
        if type(clientPlayer.job) == 'table' then
            unit.job.name = tostring(clientPlayer.job.name or unit.job.name)
            unit.job.type = tostring(clientPlayer.job.type or unit.job.type)
            unit.job.label = tostring(clientPlayer.job.label or unit.job.label)
        end
        if type(clientPlayer.metadata) == 'table' and clientPlayer.metadata.callsign then
            unit.metadata.callsign = tostring(clientPlayer.metadata.callsign)
        end
    end

    -- Callsign from MDT profiles / players metadata when available
    if not unit.metadata.callsign then
        local ok, row = pcall(function()
            return MySQL.single.await(
                'SELECT callsign FROM mdt_profiles WHERE citizenid = ? LIMIT 1',
                { cid }
            )
        end)
        if ok and row and row.callsign and row.callsign ~= '' then
            unit.metadata.callsign = tostring(row.callsign)
        end
    end

    if not unit.metadata.callsign then
        local ok, row = pcall(function()
            return MySQL.single.await(
                'SELECT metadata FROM players WHERE citizenid = ? LIMIT 1',
                { cid }
            )
        end)
        if ok and row and row.metadata and row.metadata ~= '' then
            local decOk, meta = pcall(json.decode, row.metadata)
            if decOk and type(meta) == 'table' and meta.callsign then
                unit.metadata.callsign = tostring(meta.callsign)
            end
        end
    end

    return unit
end

-- Functions
exports('GetDispatchCalls', function()
    return calls
end)

-- Events
RegisterServerEvent('ps-dispatch:server:notify', function(data)
    if type(data) ~= 'table' then return end

    callCount = callCount + 1
    data.id = callCount
    data.time = os.time() * 1000
    data.units = {}
    data.responses = {}

    if #calls > 0 then
        if calls[#calls] == data then
            return
        end
    end

    if #calls >= Config.MaxCallList then
        table.remove(calls, 1)
    end

    calls[#calls + 1] = data
    persistSession()

    TriggerClientEvent('ps-dispatch:client:notify', -1, data)
end)

RegisterServerEvent('ps-dispatch:server:attach', function(id, player)
    local src = source
    local unit = unitFromSource(src, player)
    if not unit then return end

    id = tonumber(id)
    if not id then return end

    for i = 1, #calls do
        if calls[i]['id'] == id then
            for j = 1, #calls[i]['units'] do
                if calls[i]['units'][j]['citizenid'] == unit.citizenid then
                    return
                end
            end
            calls[i]['units'][#calls[i]['units'] + 1] = unit
            persistSession()
            return
        end
    end
end)

RegisterServerEvent('ps-dispatch:server:detach', function(id, player)
    local src = source
    local cid = characterIdOf(src)
    if not cid then return end

    id = tonumber(id)
    if not id then return end

    for i = #calls, 1, -1 do
        if calls[i]['id'] == id then
            if calls[i]['units'] and (#calls[i]['units'] or 0) > 0 then
                for j = #calls[i]['units'], 1, -1 do
                    if calls[i]['units'][j]['citizenid'] == cid then
                        table.remove(calls[i]['units'], j)
                    end
                end
            end
            persistSession()
            return
        end
    end
end)

-- Callbacks
lib.callback.register('ps-dispatch:callback:getLatestDispatch', function(source)
    return calls[#calls]
end)

lib.callback.register('ps-dispatch:callback:getCalls', function(source)
    return calls
end)

lib.callback.register('ps-dispatch:callback:getCallsign', function(source)
    local unit = unitFromSource(source, nil)
    return unit and unit.metadata and unit.metadata.callsign or nil
end)

-- Commands
lib.addCommand('dispatch', {
    help = locale('open_dispatch')
}, function(source, raw)
    TriggerClientEvent("ps-dispatch:client:openMenu", source, calls)
end)

lib.addCommand('911', {
    help = 'Send a message to 911',
    params = { { name = 'message', type = 'string', help = '911 Message' }},
}, function(source, args, raw)
    local fullMessage = raw:sub(5)
    TriggerClientEvent('ps-dispatch:client:sendEmergencyMsg', source, fullMessage, "911", false)
end)
lib.addCommand('911a', {
    help = 'Send an anonymous message to 911',
    params = { { name = 'message', type = 'string', help = '911 Message' }},
}, function(source, args, raw)
    local fullMessage = raw:sub(5)
    TriggerClientEvent('ps-dispatch:client:sendEmergencyMsg', source, fullMessage, "911", true)
end)

lib.addCommand('311', {
    help = 'Send a message to 311',
    params = { { name = 'message', type = 'string', help = '311 Message' }},
}, function(source, args, raw)
    local fullMessage = raw:sub(5)
    TriggerClientEvent('ps-dispatch:client:sendEmergencyMsg', source, fullMessage, "311", false)
end)

lib.addCommand('311a', {
    help = 'Send an anonymous message to 311',
    params = { { name = 'message', type = 'string', help = '311 Message' }},
}, function(source, args, raw)
    local fullMessage = raw:sub(5)
    TriggerClientEvent('ps-dispatch:client:sendEmergencyMsg', source, fullMessage, "311", true)
end)

CreateThread(function()
    Wait(100)
    rehydrateSession()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    persistSession()
end)
