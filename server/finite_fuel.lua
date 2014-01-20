class "FiniteFuel"

function FiniteFuel:__init()
	-- Table to store all vehicles their current fuel amount
	self.vehiclesFuel = {}
	
	-- The amount of seconds between each time the server should check for vehicles in the vehicles fuel table that are removed and it's timer.
	self.removedVehiclesCheckTimeout = 60
	self.removedVehiclesCheckTimer = Timer()
	
	-- List of all vehicles their tank sizes
	self.tankSizes = FiniteFuelCreateConfig()
	
	-- The default tank size for vehicles that are not defined in the above table
	self.defaultTankSize = 800
	
	-- Events
	Network:Subscribe("FiniteFuelGetFuel", self, self.GetFuel)
	Network:Subscribe("FiniteFuelSetFuel", self, self.SetFuel)
	Events:Subscribe("PostTick", self, self.PostTick)
end

function FiniteFuel:GetTankSize(vehicle)
	local vehicleModelId = vehicle:GetModelId()
	local tankSize = vehicle:GetMass() / 2
	if self.tankSizes[vehicleModelId] ~= nil then tankSize = self.tankSizes[vehicleModelId] end
	return tankSize
end

function FiniteFuel:GetCurrentFuelAndTankSize(vehicle)
	-- Vehicle not valid
	if not IsValid(vehicle) then return end
	
	-- Get tank size
	local tankSize = self:GetTankSize(vehicle)
	
	-- See if the vehicle is in the fuel array
	local savedFuel = nil
	for v, fuel in pairs(self.vehiclesFuel) do
		if IsValid(v) and v == vehicle then
			savedFuel = fuel
			break
		end
	end
	
	-- Return the saved fuel
	if savedFuel ~= nil then return savedFuel, tankSize end
	
	-- Add to vehicle fuel array
	self.vehiclesFuel[vehicle] = tankSize
	
	return tankSize, tankSize
end

function FiniteFuel:GetFuel(vehicle, player)
	-- Check if vehicle is valid
	if not IsValid(vehicle) then return end
	
	-- Get vehicle current fuel and tank size
	local vehicleFuel, tankSize = self:GetCurrentFuelAndTankSize(vehicle)
	
	-- Return vehicle fuel and tank size
	Network:Send(player, "FiniteFuelVehicleFuel", {vehicle = vehicle, fuel = vehicleFuel, tankSize = tankSize})
end

function FiniteFuel:SetFuel(args, player)
	-- Get fuel and vehicle arguments
	local vehicle = args.vehicle
	local fuel = args.fuel
	
	-- Set vehicle fuel in vehicles fuel table
	for v, vFuel in pairs(self.vehiclesFuel) do
		if IsValid(v) and v == vehicle then
			self.vehiclesFuel[v] = fuel
			break
		end
	end
end

function FiniteFuel:PostTick()
	-- Timeout has not elapsed yet
	if self.removedVehiclesCheckTimer:GetSeconds() < self.removedVehiclesCheckTimeout then return end
	
	-- Restart timeout timer
	self.removedVehiclesCheckTimer:Restart()
	
	-- Loop through all stored vehicles, and check if the ID no longer exists
	for vehicle, fuel in pairs(self.vehiclesFuel) do
		if not IsValid(vehicle) or vehicle:GetUnoccupiedRemove() or vehicle:GetDeathRemove() then
			-- Vehicle no longer exists, remove from table
			self.vehiclesFuel[vehicle] = nil
		end
	end
end

-- Initialize when module is fully loaded
Events:Subscribe("ModuleLoad", function()
	FiniteFuel()
end)