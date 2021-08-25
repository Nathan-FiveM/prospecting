function EnsureAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end
function EnsureModel(model)
    if not IsModelInCdimage(model) then

    else
        if not HasModelLoaded(model) then
            RequestModel(model)
        	while not HasModelLoaded(model) do
        		Wait(0)
        	end
    	end
	end
end

local previousAnim = nil
function StopAnim(ped)
    if previousAnim then
        StopEntityAnim(ped, previousAnim[2], previousAnim[1], true)
        previousAnim = nil
    end
end
function PlayAnimFlags(ped, dict, anim, flags)
    StopAnim(ped)
    EnsureAnimDict(dict)
    local len = GetAnimDuration(dict, anim)
    TaskPlayAnim(ped, dict, anim, 1.0, -1.0, len, flags, 1, 0, 0, 0)
    previousAnim = {dict, anim}
end

function PlayAnimUpper(ped, dict, anim)
    PlayAnimFlags(ped, dict, anim, 49)
end
function PlayAnim(ped, dict, anim)
    PlayAnimFlags(ped, dict, anim, 0)
end

local targetPool = {
    {vector3(1600.185, 6622.714, 15.85106), 1.0},
}

local maxTargetRange = 200.0
local targets = {}


RegisterNetEvent("prospecting:setTargetPool")
AddEventHandler("prospecting:setTargetPool", function(pool)
    targetPool = {}
    for n, pos in next, pool do
        targetPool[n] = {vector3(pos[1], pos[2], pos[3]), pos[4], n}
    end
end)

local isProspecting = false
local pauseProspecting = false
local didCancelProspecting = false
local scannerState = "none"
local scannerFrametime = 0.0
local scannerScale = 0.0
local scannerAudio = true

local entityOffsets = {
    ["w_am_digiscanner"] = {
		bone = 18905,
        offset = vector3(0.15, 0.1, 0.0),
        rotation = vector3(270.0, 90.0, 80.0),
	},
    -- cant get the fucking model to be standalone so im replacing the digiscanner
    -- nobody uses it anyways so w/e
    ["w_am_metaldetector"] = {
		bone = 18905,
        offset = vector3(0.15, 0.1, 0.0),
        rotation = vector3(270.0, 90.0, 80.0),
	},
    -- original digiscanner stuff
    -- ["w_am_digiscanner"] = {
	-- 	bone = 57005,
    --     offset = vector3(0.1, 0.1, 0.0),
    --     rotation = vector3(270.0, 90.0, 90.0),
	-- },
}

local attachedEntities = {}
local scannerEntity = nil
function AttachEntity(ped, model)
    if entityOffsets[model] then
        EnsureModel(model)
        local pos = GetEntityCoords(PlayerPedId())
    	local ent = CreateObjectNoOffset(model, pos, 1, 1, 0)
    	AttachEntityToEntity(ent, ped, GetPedBoneIndex(ped, entityOffsets[model].bone), entityOffsets[model].offset, entityOffsets[model].rotation, 1, 1, 0, 0, 2, 1)
        scannerEntity = ent
        table.insert(attachedEntities, ent)
    end
end

function CleanupModels()
    for _, ent in next, attachedEntities do
        DetachEntity(ent, 0, 0)
        DeleteEntity(ent)
    end
    attachedEntities = {}
    scannerEntity = nil
end

--[[ function DigSequence(cb)
    CleanupModels()
        local ped = PlayerPedId()
        StopEntityAnim(ped, "wood_idle_a", "mini@golfai", true)
        PlayAnim(ped, "amb@world_human_gardener_plant@male@enter", "enter")
        Wait(100)
        while IsEntityPlayingAnim(ped, "amb@world_human_gardener_plant@male@enter", "enter", 3) do
            Wait(0)
        end
        PlayAnim(ped, "amb@world_human_gardener_plant@male@base", "base")
        Wait(100)
        while IsEntityPlayingAnim(ped, "amb@world_human_gardener_plant@male@base", "base", 3) do
            Wait(0)
        end
        if cb then cb() end
        PlayAnim(ped, "amb@world_human_gardener_plant@male@exit", "exit")
        Wait(100)
        while IsEntityPlayingAnim(ped, "amb@world_human_gardener_plant@male@exit", "exit", 3) do
            Wait(0)
        end
    AttachEntity(PlayerPedId(), "w_am_digiscanner")
end ]]

function DigSequence(cb)
    local ped = PlayerPedId()
    StopEntityAnim(ped, "wood_idle_a", "mini@golfai", true)
    Citizen.Wait(100)
    if not isPickingUp then
        isPickingUp = true
        Citizen.Wait(100)
        TaskStartScenarioInPlace(ped, 'world_human_gardener_plant', 0, false)
        QBCore.Functions.Progressbar("prospect_digging", "Digging...", math.random(3000, 9000), false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            ClearPedTasks(PlayerPedId())
            if cb then
                cb()
            end
            AttachEntity(PlayerPedId(), "w_am_digiscanner")
        end, function() -- Cancel
            ClearPedTasks(PlayerPedId())
            AttachEntity(PlayerPedId(), "w_am_digiscanner")
        end)
        isPickingUp = false
        AttachEntity(PlayerPedId(), "w_am_digiscanner")
    end
end

function getClosestTarget(pos)
    local closest, index, closestdist, difficulty
    for n, target in next, targets do
        local dist = #(pos.xy - target[1].xy)
        if (not closest) or closestdist > dist then
            closestdist = dist
            index = n
            closest = target
            difficulty = target[2]
        end
    end
    -- Return 0,0,0 if no targets
    return closest or vector3(0.0, 0.0, 0.0), closestdist, index, difficulty
end

function DigTarget(index)
    pauseProspecting = true
    local target = table.remove(targets, index)
    local pos = target[1]
    DigSequence(function()
        TriggerServerEvent("prospecting:userCollectedNode", index, pos.x, pos.y, pos.z)
    end)
    scannerState = "none"
    pauseProspecting = false
end

function StopProspecting()
    if not didCancelProspecting then
        didCancelProspecting = true
        CleanupModels()
        local ped = PlayerPedId()
        StopEntityAnim(ped, "wood_idle_a", "mini@golfai", true)
        circleScale = 0.0
        scannerScale = 0.0
        scannerState = "none"
        isProspecting = false
        TriggerServerEvent("prospecting:userStoppedProspecting")
    end
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        CleanupModels()
        StopProspecting()
    end
end)

function StartProspecting()
    if not isProspecting then
        ProspectingThreads()
    end
end

RegisterNetEvent("prospecting:forceStart")
AddEventHandler("prospecting:forceStart", function()
    StartProspecting()
end)
RegisterNetEvent("prospecting:forceStop")
AddEventHandler("prospecting:forceStop", function()
    isProspecting = false
end)

CreateThread(function()
    Wait(1000)
    -- init
    TriggerServerEvent("prospecting:userRequestsLocations")
end)

function ProspectingThreads()
    if IsProspecting then return false end
    TriggerServerEvent("prospecting:userStartedProspecting")
    isProspecting = true
    didCancelProspecting = false
    pauseProspecting = false

    -- Prospecting handler
    CreateThread(function()
        AttachEntity(PlayerPedId(), "w_am_digiscanner")
        while isProspecting do
            Wait(0)
            local ped = PlayerPedId()
            local ply = PlayerId()
            local canProspect = true
            if not IsEntityPlayingAnim(ped, "mini@golfai", "wood_idle_a", 3) then
                PlayAnimUpper(PlayerPedId(), "mini@golfai", "wood_idle_a")
            end

            -- Actions that halt prospecting animations and scanning
            local restrictedMovement = false
            restrictedMovement = restrictedMovement or IsPedFalling(ped)
            restrictedMovement = restrictedMovement or IsPedJumping(ped)
            restrictedMovement = restrictedMovement or IsPedSprinting(ped)
            restrictedMovement = restrictedMovement or IsPedRunning(ped)
            restrictedMovement = restrictedMovement or IsPlayerFreeAiming(ply)
            restrictedMovement = restrictedMovement or IsPedRagdoll(ped)
            restrictedMovement = restrictedMovement or IsPedInAnyVehicle(ped)
            restrictedMovement = restrictedMovement or IsPedInCover(ped)
            restrictedMovement = restrictedMovement or IsPedInMeleeCombat(ped)

            if restrictedMovement then canProspect = false end
            if canProspect then
                local pos = GetEntityCoords(ped) + vector3(GetEntityForwardX(ped) * 0.75, GetEntityForwardY(ped) * 0.75, -0.75)
                -- local pos = GetWorldPositionOfEntityBone(scannerEntity, 0)
                local target, dist, index, difficulyModifier = getClosestTarget(pos)
                if index then
                    local dist = dist * difficulyModifier
                    if dist < 3.0 then
                        if IsDisabledControlJustPressed(0, 54) then
                            DigTarget(index)
                        end
                    else
                        if IsDisabledControlJustPressed(0, 54) then
                            QBCore.Functions.Notify("You're too far away!", "error")
                        end
                    end
                    if dist < 3.0 then
                        circleScale = 0.0
                        scannerScale = 0.0
                        scannerState = "ultra"
                    elseif dist < 4.0 then
                        scannerFrametime = 0.35
                        scannerScale = 4.50
                        scannerState = "fast"
                    elseif dist < 5.0 then
                        scannerFrametime = 0.4
                        scannerScale = 3.75
                        scannerState = "fast"
                    elseif dist < 6.5 then
                        scannerFrametime = 0.425
                        scannerScale = 3.00
                        scannerState = "fast"
                    elseif dist < 7.5 then
                        scannerFrametime = 0.45
                        scannerScale = 2.50
                        scannerState = "fast"
                    elseif dist < 10.0 then
                        scannerFrametime = 0.5
                        scannerScale = 1.75
                        scannerState = "fast"
                    elseif dist < 12.5 then
                        scannerFrametime = 0.75
                        scannerScale = 1.25
                        scannerState = "medium"
                    elseif dist < 15.0 then
                        scannerFrametime = 1.0
                        scannerScale = 1.00
                        scannerState = "medium"
                    elseif dist < 20.0 then
                        scannerFrametime = 1.25
                        scannerScale = 0.875
                        scannerState = "medium"
                    elseif dist < 25.0 then
                        scannerFrametime = 1.5
                        scannerScale = 0.75
                        scannerState = "slow"
                    elseif dist < 30.0 then
                        scannerFrametime = 2.0
                        scannerScale = 0.5
                        scannerState = "slow"
                    else
                        circleScale = 0.0
                        scannerScale = 0.0
                        scannerState = "none"
                    end
                    scannerDistance = dist
                else
                    circleScale = 0.0
                    scannerScale = 0.0
                    scannerState = "none"
                end
            end
            if not canProspect then
                -- Ped is busy and can't prospect at this time (like falling or w/e)
                StopEntityAnim(ped, "wood_idle_a", "mini@golfai", true)
                circleScale = 0.0
                scannerScale = 0.0
                scannerState = "none"
            end
            if not isProspecting then
                -- We stopped prospecting mid-frame
                CleanupModels()
                StopEntityAnim(ped, "wood_idle_a", "mini@golfai", true)
                circleScale = 0.0
                scannerScale = 0.0
                scannerState = "none"
            end
        end
        StopProspecting()
    end)

    -- Marker rendering
    -- Audio
    CreateThread(function()
        local framecount = 0
        local frametime = 0
        local circleScale = 0.0
        local circleScaleMultiplier = 1.5
        local renderCircle = false
        while isProspecting do
            Wait(0)
            if not pauseProspecting then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped) + vector3(GetEntityForwardX(ped) * 0.75, GetEntityForwardY(ped) * 0.75, -0.75)
                -- local pos = GetWorldPositionOfEntityBone(scannerEntity, 0)
                if scannerState == "none" then
                    renderCircle = false
                elseif scannerState == "slow" then
                    renderCircle = true
                    circleScale = circleScale + scannerScale
                    if frametime > scannerFrametime then
                        frametime = 0.0
                    end
                    -- circleSize = (circleScale % 100) / 100
                    -- circleA = math.floor(255 - ((circleScale % 100) / 100) * 255)
                    -- DrawMarker(1, pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, circleSize, circleSize, 0.1, circleR, circleG, circleB, circleA)
                elseif scannerState == "medium" then
                    renderCircle = true
                    circleScale = circleScale + scannerScale
                    if frametime > scannerFrametime then
                        frametime = 0.0
                    end
                    -- circleSize = (circleScale % 100) / 100
                    -- circleA = math.floor(255 - ((circleScale % 100) / 100) * 255)
                    -- DrawMarker(1, pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, circleSize, circleSize, 0.1, circleR, circleG, circleB, circleA)
                elseif scannerState == "fast" then
                    renderCircle = true
                    circleScale = circleScale + scannerScale
                    if frametime > scannerFrametime then
                        frametime = 0.0
                    end
                elseif scannerState == "ultra" then
                    renderCircle = false
                    circleScale = circleScale + scannerScale
                    if frametime > 0.125 then
                        frametime = 0.0
                        if scannerAudio then PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0) end
                        -- PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 0)
                        if scannerAudio then PlaySoundFrontend(-1, "BOATS_PLANES_HELIS_BOOM", "MP_LOBBY_SOUNDS", 0) end
                    end
                end
                if renderCircle then
                    if circleScale > 100 then
                        while circleScale > 100 do
                            circleScale = circleScale - 100
                        end
                        if scannerAudio then PlaySoundFrontend(-1, "ATM_WINDOW", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0) end
                    end
                end

                framecount = (framecount + 1) % 120
                frametime = frametime + Timestep()
            end
        end
    end)

    -- Location updater
    -- Adds nearby targets to the target pool
    -- Prevents client from doing frame-checks on targets across the map
    CreateThread(function()
        while isProspecting do
            local pos = GetEntityCoords(PlayerPedId())
            local newTargets = {}
            for n, target in next, targetPool do
                if #(pos.xy - target[1].xy) < maxTargetRange then
                    newTargets[#newTargets + 1] = {target[1], target[2], n}
                end
            end
            targets = newTargets
            Wait(10000)
        end
    end)
    return true
end
