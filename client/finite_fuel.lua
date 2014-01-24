class "FiniteFuel"

function FiniteFuel:__init()
	-- Get gas stations array
	self.gasStations = FiniteFuelGasStations()
	self.gasStationMarkerRadius = 100
	self.gasStationColor = Color(0, 255, 0, 100)
	self.gasStationMarkerColor = Color(0, 255, 0)
	self.gasStationRefuelRadius = 10
	
	-- Closest gas station to render on minimap, and marker
	self.closestGasStation = { distance = 9999999999, position = Vector3(0, 0, 0) }

	-- Timeout timer, timeout and amount to decrease fuel by after the timeout
	self.timeoutTimer = Timer()
	self.timeoutDuration = 100
	
	-- Timer for refuel
	self.refuelTimer = Timer()
	self.refuelTimeout = 500
	self.refuelRate = 8
	self.idleVelocity = 0.1
	
	-- Tick update timer
	self.tickUpdateTimer = Timer()
	self.tickUpdateTimeout = 100

	-- Fuel related vehicle actions
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
	self.currentVehicleIdleDecrease = 0.01
	
	self.currentVehicleFuelDecrease = 0.1
	
	-- Fuel indicator position
	self.fuelMeterPosition = "BottomCenter" -- Options: BottomLeft, BottomRight, BottomCenter, TopRight, TopCenter
	self.fuelMeterRelativeWidth = 0.2 -- value * screen width
	self.fuelMeterRelativeHeight = 0.03 -- value * screen height
	self.fuelMeterBackground = Color(0, 0, 0, 100)
	self.fuelMeterForeground = Color(0, 255, 0)
	self.fuelMeterRelativeTextSize = 0.02 -- value * screen height
	self.fuelMeterTextColor = Color(255, 255, 255)
	
	self.fuelMeterWidth = 0
	self.fuelMeterHeight = 0
	self.fuelMeterLeft = 0
	self.fuelMeterTop = 0
	self.fuelMeterTextLeft = 0
	self.fuelMeterTextTop = 0
	self.fuelMeterIndicatorWidth = 0
	self.fuelMeterTextSize = 0
	self.fuelMeterText = "Fuel"
	
	self:CalculateMeterPosition({size = Vector2(Render.Width, Render.Height)})

	-- Events
	Network:Subscribe("FiniteFuelVehicleFuel", self, self.VehicleFuel)
	Events:Subscribe("LocalPlayerEnterVehicle", self, self.LocalPlayerEnterVehicle)
	Events:Subscribe("LocalPlayerExitVehicle", self, self.LocalPlayerExitVehicle)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
	Events:Subscribe("PreTick", self, self.PreTick)
	Events:Subscribe("Render", self, self.Render)
	Events:Subscribe("ResolutionChange", self, self.CalculateMeterPosition)
	
	-- If player currently in vehicle, call the LocalPlayerEnterVehicle, to get the current vehicle's fuel
	if LocalPlayer:InVehicle() and LocalPlayer:GetState() == PlayerState.InVehicle and IsValid(LocalPlayer:GetVehicle()) then
		self:LocalPlayerEnterVehicle({vehicle = LocalPlayer:GetVehicle(), is_driver = true})
	end
end

function FiniteFuel:CalculateMeterPosition(args)
	local size = args.size

	-- Calculate width and height
	self.fuelMeterWidth = size.x * self.fuelMeterRelativeWidth
	self.fuelMeterHeight = size.y * self.fuelMeterRelativeHeight
	
	-- Calculate left and top positions
	self.fuelMeterLeft = 0
	self.fuelMeterTop = 0
	
	if self.fuelMeterPosition == "BottomLeft" then
		self.fuelMeterLeft = 0
		self.fuelMeterTop = size.y - self.fuelMeterHeight
	elseif self.fuelMeterPosition == "BottomRight" then
		self.fuelMeterLeft = size.x - self.fuelMeterWidth
		self.fuelMeterTop = size.y - self.fuelMeterHeight
	elseif self.fuelMeterPosition == "BottomCenter" then
		self.fuelMeterLeft = (size.x / 2) - (self.fuelMeterWidth / 2)
		self.fuelMeterTop = size.y - self.fuelMeterHeight
	elseif self.fuelMeterPosition == "TopRight" then
		self.fuelMeterLeft = size.x - self.fuelMeterWidth
		self.fuelMeterTop = 0
	elseif self.fuelMeterPosition == "TopCenter" then
		self.fuelMeterLeft = (size.x / 2) - (self.fuelMeterWidth / 2)
		self.fuelMeterTop = 0
	end
	
	self.fuelMeterTextSize = size.y * self.fuelMeterRelativeTextSize
	
	self:CalculateTextPosition()
end

function FiniteFuel:CalculateTextPosition()
	local textSize = Render:GetTextSize(self.fuelMeterText, self.fuelMeterTextSize)
	
	self.fuelMeterTextLeft = self.fuelMeterLeft + (self.fuelMeterWidth / 2) - (textSize.x / 2)
	self.fuelMeterTextTop = self.fuelMeterTop + (self.fuelMeterHeight / 2) - (textSize.y / 2)
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
	self.currentVehicleFuelDecrease = vehicle:GetMass() * 0.00005
	self.currentVehicleIdleDecrease = vehicle:GetMass() * 0.00001
	
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
	if self.currentVehicle == nil or not IsValid(self.currentVehicle) or not LocalPlayer:InVehicle() or LocalPlayer:GetState() ~= PlayerState.InVehicle or not IsValid(LocalPlayer:GetVehicle()) then return end
	--Chat:Print("a", Color(255, 0, 0))

	-- Get action argument
	local action = args.input
	
	-- Check if we are watching for this action
	if self.vehicleActions[action] then
		-- If fuel <= 0, ignore the action
		if self.currentVehicleFuel <= 0 then return false end
	
		-- Check if timeout elapsed
		if self.timeoutTimer:GetMilliseconds() < self.timeoutDuration then return end
		self.timeoutTimer:Restart()
		
		self.currentVehicleFuel = self.currentVehicleFuel - self.currentVehicleFuelDecrease
	elseif self.currentVehicle:GetLinearVelocity():Length() <= self.idleVelocity then -- Vehicle idle		
		-- Check if timeout elapsed
		if self.timeoutTimer:GetMilliseconds() < self.timeoutDuration then return end
		self.timeoutTimer:Restart()
		
		self.currentVehicleFuel = self.currentVehicleFuel - self.currentVehicleIdleDecrease
	end
		
	-- Make sure fuel doesn not go < 0
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

function FiniteFuel:PreTick()
	-- Check if vehicle ID and tank size are valid and if the GUI state is game, if not, exit function
	if self.currentVehicle == nil or not IsValid(self.currentVehicle) or self.currentVehicleTankSize == 0 or Game:GetState() ~= GUIState.Game or self.tickUpdateTimer:GetMilliseconds() < self.tickUpdateTimeout then return end
	self.tickUpdateTimer:Restart()
	
	-- Calculate fuel indicator position
	self.fuelMeterIndicatorWidth = self.fuelMeterWidth / self.currentVehicleTankSize * self.currentVehicleFuel
		
	--[[self.gasStationMarkers = {}
	for index, position in ipairs(self.gasStations) do
		local distance = Vector3.Distance(playerPosition, position)
		
		-- Check if distance closer than closest gas station
		if distance < self.closestGasStation.distance then self.closestGasStation = { distance = distance, position = position } end
		
		-- Check if distance low enough to render marker
		if distance < self.gasStationMarkerRadius then
		end
	end]]
end

function FiniteFuel:Render()
	-- Check if vehicle ID and tank size are valid and if the GUI state is game, if not, exit function
	if self.currentVehicle == nil or not IsValid(self.currentVehicle) or self.currentVehicleTankSize == 0 then return end
	
	-- If close to gas station, draw ellipse to indicate refueling station
	local playerPosition = LocalPlayer:GetPosition()
	local restartTimer = false
	local refuelling = false
	for index, position in ipairs(self.gasStations) do
		local distance = Vector3.Distance(playerPosition, position)
		
		if distance < Vector3.Distance(self.closestGasStation.position, playerPosition) and position ~= self.closestGasStation.position then self.closestGasStation = { distance = distance, position = position } end
		
		if distance < self.gasStationMarkerRadius then
		
			local pos1 = position
			local pos2 = position + (Vector3(-1, 2, 0) * (distance / 20))
			local pos3 = position + (Vector3(1, 2, 0) * (distance / 20))
			Render:FillTriangle(pos1, pos2, pos3, self.gasStationColor)
			pos1 = position
			pos2 = position + (Vector3(0, 2, -1) * (distance / 20))
			pos3 = position + (Vector3(0, 2, 1) * (distance / 20))
			Render:FillTriangle(pos1, pos2, pos3, self.gasStationColor)
			
			local velocity = self.currentVehicle:GetLinearVelocity():Length()
			
			-- Timeout passed
			if self.refuelTimer:GetMilliseconds() >= self.refuelTimeout then
				restartTimer = true
				
				-- Vehicle close enough to the fuel station, tank is not full, and standing still
				if distance < self.gasStationRefuelRadius and velocity < self.idleVelocity and self.currentVehicleFuel < self.currentVehicleTankSize then
					refuelling = true
				
					-- Fuel up vehicle
					self.currentVehicleFuel = self.currentVehicleFuel + self.refuelRate
					if self.currentVehicleFuel > self.currentVehicleTankSize then self.currentVehicleFuel = self.currentVehicleTankSize end
				end
			end
		end
	end
	
	-- Only do if the timer has just ticked
	if restartTimer then		
		if refuelling and self.fuelMeterText ~= "Refuelling..." then
			self.fuelMeterText = "Refuelling..."
			self:CalculateTextPosition()
		elseif not refuelling and self.fuelMeterText ~= "Fuel" then
			self.fuelMeterText = "Fuel"
			self:CalculateTextPosition()
		end
	end
	
	if restartTimer then self.refuelTimer:Restart() end
	
	-- Don't render if not in game
	if Game:GetState() ~= GUIState.Game then return end
	
	-- Draw background
	Render:FillArea(Vector2(self.fuelMeterLeft, self.fuelMeterTop), Vector2(self.fuelMeterWidth, self.fuelMeterHeight), self.fuelMeterBackground)
	
	-- Draw indicator
	Render:FillArea(Vector2(self.fuelMeterLeft, self.fuelMeterTop), Vector2(self.fuelMeterIndicatorWidth, self.fuelMeterHeight), self.fuelMeterForeground)
	
	-- Draw text
	Render:DrawText(Vector2(self.fuelMeterTextLeft, self.fuelMeterTextTop), self.fuelMeterText, self.fuelMeterTextColor, self.fuelMeterTextSize)
	
	-- Draw closest gas station on minimap
	if self.closestGasStation.position ~= nil then Render:FillArea(Render:WorldToMinimap(self.closestGasStation.position), Vector2(10, 10), self.gasStationMarkerColor) end
end

-- Initialize when module is fully loaded
Events:Subscribe("ModuleLoad", function()
	FiniteFuel()
end)