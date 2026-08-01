--- Sail compatibility shim: stock ps-dispatch expects QBCore + PlayerData globals.
--- Loaded first via fxmanifest. Real data comes from ps_lib Sail client bridge.

local JOB_TYPES = {
    police = 'leo',
    ambulance = 'ems',
}

local function buildPlayerData()
    local cid = LocalPlayer.state.sailCharacterId
    local jobName = tostring(LocalPlayer.state.sailJob or 'unemployed')
    local grade = math.floor(tonumber(LocalPlayer.state.sailJobGrade) or 0)
    local onDuty = LocalPlayer.state.sailJobDuty == true
    local stage = LocalPlayer.state.sailDeathStage

    local charinfo = {
        firstname = 'Unknown',
        lastname = '',
        gender = 0,
        birthdate = '1990-01-01',
        phone = '',
    }

    if GetResourceState('database') == 'started' then
        local ok, ch = pcall(function()
            return exports.database:GetCharacter()
        end)
        if ok and type(ch) == 'table' then
            charinfo.firstname = tostring(ch.firstName or ch.first_name or 'Unknown')
            charinfo.lastname = tostring(ch.lastName or ch.last_name or '')
            local g = tostring(ch.gender or 'male'):lower()
            charinfo.gender = (g == 'female' or g == 'f' or g == '1') and 1 or 0
            if ch.dateOfBirth or ch.date_of_birth then
                charinfo.birthdate = tostring(ch.dateOfBirth or ch.date_of_birth)
            end
        end
    end

    if GetResourceState('sail_jobs') == 'started' then
        local ok, job = pcall(function()
            return exports.sail_jobs:GetJob()
        end)
        if ok and type(job) == 'table' then
            jobName = tostring(job.name or jobName)
            grade = math.floor(tonumber(job.grade) or grade)
            onDuty = job.onDuty == true
        end
    end

    return {
        citizenid = cid and tostring(cid) or nil,
        charinfo = charinfo,
        job = {
            name = jobName,
            label = tostring(LocalPlayer.state.sailJobLabel or jobName),
            type = JOB_TYPES[jobName] or 'none',
            onduty = onDuty,
            isboss = false,
            grade = {
                level = grade,
                name = tostring(LocalPlayer.state.sailJobGradeLabel or ''),
            },
        },
        metadata = {
            callsign = nil,
            ishandcuffed = false,
            isdead = stage == 'dead' or stage == 'bleedout',
            inlaststand = stage == 'down',
        },
    }
end

PlayerData = buildPlayerData()

QBCore = {
    Functions = {
        GetPlayerData = function()
            PlayerData = buildPlayerData()
            return PlayerData
        end,
        HasItem = function(item)
            if GetResourceState('ox_inventory') ~= 'started' then return false end
            local count = exports.ox_inventory:Search('count', item)
            return (tonumber(count) or 0) > 0
        end,
        GetPlayer = function()
            return {
                PlayerData = QBCore.Functions.GetPlayerData(),
            }
        end,
    },
    Shared = {
        Vehicles = {},
        Weapons = {},
        Items = {},
    },
}

CreateThread(function()
    while true do
        PlayerData = buildPlayerData()
        Wait(2000)
    end
end)

RegisterNetEvent('sail_jobs:sync', function()
    PlayerData = buildPlayerData()
end)
