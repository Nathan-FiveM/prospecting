local locations = {
    {
        x = 1600.185, y = 6622.714, z = 15.85106,
        data = {
            item = "lockpick",
        }
    },
    {
        x = 1548.082, y = 6633.096, z = 2.377085,
        data = {
            item = "advancedlockpick",
        }
    },
    {
        x = 1504.235, y = 6579.784, z = 4.365892,
        data = {
            item = "10kgoldchain",
            valuable = true,
        }
    },
    {
        x = 1580.016, y = 6547.394, z = 15.96557,
        data = {
            item = "10kgoldchain",
            valuable = true,
        }
    },
    {
        x = 1634.586, y = 6596.688, z = 22.55633,
        data = {
            item = "lockpick",
        }
    },
}

local item_pool = {
    {item = "lockpick", valuable = false},
    {item = "advancedlockpick", valuable = false},
    {item = "10kgoldchain", valuable = true},
    {item = "10kgoldchain", valuable = true},
    {item = "lockpick", valuable = false},
}

-- Area to create targets within, matches the client side blips
local base_location = vector3(1580.9, 6592.204, 13.84828)
local area_size = 100.0

-- Choose a random item from the item_pool list
function GetNewRandomItem()
    local item = item_pool[math.random(#item_pool)]
    return {item = item.item, valuable = item.valuable}
end

-- Make a random location within the area
function GetNewRandomLocation()
    local offsetX = math.random(-area_size, area_size)
    local offsetY = math.random(-area_size, area_size)
    local pos = vector3(offsetX, offsetY, 0.0)
    if #(pos) > area_size then
        -- It's not within the circle, generate a new one instead
        return GetNewRandomLocation()
    end
    return base_location + pos
end

-- Generate a new target location
function GenerateNewTarget()
    local newPos = GetNewRandomLocation()
    local newData = GetNewRandomItem()
    Prospecting.AddTarget(newPos.x, newPos.y, newPos.z, newData)
end

RegisterServerEvent("qb-prospecting:activateProspecting")
AddEventHandler("qb-prospecting:activateProspecting", function()
    local player = source
    Prospecting.StartProspecting(player)
end)

CreateThread(function()
    -- Default difficulty
    Prospecting.SetDifficulty(1.0)

    -- Add a list of targets
    -- Each target needs an x, y, z and data entry
    Prospecting.AddTargets(locations)

    -- Generate 10 random extra targets
    for n = 0, 10 do
        GenerateNewTarget()
    end

    -- The player collected something
    Prospecting.SetHandler(function(player, data, x, y, z)
        local src = player
        local Player = QBCore.Functions.GetPlayer(src)
        local amount = math.random(1,5)
        -- Check if the item is valuable, which is a part of the data we pass when creating it!
        if data.valuable then
            TriggerClientEvent('QBCore:Notify', src, "You found " .. data.item .. "!", 'success')   
            Player.Functions.AddItem(data.item, amount)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[data.item], 'add')
        else
            TriggerClientEvent('QBCore:Notify', src, "You found " .. data.item .. "!", 'success')   
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[data.item], 'add')
            Player.Functions.AddItem(data.item, amount)
        end
        -- Every time a
        GenerateNewTarget()
    end)

    -- The player started prospecting
    Prospecting.OnStart(function(player)
        TriggerClientEvent('QBCore:Notify', player, "Started prospecting", 'success') 
    end)

    -- The player stopped prospecting
    -- time in milliseconds
    Prospecting.OnStop(function(player, time)
        TriggerClientEvent('QBCore:Notify', player, "Stopped prospecting", 'error') 
    end)
end)

QBCore.Functions.CreateUseableItem('metaldetector', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('qb-prospecting:usedetector', source)
end)