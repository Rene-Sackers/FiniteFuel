class "FiniteFuel"

function FiniteFuel:__init()
	-- Configurable
	self.gasStationMinimapIcon = true -- Square on the minimap showing closest fuel station
	self.gasStationMinimapColor = Color(0, 255, 0)
	
	self.gasStationMarker = true -- 3D markers that show up at the gas station itself
	self.gasStationMarkerVisibleRadius = 100
	self.gasStationMarkerColor = Color(0, 255, 0, 100)
	
	self.gasStationRefuelRadius = 10
	self.gasStationRefuelMaxVelocity = 0.4
	
	self.externalRefuel = false -- Set this to true if you want to control refuel with an external script

	-- Variables
	self.currentVehicle = nil
	
	self.refuelRate = 35
	
	self.tickTimer = Timer()
	self.tickTimeout = 500
	
	-- Fuel meter
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
	
	self.gasStationMarkerPositions = {}
	self.gasStationClosest = {position = nil, distance = nil}
	
	self:CalculateMeterPosition({size = Vector2(Render.Width, Render.Height)})
	
	-- Events
	Events:Subscribe("LocalPlayerEnterVehicle", self, self.LocalPlayerEnterVehicle)
	Events:Subscribe("LocalPlayerExitVehicle", self, self.LocalPlayerExitVehicle)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
	Events:Subscribe("InputPoll", self, self.InputPoll)
	Events:Subscribe("PostTick", self, self.PostTick)
	Events:Subscribe("ResolutionChange", self, self.CalculateMeterPosition)
	Events:Subscribe("Render", self, self.Render)
	
	-- Networked events
	Network:Subscribe("FiniteFuelGetFuel", self, self.GetFuel)
	
	-- Get current vehicle's fuel if player in one
	if LocalPlayer:InVehicle() and IsValid(LocalPlayer:GetVehicle()) then
		Network:Send("FiniteFuelGetFuel", LocalPlayer:GetVehicle())
	end
end

-- ======================== Position calculations ========================
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

-- ======================== Rendering ========================
function FiniteFuel:Render(args)
	if self.currentVehicle == nil or not IsValid(self.currentVehicle.vehicle) or not LocalPlayer:InVehicle() or Game:GetState() ~= GUIState.Game then return end
	
	-- Draw background
	Render:FillArea(Vector2(self.fuelMeterLeft, self.fuelMeterTop), Vector2(self.fuelMeterWidth, self.fuelMeterHeight), self.fuelMeterBackground)
	
	-- Draw indicator
	Render:FillArea(Vector2(self.fuelMeterLeft, self.fuelMeterTop), Vector2(self.fuelMeterIndicatorWidth, self.fuelMeterHeight), self.fuelMeterForeground)
	
	-- Draw text
	Render:DrawText(Vector2(self.fuelMeterTextLeft, self.fuelMeterTextTop), self.fuelMeterText, self.fuelMeterTextColor, self.fuelMeterTextSize)
	
	-- Draw closest gas station on minimap
	if self.gasStationMinimapIcon and self.gasStationClosest.position ~= nil then Render:FillArea(Render:WorldToMinimap(self.gasStationClosest.position), Vector2(10, 10), self.gasStationMinimapColor) end
	
	-- Draw gas station marker
	if self.gasStationMarker and self.gasStationClosest.position ~= nil and self.gasStationClosest.distance <= self.gasStationMarkerVisibleRadius then
		local position = self.gasStationClosest.position
		local distance = self.gasStationClosest.distance
		local pos1 = position
		local pos2 = position + (Vector3(-1, 2, 0) * (distance / 20))
		local pos3 = position + (Vector3(1, 2, 0) * (distance / 20))
		Render:FillTriangle(pos1, pos2, pos3, self.gasStationMarkerColor)
		pos1 = position
		pos2 = position + (Vector3(0, 2, -1) * (distance / 20))
		pos3 = position + (Vector3(0, 2, 1) * (distance / 20))
		Render:FillTriangle(pos1, pos2, pos3, self.gasStationMarkerColor)
	end
end

-- ======================== Enter/exit vehicle ========================
function FiniteFuel:LocalPlayerEnterVehicle(args)
	if not IsValid(args.vehicle) then return end
	
	Network:Send("FiniteFuelGetFuel", args.vehicle)
end

function FiniteFuel:LocalPlayerExitVehicle(args)
	if self.currentVehicle == nil or not IsValid(self.currentVehicle.vehicle) or self.currentVehicle.vehicle ~= args.vehicle then return end
	
	Network:Send("FiniteFuelSetFuel", {vehicle = args.vehicle, fuel = self.currentVehicle.fuel})
	
	self.currentVehicle = nil
end

-- ======================== Tick update events ========================
function FiniteFuel:InputPoll()
	if self.currentVehicle == nil or
	not IsValid(self.currentVehicle.vehicle) or
	self.currentVehicle.fuel > 0 or
	(self.currentVehicle.vehicleType ~= FiniteFuelVehicleTypes.Airplane and self.currentVehicle.vehicleType ~= FiniteFuelVehicleTypes.Helicopter) then return end
	
	Input:SetValue(Action.HeliDecAltitude, 1)
	Input:SetValue(Action.PlaneDecTrust, 1)
end

function FiniteFuel:PostTick()

	if self.tickTimer:GetMilliseconds() < self.tickTimeout or self.currentVehicle == nil or not IsValid(self.currentVehicle.vehicle) then return end
	self.tickTimer:Restart()
	
	local playerPosition = LocalPlayer:GetPosition()
	self.gasStationMarkerPositions = {}
	if self.gasStationClosest.position ~= nil then self.gasStationClosest.distance = Vector3.Distance(self.gasStationClosest.position, playerPosition) end
	for index, data in ipairs(FiniteFuelGasStations) do
		local gasStationPosition = data[1]
		local distance = Vector3.Distance(gasStationPosition, playerPosition)
		
		-- Closer than last gas station checked
		if self.gasStationClosest.distance == nil or distance < self.gasStationClosest.distance then
			self.gasStationClosest = {position = data[1], distance = distance}
		end
		
		-- Close enough to draw marker
		if distance <= self.gasStationMarkerVisibleRadius then
			table.insert(self.gasStationMarkerPositions, gasStationPosition)
		end
	end
	
	-- Close and moving slow enough to refuel, and tank is not full
	local velocity = self.currentVehicle.vehicle:GetLinearVelocity():Length()
	local idling = velocity <= self.gasStationRefuelMaxVelocity
	
	if not self.externalRefuel and self.gasStationClosest.distance ~= nil and self.gasStationClosest.distance <= self.gasStationRefuelRadius and idling and self.currentVehicle.fuel < self.currentVehicle.tankSize then
		-- Fuel up. Set to tank size if full
		self.currentVehicle.fuel = self.currentVehicle.fuel + self.refuelRate
		if self.currentVehicle.fuel > self.currentVehicle.tankSize then self.currentVehicle.fuel = self.currentVehicle.tankSize end
		
		-- Change text
		if self.fuelMeterText ~= "Refuelling..." then
			self.fuelMeterText = "Refuelling..."
			self:CalculateTextPosition()
		end
	elseif idling and self.currentVehicle.fuel > 0 then -- Idling
		-- Drain idle. Set tank to 0 if less than empty
		self.currentVehicle.fuel = self.currentVehicle.fuel - self.currentVehicle.idleDrainRate
		
		-- Change text
		if self.fuelMeterText ~= "Idle" then
			self.fuelMeterText = "Idle"
			self:CalculateTextPosition()
		end
		if self.currentVehicle.fuel < 0 then self.currentVehicle.fuel = 0 end
	elseif not idling and self.currentVehicle.fuel > 0 then -- Moving
		-- Drain moving. Set tank to 0 if less than empty
		local drain = (velocity * self.currentVehicle.drainRate)-- * 100 -- DEBUGGING
		self.currentVehicle.fuel = self.currentVehicle.fuel - drain
		if self.currentVehicle.fuel < 0 then self.currentVehicle.fuel = 0 end
		
		-- Change text
		if self.fuelMeterText ~= "Fuel" then
			self.fuelMeterText = "Fuel"
			self:CalculateTextPosition()
		end
	end
	
	-- Calculate indicator width
	self.fuelMeterIndicatorWidth = self.fuelMeterWidth / self.currentVehicle.tankSize * self.currentVehicle.fuel
end

-- ======================== Movement blocker ========================
function FiniteFuel:LocalPlayerInput(args)
	if self.currentVehicle == nil or not IsValid(self.currentVehicle.vehicle) or self.currentVehicle.fuel > 0 then return end
	
	-- Fuel empty, block movement keys
	return not FiniteFuelVehicleKeys[args.input]
end

-- ======================== Vehicle info ========================
function FiniteFuel:GetFuel(args)
	local vehicle = args.vehicle
	local fuel = args.fuel
	
	self.currentVehicle = FiniteFuelVehicle(vehicle, fuel)
end

-- ======================== Initialize ========================
Events:Subscribe("ModuleLoad", function()
	FiniteFuel()
end)