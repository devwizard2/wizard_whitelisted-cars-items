local ESX = nil
local playerJob = "unemployed"

local weaponJobRestrictions = {
    [`weapon_pistol`] = { "police", "sheriff" }, -- allowed jobs
    [`weapon_smg`] = { "police" },
    -- add more weapons and allowed jobs here
}

local vehicleJobRestrictions = {
    [GetHashKey("ndds63")] = { "police", "sheriff" },
    [GetHashKey("police2")] = { "police" },
    -- add more vehicles and allowed jobs here
}

local function isJobAllowed(job, allowedJobs)
    for _, allowedJob in ipairs(allowedJobs) do
        if job == allowedJob then
            return true
        end
    end
    return false
end

CreateThread(function()
    while ESX == nil do
        ESX = exports["es_extended"]:getSharedObject()
        Wait(100)
    end

    while not ESX.IsPlayerLoaded() do Wait(100) end

    local playerData = ESX.GetPlayerData()
    if playerData and playerData.job and playerData.job.name then
        playerJob = playerData.job.name
    else
        playerJob = "unemployed"
    end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    if job and job.name then
        playerJob = job.name
    else
        playerJob = "unemployed"
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)

        if weaponJobRestrictions[weapon] then
            if not isJobAllowed(playerJob, weaponJobRestrictions[weapon]) then
                -- Disable shooting controls
                DisableControlAction(0, 24, true)  -- Attack
                DisableControlAction(0, 25, true)  -- Aim
                DisableControlAction(0, 142, true) -- Melee
                DisableControlAction(0, 106, true) -- Vehicle attack

                -- Force unarmed
                if weapon ~= `weapon_unarmed` then
                    SetCurrentPedWeapon(ped, `weapon_unarmed`, true)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()

        if not IsPedInAnyVehicle(ped, false) then
            if IsControlJustPressed(0, 23) or IsControlJustPressed(0, 75) then -- enter vehicle keys
                local veh = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 70)
                if veh ~= 0 then
                    local model = GetEntityModel(veh)
                    if vehicleJobRestrictions[model] and not isJobAllowed(playerJob, vehicleJobRestrictions[model]) then
                        ClearPedTasks(ped) -- stop entering
                    end
                end
            end
        else
            local veh = GetVehiclePedIsIn(ped, false)
            local model = GetEntityModel(veh)
            if vehicleJobRestrictions[model] and not isJobAllowed(playerJob, vehicleJobRestrictions[model]) then
                if GetPedInVehicleSeat(veh, -1) == ped then
                    TaskLeaveVehicle(ped, veh, 0)
                end
            end
        end
    end
end)
