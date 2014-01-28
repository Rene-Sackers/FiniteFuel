class "FiniteFuelVehicle"

function FiniteFuelVehicle:__init(vehicle, fuel)
	self.vehicle = vehicle
	self.vehicleGasType = self:VehicleGasType()
	
	self.fuel = fuel
	self.tankSize = self:TankSize()
	
	if self.fuel == nil then self.fuel = self.tankSize end
	
	local drainage = self:DrainRate(vehicle)
	local vehicleMass = self.vehicle:GetMass()
	self.drainRate = vehicleMass * drainage.accelerate
	self.idleDrainRate = vehicleMass * drainage.idle
end

function FiniteFuelVehicle:VehicleGasType()
	if not IsValid(self.vehicle) then return FiniteFuelGasTypes.Car end
	
	local vehicleGasType = FiniteFuelVehicles[self.vehicle:GetModelId()]
	if vehicleGasType == nil then return FiniteFuelGasTypes.Car else return vehicleGasType end
end

function FiniteFuelVehicle:DrainRate()
	if not IsValid(self.vehicle) then return 1 end
	
	local drainage = FiniteFuelDrainageFormulas[self.vehicleGasType]
	if drainage == nil then return {idle = 0, accelerate = 0}
	else return drainage end
end

function FiniteFuelVehicle:TankSize()
	if not IsValid(self.vehicle) then return 0 end
	
	return self.vehicle:GetMass() / FiniteFuelTankSizeFormulas[self.vehicleGasType]
end