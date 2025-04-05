--MIT License

--Copyright (c) 2025 LawAus

--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:

--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.

--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.


--Reach out VIA discord @lawaus for any questions, concerns, or issues. Don't hesitate to contribute to the project with optimizations or fixing kinks. 
--I apologise for the lack of comments I just really cannot be bothered. 
--This is DNA version 1.0.0

-- Config List
local carList = ""

-- Local Variables
local clientPlayer = PlayerPedId()
local vehicle = ""

-- Main Vehicles List
local VehicleControlList = {}
local VehicleControlActivityDict = {}

-- Pursuit lightbar vehicles list
local VehicleControlPursuitSystemList = {}

-- Special case vehicles list
local VehicleControlUniqueList = {}

-- Main Function Sleep!
local sleep = 1000

function IsPedOperatingVehicle(playerID, vehicle)
    local driver = GetPedInVehicleSeat(vehicle, -1)
    return driver == playerID or driver == 0
end

function VerifyVehicleState(playerID, vehicle)
	return DoesEntityExist(vehicle) and IsPedOperatingVehicle(playerID, vehicle) and IsVehicleSirenOn(vehicle)
end

function VerifyVehicleStateLightReverse(playerID, vehicle)
	return DoesEntityExist(vehicle) and IsPedOperatingVehicle(playerID, vehicle)
end

function lightSyncSystem(vehicle, extraList)
	local active = true
	local lightSyncVehicle = vehicle
	local lightStateExtra = extraList
	local waitTime = 1000 -- This time is optimal for the lowest % usage and response time!

	if config.debug then
		print("LIGHT SYNC RAN FOR ",lightSyncVehicle)
	end

	while active do
		if VerifyVehicleState(clientPlayer, lightSyncVehicle) then
			local emptyNull, lightsOn, highBeamsOn = GetVehicleLightsState(lightSyncVehicle)
			for i, extra in ipairs(lightStateExtra) do
				local verify = (extra > 0 and (highBeamsOn == 0 and lightsOn == 0)) or (extra < 0 and (highBeamsOn == 1 or lightsOn == 1))
				if (IsVehicleExtraTurnedOn(lightSyncVehicle, math.abs(extra)) and 1 or 0) ~= (verify and 1 or 0) then
					if not IsControlPressed(0, 72) then
						SetVehicleAutoRepairDisabled(lightSyncVehicle, true)
						SetVehicleExtra(lightSyncVehicle, math.abs(extra), verify and 0 or 1)
						SetVehicleAutoRepairDisabled(lightSyncVehicle, false)
					end
				end
			end
		else 
			active = false
			VehicleControlActivityDict[lightSyncVehicle].lightSync = 0
		end
		Wait(waitTime)
	end

	if config.debug then
		print("LIGHT SYNC STOPPED FOR ",lightSyncVehicle)
	end
end

function brakeLightSystem(vehicle, extraList)
	local active = true
	local brakeVehicle = vehicle
	local lightStateExtra = extraList
	local waitTime = 267 -- This time is optimal for the lowest % usage and response time!
	
	if config.debug then
		print("BRAKE LIGHT RAN FOR ",brakeVehicle)
	end


	while active do
		if VerifyVehicleState(clientPlayer, brakeVehicle) then
			if IsControlPressed(0,72) then
				for i, extra in ipairs(lightStateExtra) do
					if not IsControlPressed(0, 72) then
						SetVehicleAutoRepairDisabled(brakeVehicle, true)
						SetVehicleExtra(brakeVehicle, extra, 1)
						SetVehicleAutoRepairDisabled(brakeVehicle, false)
					end				
				end
			end
		else
			active = false
			VehicleControlActivityDict[brakeVehicle].brakeSync = 0
		end
		Wait(waitTime)
	end
	
	if config.debug then
		print("BRAKE LIGHT STOPPED FOR ",brakeVehicle)
	end

end

function lightbarPatternSystem(vehicle, extraList)
	local active = true
	local lightbarVehicle = vehicle
	local lightStateExtra = extraList
	local cyclePattern = {}
	local waitTime = 1000 

	if config.debug then
		print("LIGHTBAR PATTERN SYSTEM RAN FOR ",lightbarVehicle)
	end

	for _, extra in ipairs(lightStateExtra) do
		if extra > 0 then
			table.insert(cyclePattern, extra)
		end
		if extra ~= 0 then
			local condition = not IsVehicleExtraTurnedOn(lightbarVehicle, math.abs(extra)) ~= ((extra < 0) and 1 or false)
			if condition then
				SetVehicleAutoRepairDisabled(lightbarVehicle, true)
				SetVehicleExtra(lightbarVehicle, math.abs(extra), (extra < 0) and 0 or 1)
				SetVehicleAutoRepairDisabled(lightbarVehicle, false)
			end
		end
	end


	local checkHornStatus = config.ConfigList[GetEntityModel(lightbarVehicle)].hornLighting

	table.sort(cyclePattern)
	if #cyclePattern > 1 then
		while active do -- Actual pattern cycle
			if checkHornStatus == nil or not (IsDisabledControlPressed(0, 86) or IsControlPressed(0, 86)) then
				waitTime = 1000
				if VerifyVehicleStateLightReverse(clientPlayer, lightbarVehicle) then
					local cycleTime = math.random(1200,5500)
					local lightbarState = math.random(cyclePattern[1],cyclePattern[#cyclePattern]) -- Determines random pattern choice for the cycle!

					if not IsVehicleExtraTurnedOn(lightbarVehicle, lightbarState) then
						SetVehicleAutoRepairDisabled(lightbarVehicle, true)
						SetVehicleExtra(lightbarVehicle, lightbarState, 0)
						SetVehicleAutoRepairDisabled(lightbarVehicle, false)
					end
					local lightbarStartTime = GetGameTimer()
					while math.abs(GetGameTimer() - lightbarStartTime) < cycleTime do
						Wait(500)
						if not VerifyVehicleStateLightReverse(clientPlayer, lightbarVehicle) then
							active = false
							cycleTime = 1
							
							VehicleControlActivityDict[lightbarVehicle].patternSync = 0
						end
					end
					if IsVehicleExtraTurnedOn(lightbarVehicle, lightbarState) == 1 then
						SetVehicleAutoRepairDisabled(lightbarVehicle, true)
						SetVehicleExtra(lightbarVehicle, lightbarState, 1)
						SetVehicleAutoRepairDisabled(lightbarVehicle, false)
					end
				else
					active = false
							
					VehicleControlActivityDict[lightbarVehicle].patternSync = 0
				end
			else
				waitTime = 100
				Wait(waitTime)
			end
		end
	elseif #cyclePattern == 1 then
		while active do
			if checkHornStatus == nil or not (IsDisabledControlPressed(0, 86) or IsControlPressed(0, 86)) then
				waitTime = 1000
				if VerifyVehicleState(clientPlayer, lightbarVehicle) then
					if IsVehicleExtraTurnedOn(lightbarVehicle, cyclePattern[1]) == false then
						SetVehicleAutoRepairDisabled(lightbarVehicle, true)
						SetVehicleExtra(lightbarVehicle, cyclePattern[1], 0)
						SetVehicleAutoRepairDisabled(lightbarVehicle, false)
					end
				else
					active = false
							
					VehicleControlActivityDict[lightbarVehicle].patternSync = 0
				end
			else
				waitTime = 100
			end
			Wait(waitTime)
		end
	else
		print("Critical Error on pattern cycle system. Pattern count less than 1!")
	end

	if config.debug then
		print("LIGHTBAR PATTERN SYSTEM STOPPED FOR ",lightbarVehicle)
	end

end

function hornLightSystem(vehicle, dictionary, patternList)

	local active = true

    local hornVehicle = vehicle
    local extraDict = dictionary
	local patternListSync = patternList
    local innerIndex = 0
    local fail = 0
    local waitTime = 100
    local delayStartTime = extraDict.startDelay[1] or 0

	if config.debug then
		print("HORN LIGHTING SYSTEM RAN FOR ",hornVehicle)
	end

    for _, table in ipairs(extraDict) do
        for _, data in ipairs(table) do
            if data > 0 and IsVehicleExtraTurnedOn(hornVehicle, data) then
				SetVehicleAutoRepairDisabled(hornVehicle, true)
				SetVehicleExtra(hornVehicle, data, 1)
				SetVehicleAutoRepairDisabled(hornVehicle, false)
			end
        end
    end

    while active do  
        if IsDisabledControlPressed(0, 86) or IsControlPressed(0, 86) then
			if VerifyVehicleState(clientPlayer, hornVehicle) and GetPedInVehicleSeat(hornVehicle,-1) == clientPlayer then
                local outerStartTime = GetGameTimer()
                while innerIndex == 0 and (GetGameTimer() - outerStartTime) < delayStartTime do
                    if not (IsDisabledControlPressed(0, 86) or IsControlPressed(0, 86)) then
                        fail = 1
                        break
                    end
                    Wait(50)
                end
                if innerIndex >= #extraDict then innerIndex = 0 end

                if fail == 0 then
                    innerIndex = innerIndex + 1
                    local extraA = extraDict[innerIndex][1]
                    local waitTimer = math.abs(extraDict[innerIndex][2])
                    local startTime = GetGameTimer()

					if patternListSync ~= nil then
						for i,dext in ipairs(patternListSync) do
                            if IsVehicleExtraTurnedOn(hornVehicle, math.abs(dext)) then
								SetVehicleAutoRepairDisabled(hornVehicle, true)
								SetVehicleExtra(hornVehicle, math.abs(dext), 1)
								SetVehicleAutoRepairDisabled(hornVehicle, false)
							end
						end
					end

                    while (GetGameTimer() - startTime < waitTimer) do
                        if IsDisabledControlPressed(0, 86) or IsControlPressed(0, 86) then
                            if not IsVehicleExtraTurnedOn(hornVehicle, extraA) then
								SetVehicleAutoRepairDisabled(hornVehicle, true)
								SetVehicleExtra(hornVehicle, extraA, 0)
								SetVehicleAutoRepairDisabled(hornVehicle, false)
							end
                        else
                            fail = 1
                            break
                        end
                        Wait(100)
                    end
                    if IsVehicleExtraTurnedOn(hornVehicle, extraA) then
						SetVehicleAutoRepairDisabled(hornVehicle, true)
						SetVehicleExtra(hornVehicle, extraA, 1)
						SetVehicleAutoRepairDisabled(hornVehicle, false)
					end
                end
                if fail == 1 then
                    delayStartTime = extraDict.startDelay[1] or 0
                    fail = 0
                end
            else
                innerIndex = 0
            end
		else
			innerIndex = 0
			if not VerifyVehicleState(clientPlayer, hornVehicle) then
				active = false
							
				VehicleControlActivityDict[hornVehicle].hornLightSync = 0
			end

        end
        Wait(waitTime)
    end

	if config.debug then
		print("HORN LIGHTING SYSTEM STOPPED FOR ",hornVehicle)
	end

end

function executeVehicleSystems(vehicle)
	local car = vehicle
    local vehicleModelName = GetEntityModel(car)

    if not config or not config.ConfigList or not config.ConfigList[vehicleModelName] then
        return
    end

    if VerifyVehicleState(clientPlayer, car) then
        if VehicleControlList[car] then
            if config.ConfigList[vehicleModelName].grillLights ~= nil then
                if VehicleControlActivityDict[car] and VehicleControlActivityDict[car].lightSync == 0 then
                    VehicleControlActivityDict[car].lightSync = 1
                    Citizen.CreateThread(function()
                        lightSyncSystem(car, config.ConfigList[vehicleModelName].grillLights)
                    end)
                end
            end
            if config.ConfigList[vehicleModelName].brakeLights ~= nil then
                if VehicleControlActivityDict[car] and VehicleControlActivityDict[car].brakeSync == 0 then
                    VehicleControlActivityDict[car].brakeSync = 1
                    Citizen.CreateThread(function()
                        brakeLightSystem(car, config.ConfigList[vehicleModelName].brakeLights)
                    end)
                end
            end
			if config.ConfigList[vehicleModelName].lightbarPattern ~= nil then
				if VehicleControlActivityDict[car].patternSync == 0 then
					VehicleControlActivityDict[car].patternSync = 1
					Citizen.CreateThread(function()
					lightbarPatternSystem(car,config.ConfigList[vehicleModelName].lightbarPattern)
					end)
				end
			end
			if config.ConfigList[vehicleModelName].hornLighting ~= nil then
				if VehicleControlActivityDict[car].hornLightSync == 0 then
					VehicleControlActivityDict[car].hornLightSync = 1
					Citizen.CreateThread(function()
					hornLightSystem(car,config.ConfigList[vehicleModelName].hornLighting, config.ConfigList[vehicleModelName].lightbarPattern)
					end)
				end
			end
		end
	end
end

-- Check for vehicles being in the control list, if they are not then the function will add them.
function auditVehicleControlList(vehicleAudit)
	local vehicle = vehicleAudit
	if DoesEntityExist(vehicle) then
		if not VehicleControlList[vehicle] then
			for carName in pairs(config.ConfigList) do
				if carName == GetEntityModel(vehicle) then
					VehicleControlList[vehicle] = true
					VehicleControlActivityDict[vehicle] = {lightSync = 0 , brakeSync = 0 , patternSync = 0 , hornLightSync = 0 , val4 = false }
				end
			end
		end
	end
end

-- VehicleControlList monitor function, with its own wait time to ensure that nothing attempts to execute functions on a car that doesn't exist.
Citizen.CreateThread(function()
	while true do
		for car in pairs(VehicleControlList) do
			if not VerifyVehicleStateLightReverse(clientPlayer, car) then
				VehicleControlList[car] = nil
				VehicleControlActivityDict[car] = nil
			end
		end
		Wait(2500)
	end
end)

-- Main loop!
Citizen.CreateThread(function()
	local stopLoopVehicle = 0
	while true do
		clientPlayer = cache?.ped or PlayerPedId()
		vehicle = GetVehiclePedIsIn(clientPlayer, false)
		if VerifyVehicleStateLightReverse(clientPlayer, vehicle) then
			if not VehicleControlList[vehicle] then
				auditVehicleControlList(vehicle)
			end
			if VehicleControlList[vehicle] then
				executeVehicleSystems(vehicle)
			end
		end
		Wait(2500)
	end
end)

Citizen.CreateThread(function()
	if config.debug then
		while true do
			print("-----------------------------------------------------------")
			for a,i in pairs(VehicleControlList) do
				print("DEBUG (VehicleControlList) VEHICLE ",a)
			end
			print("===========================================================")
			for a,i in pairs(VehicleControlActivityDict) do
				print("DEBUG (VehicleControlActivityDict) VEHICLE ",a)
			end
			print("-----------------------------------------------------------")
			Wait(5000)
		end
	end
end)
