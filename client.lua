--- "Ramsus" ---
local isUiOpen = false
local speedBuffer = {}
local velBuffer = {}
local SeatbeltON = false
local InVehicle = false
local IsDead = false 
local InPause = false 
local Initialed = false  

local function AbsolutelyVehicleIsACar(veh) local vc = GetVehicleClass(veh) ; return (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20) end
local function Fwv(entity) local hr = GetEntityHeading(entity) + 90.0 ;if hr < 0.0 then hr = 360.0 + hr end ;hr = hr * 0.0174533;return {x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0} end
local function SetSeatBeltIconON() isUiOpen = true; SendNUIMessage({displayWindow = "true"}) end 
local function SetSeatBeltIconOFF() isUiOpen = false; SendNUIMessage({displayWindow = "false"}) end 
local function SeatBeltPlaySound(soundFile,soundVolume) SendNUIMessage({transactionType = "playSound",transactionFile = soundFile,transactionVolume = soundVolume}) end 


function Notify(string)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(string)
    DrawNotification(false, true)
end

CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local playerid = PlayerId()
        local ped = PlayerPedId()
        local car = GetVehiclePedIsIn(ped,false)
        InPause = IsPauseMenuActive()
        IsDead = IsPlayerDead(playerid)
        Initialed = true 
    end
end)

CreateThread(function()
    while not Initialed do 
        Wait(34)
    end 
    CreateThread(function()
        while true do
            Citizen.Wait(0)
            local ped = PlayerPedId()
            local car = GetVehiclePedIsIn(ped)
            if car ~= 0 and (InVehicle or AbsolutelyVehicleIsACar(car)) then
                InVehicle = true
                if isUiOpen == false and not IsDead then
                    if Config.Blinker then
                        SetSeatBeltIconON()
                    end
                end
                if SeatbeltON then
                    DisableControlAction(0, 75, true) -- Disable exit vehicle when stop
                    DisableControlAction(27, 75, true) -- Disable exit vehicle when Driving
                end
                speedBuffer[2] = speedBuffer[1]
                speedBuffer[1] = GetEntitySpeed(car)
                if
                    not SeatbeltON and speedBuffer[2] ~= nil and GetEntitySpeedVector(car, true).y > 1.0 and
                        speedBuffer[1] > (Config.Speed / 3.6) and
                        (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.255)
                 then
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
                    SeatbeltON = not SeatbeltON
                    if SeatbeltON then
                        Citizen.Wait(1)
                        if Config.Sounds then
                            TriggerEvent("seatbelt:sounds", "buckle", Config.Volume)
                        end
                        if Config.Notification then
                            Notify(Config.Strings.seatbelt_on)
                        end
                        if Config.Blinker then
                            SetSeatBeltIconOFF()
                        end
                    else
                        if Config.Notification then
                            Notify(Config.Strings.seatbelt_off)
                        end
                        if Config.Sounds then
                            TriggerEvent("seatbelt:sounds", "unbuckle", Config.Volume)
                        end
                        if Config.Blinker then
                            SetSeatBeltIconON()
                        end
                    end
                end
            elseif InVehicle then
                InVehicle = false
                SeatbeltON = false
                speedBuffer[1], speedBuffer[2] = 0.0, 0.0
                if isUiOpen == true and not IsDead then
                    if Config.Blinker then
                        SetSeatBeltIconOFF()
                    end
                end
            end
        end
    end)
    CreateThread(function()
        while true do
            Citizen.Wait(10)
            local Vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
            local VehSpeed = GetEntitySpeed(Vehicle) * 3.6
            if Config.AlarmOnlySpeed and VehSpeed > Config.AlarmSpeed then
                ShowAlarm = true
            else
                ShowAlarm = false
                SetSeatBeltIconOFF()
            end
            if IsDead or InPause then
                if isUiOpen == true then
                    SetSeatBeltIconOFF()
                end
            elseif not SeatbeltON and InVehicle and not InPause and not IsDead and Config.Blinker then
                if Config.AlarmOnlySpeed and ShowAlarm and VehSpeed > Config.AlarmSpeed then
                    SetSeatBeltIconON()
                end
            end
        end
    end)
    CreateThread(function()
        while true do
            Citizen.Wait(3500)
            if not SeatbeltON and InVehicle and not InPause and Config.LoopSound and ShowAlarm then
                TriggerEvent("seatbelt:sounds", "seatbelt", Config.Volume)
            end
        end
    end)
end)


AddEventHandler("seatbelt:sounds",function(soundFile, soundVolume)
    SeatBeltPlaySound(soundFile,soundVolume)
end)