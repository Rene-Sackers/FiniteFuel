class "FiniteFuelVehicle"

function FiniteFuelVehicle:__init(vehicle, fuel)
	self.vehicle = vehicle
	self.vehicleType = self:VehicleType()
	
	self.fuel = fuel
	self.tankSize = self:TankSize()
	
	if self.fuel == nil then self.fuel = self.tankSize end
	
	local drainage = self:DrainRate(vehicle)
	local vehicleMass = self.vehicle:GetMass()
	self.drainRate = vehicleMass * drainage.accelerate
	self.idleDrainRate = vehicleMass * drainage.idle
end

function FiniteFuelVehicle:VehicleType()
	if not IsValid(self.vehicle) then return FiniteFuelVehicleTypes.Car end
	
	local vehicleType = FiniteFuelVehicles[self.vehicle:GetModelId()]
	if vehicleType == nil then return FiniteFuelVehicleTypes.Car else return vehicleType end
end

function FiniteFuelVehicle:DrainRate()
	if not IsValid(self.vehicle) then return 1 end
	
	local drainage = FiniteFuelDrainageFormulas[self.vehicleType]
	if drainage == nil then return {idle = 0, accelerate = 0}
	else return drainage end
end

function FiniteFuelVehicle:TankSize()
	if not IsValid(self.vehicle) then return 1 end
	
	return self.vehicle:GetMass() / 2
end