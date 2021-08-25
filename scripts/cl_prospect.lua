local prospecting_location = vector3(1580.9, 6592.204, 13.84828)
local area_size = 100.0
local prospecting = false

RegisterNetEvent("qb-prospecting:usedetector")
AddEventHandler("qb-prospecting:usedetector", function()
    local pos = GetEntityCoords(PlayerPedId())

    -- Make sure the player is within the prospecting zone before they start
    local dist = #(pos - prospecting_location)
    if dist < area_size then
        if not prospecting then
            TriggerServerEvent("qb-prospecting:activateProspecting")
            prospecting = true
        else
            TriggerEvent("prospecting:forceStop")
            prospecting = false
        end
    end
end, false)
