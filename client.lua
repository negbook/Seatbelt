--- "Ramsus" ---


local isUiOpen = false 
local speedBuffer  = {}
local velBuffer    = {}
local beltOn       = false
local wasInCar     = false

function Notify(string)
  SetNotificationTextEntry("STRING")
  AddTextComponentString(string)
  DrawNotification(false, true)
end

AddEventHandler('seatbelt:sounds', function(soundFile, soundVolume)
  SendNUIMessage({
    transactionType     = 'playSound',
    transactionFile     = soundFile,
    transactionVolume   = soundVolume
  })
end)

function IsCar(veh)
  local vc = GetVehicleClass(veh)
  return (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20)
end	

function Fwv(entity)
  local hr = GetEntityHeading(entity) + 90.0
  if hr < 0.0 then hr = 360.0 + hr end
  hr = hr * 0.0174533
  return { x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0 }
end
 
Citizen.CreateThread(function()
	while true do
	Citizen.Wait(0)
  
    local ped = PlayerPedId()
    local car = GetVehiclePedIsIn(ped)

    if car ~= 0 and (wasInCar or IsCar(car)) then
      wasInCar = true
          if isUiOpen == false and not IsPlayerDead(PlayerId()) then
            if Config.Blinker then
              SendNUIMessage({displayWindow = 'true'})
            end
              isUiOpen = true
          end

      if beltOn then 
        DisableControlAction(0, 75, true)  -- Disable exit vehicle when stop
        DisableControlAction(27, 75, true) -- Disable exit vehicle when Driving
	    end

      speedBuffer[2] = speedBuffer[1]
      speedBuffer[1] = GetEntitySpeed(car)

      if not beltOn and speedBuffer[2] ~= nil and GetEntitySpeedVector(car, true).y > 1.0 and speedBuffer[1] > (Config.Speed / 3.6) and (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.255) then
        local co = GetEntityCoords(ped)
        local fw = Fwv(ped)
        SetEntityCoords(ped, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
        SetEntityVelocity(ped, velBuffer[2].x, velBuffer[2].y, velBuffer[2].z)
        Citizen.Wait(1)
        SetPedToRagdoll(ped, 1000, 1000, 0, 0, 0, 0)
      end
        
      velBuffer[2] = velBuffer[1]
      velBuffer[1] = GetEntityVelocity(car)
        
      if IsControlJustReleased(0, Config.Control) and GetLastInputMethod(0) then
          beltOn = not beltOn 
          if beltOn then
          Citizen.Wait(1)

        if Config.Sounds then  
        TriggerEvent("seatbelt:sounds", "buckle", Config.Volume)
        end
        if Config.Notification then
        Notify(Config.Strings.seatbelt_on)
        end
        
        if Config.Blinker then
        SendNUIMessage({displayWindow = 'false'})
        end
        isUiOpen = true 
      else 
        if Config.Notification then
        Notify(Config.Strings.seatbelt_off)
        end

        if Config.Sounds then
        TriggerEvent("seatbelt:sounds", "unbuckle", Config.Volume)
        end

        if Config.Blinker then
        SendNUIMessage({displayWindow = 'true'})
        end
        isUiOpen = true  
      end
    end
      
    elseif wasInCar then
      wasInCar = false
      beltOn = false
      speedBuffer[1], speedBuffer[2] = 0.0, 0.0
          if isUiOpen == true and not IsPlayerDead(PlayerId()) then
            if Config.Blinker then
            SendNUIMessage({displayWindow = 'false'})
            end
            isUiOpen = false 
          end
    end
  end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)
		if (IsPlayerDead(PlayerId()) and isUiOpen == true) or IsPauseMenuActive() then
			SendNUIMessage({displayWindow = 'false'})
			isUiOpen = false
		end    
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(3500)
    if not beltOn and wasInCar and not IsPauseMenuActive() and Config.LoopSound then
      TriggerEvent("seatbelt:sounds", "seatbelt", Config.Volume)
		end    
	end
end)