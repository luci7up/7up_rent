local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","7up_rent")

local rentedVehicles = {}

RegisterNetEvent('7up_rent:RentVehicle')
AddEventHandler('7up_rent:RentVehicle', function(model, insurance, price, time, rentalIndex)
    time = time:gsub('min', '')
    time =  tonumber(time)
    local user_id = vRP.getUserId{source}

    if vRP.getMoney{user_id} >= price + Config.DownPayment then
        vRP.tryPayment{user_id,price + Config.DownPayment}
        vRPclient.notify(source,{"You have paid "..price.." $ "})
        vRPclient.notify(source,{"You have paid "..Config.DownPayment.."$ as a down payment"})
        TriggerClientEvent('7up_rent:SpawnVehicle', source, model, insurance, price, time, rentalIndex)
    elseif vRP.getBankMoney{user_id} >= price + Config.DownPayment then
        vRP.tryBankPayment{user_id, price + Config.DownPayment}
        vRPclient.notify(source,{"You have paid "..Config.DownPayment.."$ as a down payment from your bank account"})
        vRPclient.notify(source,{"You have paid "..price.."$ from your bank account"})
        TriggerClientEvent('7up_rent:SpawnVehicle', source, model, insurance, price, time, rentalIndex)
    else
        vRPclient.notify(source,{"You can not afford renting this vehicle."})
    end
end)

RegisterNetEvent('7up_rent:VehicleSpawned')
AddEventHandler('7up_rent:VehicleSpawned', function(plate, insurance, time, netId)
    local _source = source
    local user_id = vRP.getUserId{_source}
    if not rentedVehicles[plate] then
        rentedVehicles[plate] = {
            owner = user_id,
            insurance = insurance,
            netId = netId,
            downPayment = Config.DownPayment
        }
        SetTimeout(time * 60 * 1000 + 5000, function()
            local plate = GetVehicleNumberPlateText(NetworkGetEntityFromNetworkId(netId))
            if rentedVehicles[plate] then
                if GetPlayerPing(rentedVehicles[plate].owner) > 5 then
                    Citizen.CreateThread(function()
                        
                        while true do
                            Wait(1000 * 60)
                            if rentedVehicles[plate].downPayment >= Config.ExtraChargePerMinute then
                                rentedVehicles[plate].downPayment = rentedVehicles[plate].downPayment - Config.ExtraChargePerMinute
                            else
                                if vRP.getUserId{_source} then
                                    vRPclient.notify(source,{"The deposit will not be refunded, because you have not returned the vehicle"})
                                    vRPclient.notify(source,{"The vehicle has been impounded"})
                                end
                                DeleteEntity(NetworkGetEntityFromNetworkId(netId))
                                rentedVehicles[plate] = nil
                            end
                        end
                    end)
                else
                    rentedVehicles[plate] = nil
                    DeleteEntity(NetworkGetEntityFromNetworkId(netId))
                end
            end
        end)
    end
end)

RegisterNetEvent('7up_rent:ReturnVehicle')
AddEventHandler('7up_rent:ReturnVehicle', function(plate, damageIndex)
    local user_id = vRP.getUserId{source}
    if not rentedVehicles[plate] then
        vRPclient.notify(source,{"You can not return this vehicle because this one has not been rented."})
        return
    end

    if rentedVehicles[plate].owner ~= user_id then
        vRPclient.notify(source,{"You can not return this vehicle because you are not borrower."}) 
        return
    end

    if rentedVehicles[plate].insurance then
        damageIndex = 1
    end

    local moneyToGive = math.floor(rentedVehicles[plate].downPayment * damageIndex)

    if damageIndex < 1 then
        local reducedBy = Config.DownPayment - Config.DownPayment * damageIndex
        vRPclient.notify(source,{"Down payment you should receive has been lowered by "..reducedBy.."$ because you have returned the vehicle damaged"})
    end

    vRP.giveBankMoney{user_id, moneyToGive}
    vRPclient.notify(source,{"The down payment of amount "..moneyToGive.."$ has been returned you."})
    TaskLeaveVehicle(GetPlayerPed(source), NetworkGetEntityFromNetworkId(rentedVehicles[plate].netId), 0)
    Wait(1700)
    DeleteEntity(NetworkGetEntityFromNetworkId(rentedVehicles[plate].netId))
    rentedVehicles[plate] = nil
    TriggerClientEvent('7up_rent:VehicleSuccessfulyReturned', source)
end)