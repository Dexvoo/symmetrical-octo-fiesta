local DuiEntity
local DuiTxd
local DuiObj
local DuiHandle
local DuiLoaded = false
local Enabled = true
local IsDuiDisplayed = false
local carRPM, carSpeed, carGear, carIL, carAcceleration, carHandbrake, carBrakePressure, carBrakeAbs, carLS_r, carLS_o, carLS_h
local Profile
local ProfileInitialized = false

Citizen.CreateThread(function()
	InitProfile()
end)

Citizen.CreateThread(function()
	while ProfileInitialized == false do
		Citizen.Wait(100)
	end
	while true do
		Citizen.Wait(0)
		if Enabled then
			if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
				if IsDuiDisplayed then
					UpdateDui()
				else
					DisplayDui()
					IsDuiDisplayed = true
				end
			else
				if IsDuiDisplayed then
					HideDui()
					IsDuiDisplayed = false
				end
			end
		else
			HideDui()
			IsDuiDisplayed = false
		end
	end
end)

Citizen.CreateThread(function()
	while ProfileInitialized == false do
		Citizen.Wait(100)
	end
	while true do
		Citizen.Wait(0)
		if IsControlJustPressed(0, Profile.keyControl) then
			Enabled = not Enabled
			local CurrentStatus = Enabled and "^2On^0" or "^1Off^0"
			SendChatMessage("Your speedometer has been switched to " .. CurrentStatus)
		end
	end
end)

RegisterCommand('hsp', function(source, args)
	local cmd = args[1] or ''
	if cmd == 'mph' then
		Profile.useMph = not Profile.useMph
		SetPlayerProfile(Profile)
		local CurrentUnit = Profile.useMph and "^2MPH^0" or "^2KPH^0"
		SendChatMessage("Your speed unit has been switched to " .. CurrentUnit .. ", please restart your game to take effect")
	elseif cmd == 'nve' then
		Profile.useNve = not Profile.useNve
		SetPlayerProfile(Profile)
		local CurrentNve = Profile.useNve and "^2On^0" or "^1Off^0"
		SendChatMessage("Your NVE graphic mods has been switched to " .. CurrentNve .. ", please restart your game to take effect")
	else
		Enabled = not Enabled
		local CurrentStatus = Enabled and "^2On^0" or "^1Off^0"
		SendChatMessage("Your speedometer has been switched to " .. CurrentStatus)
	end
end, false)

function SendChatMessage(data)
	TriggerEvent('chat:addMessage', {
		args = { data }
	})
end

function InitProfile()
	Profile = GetPlayerProfile()
	if Profile.unit == nil then
		Profile.unit = Config.unit
	end
	if Profile.keyControl == nil then
		Profile.keyControl = Config.keyControl
	end
	if Profile.useNve == nil then
		Profile.useNve = Config.useNve
	end
	SetPlayerProfile(Profile)
	ProfileInitialized = true
end

function CreateHologramDui()
	print("Loading " .. Config.duiUrl)
	local urlHash = "#"
	local jsonTemp = {}
	if Profile.useMph then
		jsonTemp.unit = "MPH"
	else
		jsonTemp.unit = "KPH"
	end
	if Profile.useNve then
		jsonTemp.nve = true
	else
		jsonTemp.nve = false
	end
	urlHash = urlHash .. json.encode(jsonTemp)
	DuiTxd = CreateRuntimeTxd('DuiHologramTxd')
	DuiObj = CreateDui(Config.duiUrl .. urlHash, 512, 512)
	while not IsDuiAvailable(DuiObj) do
		Wait(100)
	end
	print("Successful create Dui")
	_G.DuiObj = DuiObj
	DuiHandle = GetDuiHandle(DuiObj)
	local tx5 = CreateRuntimeTextureFromDuiHandle(DuiTxd, 'DuiTexture', DuiHandle)
	print("Replace textures...")
	AddReplaceTexture('hologram_box_model', 'p_hologram_box', 'DuiHologramTxd', 'DuiTexture')
end

function DestroyHologramDui()
	DestroyDui(DuiObj)
end

function UpdateDui()
	
	if not DoesEntityExist(DuiEntity) then
		DisplayDui()
	end
	
	playerPed = GetPlayerPed(-1)
		
	if playerPed and IsDuiDisplayed then
		
		playerCar = GetVehiclePedIsIn(playerPed, false)
		
		if playerCar and GetPedInVehicleSeat(playerCar, -1) == playerPed then
			
			local NcarRPM                      = GetVehicleCurrentRpm(playerCar)
			local NcarSpeed                    = GetEntitySpeed(playerCar)
			local NcarGear                     = GetVehicleCurrentGear(playerCar)
			local NcarIL                       = GetVehicleIndicatorLights(playerCar)
			local NcarAcceleration             = IsControlPressed(0, 71)
			local NcarHandbrake                = GetVehicleHandbrake(playerCar)
			local NcarBrakePressure            = GetVehicleWheelBrakePressure(playerCar, 0)
			local NcarBrakeAbs                 = (GetVehicleWheelSpeed(playerCar, 0) == 0.0 and NcarSpeed > 0.0)
			local NcarLS_r, NcarLS_o, NcarLS_h = GetVehicleLightsState(playerCar)
			
			local shouldUpdate = false
			
			if NcarRPM ~= carRPM then
				shouldUpdate = true
			end
			if NcarSpeed ~= carSpeed then
				shouldUpdate = true
			end
			if NcarGear ~= carGear then
				shouldUpdate = true
			end
			if NcarIL ~= carIL then
				shouldUpdate = true
			end
			if NcarAcceleration ~= carAcceleration then
				shouldUpdate = true
			end
			if NcarHandbrake ~= carHandbrake then
				shouldUpdate = true
			end
			if NcarBrakePressure ~= carBrakePressure then
				shouldUpdate = true
			end
			if NcarBrakeAbs ~= carBrakeAbs then
				shouldUpdate = true
			end
			if NcarLS_r ~= carLS_r then
				shouldUpdate = true
			end
			if NcarLS_o ~= carLS_o then
				shouldUpdate = true
			end
			if NcarLS_h ~= carLS_h then
				shouldUpdate = true
			end
			
			if shouldUpdate then
				carRPM           = NcarRPM
				carGear          = NcarGear
				carSpeed         = NcarSpeed
				carIL            = NcarIL
				carAcceleration  = NcarAcceleration
				carHandbrake     = NcarHandbrake
				carBrakePressure = NcarBrakePressure
				carBrakeAbs      = NcarBrakeAbs
				carLS_r          = NcarLS_r
				carLS_o          = NcarLS_o
				carLS_h          = NcarLS_h
				
				if Profile.useMph then
					carCalcSpeed = math.ceil(carSpeed * 2.236936)
				else
					carCalcSpeed = math.ceil(carSpeed * 3.6)
				end
				
				SendDuiMessage(DuiObj, json.encode({
					ShowHud                = true,
					CurrentCarRPM          = carRPM,
					CurrentCarGear         = carGear,
					CurrentCarSpeed        = carCalcSpeed,
					CurrentCarIL           = carIL,
					CurrentCarAcceleration = carAcceleration,
					CurrentCarHandbrake    = carHandbrake,
					CurrentCarBrake        = carBrakePressure,
					CurrentCarAbs          = carBrakeAbs,
					CurrentCarLS_r         = carLS_r,
					CurrentCarLS_o         = carLS_o,
					CurrentCarLS_h         = carLS_h,
					PlayerID               = GetPlayerServerId(GetPlayerIndex()),
					screenScore            = speedometer
				}))
			end
		elseif IsDuiDisplayed then
			SendDuiMessage(DuiObj, json.encode({HideHud = true}))
		end
		
		Wait(50)
	end
end

function HideDui()
	SetEntityAsNoLongerNeeded(DuiEntity)
	DeleteVehicle(DuiEntity)
	DeleteEntity(DuiEntity)
end

function DisplayDui()
	if not IsModelInCdimage(Config.modelName) or not IsModelAVehicle(Config.modelName) then
        TriggerEvent('chat:addMessage', {
            args = { 'Cannot find the model "' .. Config.modelName .. '", please make sure you install the plugin correctly' }
        })
        return
    end
	print("Creating model...")
    RequestModel(Config.modelName)
    while not HasModelLoaded(Config.modelName) do
        Citizen.Wait(500)
    end
	local pos       = GetEntityCoords(GetPlayerPed(-1))
	local playerCar = GetVehiclePedIsIn(GetPlayerPed(-1))
    DuiEntity = CreateVehicle(Config.modelName, pos.x, pos.y, pos.z, GetEntityHeading(GetPlayerPed(-1)), false, false)
	print("Setting entity status...")
	SetVehicleEngineOn(DuiEntity, true, true)
	SetVehicleDoorsLockedForAllPlayers(DuiEntity, true)
	print("Attach to entity...")
	local EntityBone = GetEntityBoneIndexByName(playerCar, "chassis")
	local BindPos = {x = 2.5, y = -1.0, z = 0.85}
	AttachEntityToEntity(DuiEntity, playerCar, EntityBone, BindPos.x, BindPos.y, BindPos.z, 0.0, 0.0, -15.0, false, false, false, false, false, true)
	Citizen.Wait(200)
	if not DuiLoaded then
		print("Creating Dui...")
		CreateHologramDui()
		DuiLoaded = true
	end
end

function GetPlayerProfile()
	local kvpData = GetResourceKvpString("HologramProfile")
	if kvpData ~= nil then
		return json.decode(kvpData)
	else
		return {}
	end
end

function SetPlayerProfile(data)
	SetResourceKvp("HologramProfile", json.encode(data))
end


local score = 0
local screenScore = 0
local tick
local idleTime
local driftTime
local mult = 0.30
local previous = 0
local total = 0
local curAlpha = 0
local threshhold = 100000
local multmaths = 1
local cashmaths = 0
local cash = 0
local fps = 0
local illegalarea = false
local show = true
local PlayerPed
local Teko

RegisterCommand("toggledriftcounter", function(source, args, rawCommand)
    if show then
	show = false
    else
	show = true
    end
end, false)

Citizen.CreateThread( function()

	RegisterFontFile('Teko')
	Teko = RegisterFontId('Teko')

	-- PREP FUNCTIONS --

	RegisterNetEvent('in-driftcounter:getdriftscore')
	AddEventHandler('in-driftcounter:getdriftscore', function()
		TriggerEvent("in-driftingtrials:sendScore", score)
	end)

	function round(number)
		number = tonumber(number)
		number = math.floor(number) -- rounds completely down
		if number < 0.01 then
			number = 0
		elseif number > 999999999 then
			number = 999999999
		end
		return number
	end
	
	function calculateBonus(previous)
		local points = previous
		local points = round(points)
		return points or 0
	end

	function angle(veh)
		if not veh then return false end
		local vx,vy,vz = table.unpack(GetEntityVelocity(veh))
		local modV = math.sqrt(vx*vx + vy*vy)
		local rx,ry,rz = table.unpack(GetEntityRotation(veh,0))
		local sn,cs = -math.sin(math.rad(rz)), math.cos(math.rad(rz))
		if GetEntitySpeed(veh)* 3.6 < 30 or GetVehicleCurrentGear(veh) == 0 then return 0,modV end --speed over 30 km/h
		local cosX = (sn*vx + cs*vy)/modV
		if cosX > 0.966 or cosX < 0 then return 0,modV end
		return math.deg(math.acos(cosX))*0.5, modV
	end

	function DrawHudText(text, font, colour,coordsx,coordsy,scalex,scaley)
		SetTextFont(font)
		SetTextProportional(1)
		SetTextScale(scalex, scaley)
		local colourr,colourg,colourb,coloura = table.unpack(colour)
		SetTextColour(colourr,colourg,colourb, coloura)
		SetTextDropshadow(0, 0, 0, 0, coloura)
		SetTextEdge(1, 0, 0, 0, 255)
		SetTextDropShadow()
		SetTextOutline()
		SetTextEntry("STRING")
		AddTextComponentString(text)
		EndTextCommandDisplayText(coordsx,coordsy)
	end

	while true do
		PlayerPed = PlayerPedId()
		Citizen.Wait(1)
		local PlayerVeh = GetVehiclePedIsUsing(PlayerPed, false)
		if not illegalarea and GetPedInVehicleSeat(PlayerVeh, -1) == PlayerPed then
			fps = 60 / (1 / GetFrameTime())
			multmaths = 1 + (math.floor(score / threshhold) / 10) -- every 1 second do:
			tick = GetGameTimer() -- get current game timestamp
			if not IsPedDeadOrDying(PlayerPed, 1) and PlayerVeh and GetPedInVehicleSeat(PlayerVeh, -1) == PlayerPed and IsVehicleOnAllWheels(PlayerVeh) and not IsPedInFlyingVehicle(PlayerPed) then -- if player is driving a vehicle, alive and on the ground
				local angle,velocity = angle(PlayerVeh) -- angle is car angle and velocity is car velocity
				local tempBool = tick - (idleTime or 0) < 1850 -- true if player is idle for 1850ms
				if not tempBool and score ~= 0 then -- when drift ends
					previous = score -- first time 0 = score (below)
					previous = calculateBonus(previous) -- floors number
					total = total+previous -- total is 0 + 0 first time
					cashmaths = math.floor(((previous / 2000000 / 35) + 1 ) * 90)
					cash = round(previous / cashmaths) -- cash is half of the previous score 
					TriggerServerEvent("in-driftcounter:NormalDrift", cash ) -- pays player for this drift
					TriggerServerEvent("in-driftcounter:BoosterDrift", cash ) -- pays player for this drift
					TriggerServerEvent("in-driftcounter:QuartzDrift", cash ) -- pays player for this drift
					TriggerServerEvent("in-driftcounter:DiamondDrift", cash ) -- pays player for this drift
					TriggerServerEvent("in-driftcounter:GoldDrift", cash ) -- pays player for this drift
					TriggerServerEvent("in-driftcounter:IronDrift", cash ) -- pays player for this drift
					TriggerServerEvent("in-driftcounter:BronzeDrift", cash ) -- pays player for this drift
					TriggerServerEvent("in-driftcounter:StaffDrift", cash ) -- pays player for this drift
					TriggerEvent("in-driftcounter:DriftFinished", previous)
					TriggerEvent("in-driftingtrials:sendScore", math.floor(score))
					score = 0 -- resets score
					multmaths = 1
				end
				if angle ~= 0 then -- if angle isnt 0
					if score == 0 then -- if score is 0
						drifting = true -- start drifting
						driftTime = tick -- drift time is current game time
					end
					if tempBool then -- if drifting is happening
						if multmaths <= 1 then	
							score = score + math.floor(angle*velocity)*mult * fps
						elseif multmaths < 10 and multmaths > 1 then
							score = score + (math.floor(angle*velocity)*mult) * (multmaths) * fps
						elseif multmaths >= 10 then
							score = score + (math.floor(angle*velocity)*mult) * 10 * fps
						end
						-- score is calculated by flooring the multiplication of the car's angle and velocity times the multiplier and added to the last score
					else -- if drift is starting
						score = math.floor(angle*velocity)*mult
						-- score is calculated by flooring the multiplication of the car's angle and velocity times the multiplier
					end
					screenScore = calculateBonus(score) -- screenscore is floored score
					idleTime = tick -- time of idle is current game time
				end
			end
			
			if tick - (idleTime or 0) < 3000 then -- random shit i have no idea I think it's colors
				if curAlpha < 255 and curAlpha+10 < 255 then
					curAlpha = curAlpha+10
				elseif curAlpha > 255 then
					curAlpha = 255
				elseif curAlpha == 255 then
					curAlpha = 255
				elseif curAlpha == 250 then
					curAlpha = 255
				end
			else
				if curAlpha > 0 and curAlpha-10 > 0 then
					curAlpha = curAlpha-10			elseif curAlpha < 0 then
					curAlpha = 0

				elseif curAlpha == 5 then
					curAlpha = 0
				end
			end
			if not screenScore then screenScore = 0 end
			multiplier = ""
			if multmaths < 10 then
				multiplier = " " .. tostring(multmaths) .. "x"
			else
				multiplier = " 10x"
			end
			red = 0
			green = 0
			blue = 0
			if multmaths >= 1 and multmaths < 2 then
				red = 180
				green = 180
				blue = 180
			elseif multmaths >= 2 and multmaths < 3 then
				red = 0
				green = 255
				blue = 255
			elseif multmaths >= 3 and multmaths < 4 then
				red = 0
				green = 255
				blue = 127
			elseif multmaths >= 4 and multmaths < 5 then
				red = 0
				green = 255
				blue = 0
			elseif multmaths >= 5 and multmaths < 6 then
				red = 127
				green = 255
				blue = 0
			elseif multmaths >= 6 and multmaths < 7 then
				red = 255
				green = 255
				blue = 0
			elseif multmaths >= 7 and multmaths < 8 then
				red = 255
				green = 127
				blue = 0
			elseif multmaths >= 8 then
				red = 255
				green = 0
				blue = 0
			end
			if show then
			DrawHudText("\n Drift Score: " .. (string.format("%s",tostring(screenScore))), Teko, {red,green,blue,curAlpha},0.80,0.9,0.6,0.6)
			DrawHudText("\n Multiplier:" .. multiplier, Teko, {red,green,blue,curAlpha},0.8027,0.955,0.3,0.3)
			end
		end
	end
end)

Citizen.CreateThread(function()
	local blacklisted = {
		{
			xupper = -371.27, -- airport
			xlower = -2024.62,
			yupper = -2112.33,
			ylower = -3383.78,
		},
	}
	while true do
		Citizen.Wait(5000)
		local playerCoords = GetEntityCoords(PlayerPed)
		for k,v in pairs(blacklisted) do 
			if playerCoords.x > v.xlower and playerCoords.x < v.xupper and playerCoords.y > v.ylower and playerCoords.y < v.yupper then
				illegalarea = true
				print('Oi Dumb Cunt Your In A Blacklisted Area To Earn Points')
			else
				illegalarea = false
			end
	 	end
    end
end)
