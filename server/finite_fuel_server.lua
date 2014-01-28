function table.GetValue(targetTable, object, default)
	for key, value in pairs(targetTable) do
		if IsValid(key) and key == object then return targetTable[key] end
	end
	
	-- Nothing matched, return default
	return default
end

function table.SetValue(targetTable, object, newValue)
	for key, value in pairs(targetTable) do
		if IsValid(key) and key == object then targetTable[key] = newValue return end
	end
	
	-- Nothing was set, create new entry
	targetTable[object] = newValue
end

class "FiniteFuel"

function FiniteFuel:__init()
	-- Store all vehicles fuel
	self.vehiclesFuel = {}
	
	-- Cleanup
	self.removedCheckTimer = Timer()
	self.removedCheckTimeout = 60
	
	-- Events
	Events:Subscribe("PostTick", self, self.PostTick)
	
	-- Networked events
	Network:Subscribe("FiniteFuelGetFuel", self, self.GetFuel)
	Network:Subscribe("FiniteFuelSetFuel", self, self.SetFuel)
end

-- ======================== Get/set fuel ========================
function FiniteFuel:GetFuel(vehicle, player)
	if not IsValid(vehicle) then return end
	
	-- Get vehicle fuel. If nothing set, return tank size
	local fuel = table.GetValue(self.vehiclesFuel, vehicle, nil)
	
	-- Network event
	Network:Send(player, "FiniteFuelGetFuel", {vehicle = vehicle, fuel = fuel})
end

function FiniteFuel:SetFuel(args, player)	
	local vehicle = args.vehicle
	local fuel = args.fuel
	
	-- Check if vehicle is valid, and if the fuel is >= 0
	if not IsValid(vehicle) then return end
	if fuel == nil then fuel = 0 end
	if fuel < 0 then fuel = 0 end
	
	-- Set the vehicle's fuel
	table.SetValue(self.vehiclesFuel, vehicle, fuel)
end

-- ======================== Cleanup ========================
function FiniteFuel:PostTick()
	if self.removedCheckTimer:GetSeconds() < self.removedCheckTimeout then return end
	self.removedCheckTimer:Restart()
	
	for vehicle, fuel in pairs(self.vehiclesFuel) do
		if not IsValid(vehicle) then self.vehiclesFuel[vehicle] = nil end
	end
end

-- ======================== Initialize ========================
FiniteFuel()















