class "FiniteFuel"

function FiniteFuel:__init()
	-- Get gas stations array
	self.gasStations = FiniteFuelGasStations()
	self.gasStationRadius = 100
	self.gasStationColor = Color(0, 255, 0, 100)
	self.gasStationRefuelRadius = 10

	-- Timeout timer, timeout and amount to decrease fuel by after the timeout
	self.timeoutTimer = Timer()
	self.timeoutDuration = 100
	self.fuelDecrease = 0.1
	
	-- Timer for refuel
	self.refuelTimer = Timer()
	self.refuelTimeout = 500
	self.refuelRate = 2

	-- Actions that should be blocked when there is no fuel
	self.vehicleActions = {
		[Action.Accelerate] = true,
		[Action.Reverse] = true,
		[Action.BoatBackward] = true,
		[Action.BoatForward] = true,
		[Action.HeliBackward] = true,
		[Action.HeliForward] = true,
		[Action.HeliIncAltitude] = true,
		[Action.PlaneIncTrust] = true
	}

	-- Store the vehicle the player is currently the driver of
	self.currentVehicle = nil
	self.currentVehicleFuel = 0
	self.currentVehicleTankSize = 0
	
	-- Fuel indicator position
	self.fuelMeterPosition = "BottomCenter" -- Options: BottomLeft, BottomRight, BottomCenter, TopRight, TopCenter
	self.fuelMeterWidth = 0.2 -- value * screen width
	self.fuelMeterHeight = 0.03 -- value * screen height
	self.fuelMeterBackground = Color(0, 0, 0, 100)
	self.fuelMeterForeground = Color(0, 255, 0)
	self.fuelMeterTextColor = Color(255, 255, 255)

	-- Events
	Network:Subscribe("FiniteFuelVehicleFuel", self, self.VehicleFuel)
	Events:Subscribe("LocalPlayerEnterVehicle", self, self.LocalPlayerEnterVehicle)
	Events:Subscribe("LocalPlayerExitVehicle", self, self.LocalPlayerExitVehicle)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
	Events:Subscribe("Render", self, self.Render)
	
	-- If player currently in vehicle, call the LocalPlayerEnterVehicle, to get the current vehicle's fuel
	if LocalPlayer:InVehicle() and LocalPlayer:GetState() == PlayerState.InVehicle and IsValid(LocalPlayer:GetVehicle()) then
		self:LocalPlayerEnterVehicle({vehicle = LocalPlayer:GetVehicle(), is_driver = true})
	end
end

function FiniteFuel:LocalPlayerEnterVehicle(args)
	-- Player is not driver, don't handle
	if not args.is_driver then return end
	
	-- Get vehicle argument
	local vehicle = args.vehicle
	
	-- Check if vehicle is valid
	if not IsValid(vehicle) then return end
	
	-- Store current vehicle id, and set fuel to 0
	self.currentVehicle = vehicle
	self.currentVehicleFuel = 0
	self.currentVehicleTankSize = 0
	
	-- Request server for current vehicle fuel
	Network:Send("FiniteFuelGetFuel", vehicle)
end

function FiniteFuel:LocalPlayerExitVehicle(args)
	-- If current vehicle id is nil, don't handle
	if self.currentVehicle == nil then return end

	-- If current vehicle is set, tell the server the new fuel amount
	Network:Send("FiniteFuelSetFuel", {vehicle = self.currentVehicle, fuel = self.currentVehicleFuel})

	-- Reset current vehicle id, fuel and tank size
	self.currentVehicle = nil
	self.currentVehicleFuel = 0
	self.currentVehicleTankSize = 0
end

function FiniteFuel:LocalPlayerInput(args)
	-- If no current vehicle id set, player not currently in vehicle, current vehicle not valid, or not in "InVehicle" state, don't handle
	if self.currentVehicle == nil or not LocalPlayer:InVehicle() or LocalPlayer:GetState() ~= PlayerState.InVehicle or not IsValid(LocalPlayer:GetVehicle()) then return end
	--Chat:Print("a", Color(255, 0, 0))

	-- Get action argument
	local action = args.input
	
	-- If action is not in target actions, don't handle
	if not self.vehicleActions[action] then return end
	--Chat:Print("c", Color(255, 0, 0))
	
	-- If fuel <= 0, ignore the action
	if self.currentVehicleFuel <= 0 then return false end
	
	-- Check if timeout elapsed
	if self.currentVehicle ~= nil and self.timeoutTimer:GetMilliseconds() < self.timeoutDuration then return end
	self.timeoutTimer:Restart()
	
	-- Decrease fuel
	self.currentVehicleFuel = self.currentVehicleFuel - self.fuelDecrease
	if self.currentVehicleFuel < 0 then self.currentVehicleFuel = 0 end
end

function FiniteFuel:VehicleFuel(args)
	-- Get vehicle ID, fuel and tnak size arguments
	local vehicle = args.vehicle
	local fuel = args.fuel
	local tankSize = args.tankSize
	
	-- Vehicle id does not match current vehicle ID
	if vehicle ~= self.currentVehicle then return end
	
	-- Set fuel and tank size for current vehicle
	self.currentVehicleFuel = fuel
	self.currentVehicleTankSize = tankSize
	
	Chat:Print("Vehicle currently has " .. fuel .. "/" .. tankSize .. " fuel.", Color(255, 0, 0))
end

function FiniteFuel:Render()
	-- Check if vehicle ID and tank size are valid and if the GUI state is game, if not, exit function
	if self.currentVehicle == nil or not IsValid(self.currentVehicle) or self.currentVehicleTankSize == 0 or Game:GetState() ~= GUIState.Game then return end

	-- Calculate width and height
	local meterWidth = Render.Width * self.fuelMeterWidth
	local meterHeight = Render.Height * self.fuelMeterHeight
	
	-- Calculate left and top positions
	local leftPosition = 0
	local topPosition = 0
	
	if self.fuelMeterPosition == "BottomLeft" then
		leftPosition = 0
		topPosition = Render.Height - meterHeight
	elseif self.fuelMeterPosition == "BottomRight" then
		leftPosition = Render.Width - meterWidth
		topPosition = Render.Height - meterHeight
	elseif self.fuelMeterPosition == "BottomCenter" then
		leftPosition = (Render.Width / 2) - (meterWidth / 2)
		topPosition = Render.Height - meterHeight
	elseif self.fuelMeterPosition == "TopRight" then
		leftPosition = Render.Width - meterWidth
		topPosition = 0
	elseif self.fuelMeterPosition == "TopCenter" then
		leftPosition = (Render.Width / 2) - (meterWidth / 2)
		topPosition = 0
	end
	
	-- Draw background
	Render:FillArea(Vector2(leftPosition, topPosition), Vector2(meterWidth, meterHeight), self.fuelMeterBackground)
	
	-- Draw indicator
	local meterIndicatorWidth = meterWidth / self.currentVehicleTankSize * self.currentVehicleFuel
	Render:FillArea(Vector2(leftPosition, topPosition), Vector2(meterIndicatorWidth, meterHeight), self.fuelMeterForeground)
	
	-- If close to gas station, draw ellipse to indicate refueling station
	local playerPosition = LocalPlayer:GetPosition()
	for index, position in ipairs(self.gasStations) do
		local distance = Vector3.Distance(playerPosition, position)
		if distance < self.gasStationRadius then
			local pos1 = position
			local pos2 = position + (Vector3(-1, 2, 0) * (distance / 20))
			local pos3 = position + (Vector3(1, 2, 0) * (distance / 20))
			Render:FillTriangle(pos1, pos2, pos3, self.gasStationColor)
			pos1 = position
			pos2 = position + (Vector3(0, 2, -1) * (distance / 20))
			pos3 = position + (Vector3(0, 2, 1) * (distance / 20))
			Render:FillTriangle(pos1, pos2, pos3, self.gasStationColor)
			
			local velocity = self.currentVehicle:GetAngularVelocity()
			if distance < self.gasStationRefuelRadius and
				self.refuelTimer:GetMilliseconds() >= self.refuelTimeout and
				velocity.x + velocity.y < 1 and
				self.currentVehicleFuel < self.currentVehicleTankSize then
				self.refuelTimer:Restart()
				
				self.currentVehicleFuel = self.currentVehicleFuel + self.refuelRate
				if self.currentVehicleFuel > self.currentVehicleTankSize then self.currentVehicleFuel = self.currentVehicleTankSize end
			end
		end
	end
end

-- Initialize when module is fully loaded
Events:Subscribe("ModuleLoad", function()
	FiniteFuel()
end)