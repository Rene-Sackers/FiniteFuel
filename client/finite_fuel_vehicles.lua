FiniteFuelVehicles = {
	-- Watercraft
	[38] = FiniteFuelGasTypes.Watercraft,
	[5] = FiniteFuelGasTypes.Watercraft,
	[6] = FiniteFuelGasTypes.Watercraft,
	[19] = FiniteFuelGasTypes.Watercraft,
	[45] = FiniteFuelGasTypes.Watercraft,
	[16] = FiniteFuelGasTypes.Watercraft,
	[25] = FiniteFuelGasTypes.Watercraft,
	[28] = FiniteFuelGasTypes.Watercraft,
	[50] = FiniteFuelGasTypes.Watercraft,
	[80] = FiniteFuelGasTypes.Watercraft,
	[27] = FiniteFuelGasTypes.Watercraft,
	[88] = FiniteFuelGasTypes.Watercraft,
	[69] = FiniteFuelGasTypes.Watercraft,
	[53] = FiniteFuelGasTypes.Watercraft,
	-- Planes
	[59] = FiniteFuelGasTypes.Aircraft,
	[81] = FiniteFuelGasTypes.Aircraft,
	[51] = FiniteFuelGasTypes.Aircraft,
	[30] = FiniteFuelGasTypes.Aircraft,
	[34] = FiniteFuelGasTypes.Aircraft,
	[85] = FiniteFuelGasTypes.Aircraft,
	[39] = FiniteFuelGasTypes.Aircraft,
	[24] = FiniteFuelGasTypes.Aircraft,
	-- Helicopters
	[3] = FiniteFuelGasTypes.Aircraft,
	[14] = FiniteFuelGasTypes.Aircraft,
	[67] = FiniteFuelGasTypes.Aircraft,
	[37] = FiniteFuelGasTypes.Aircraft,
	[57] = FiniteFuelGasTypes.Aircraft,
	[64] = FiniteFuelGasTypes.Aircraft,
	[65] = FiniteFuelGasTypes.Aircraft,
	[62] = FiniteFuelGasTypes.Aircraft
}

FiniteFuelVehicleKeys = {
	[Action.Accelerate] = true,
	[Action.Reverse] = true,
	[Action.BoatBackward] = true,
	[Action.BoatForward] = true,
	[Action.HeliBackward] = true,
	[Action.HeliForward] = true,
	[Action.HeliIncAltitude] = true,
	[Action.PlaneIncTrust] = true
}

-- The tank sizes are calculated by (vehicle mass / value)
FiniteFuelTankSizeFormulas = {
	[FiniteFuelGasTypes.Car] = 2,
	[FiniteFuelGasTypes.Watercraft] = 2,
	[FiniteFuelGasTypes.Aircraft] = 2
}

-- Drainage is calculates by
-- idle: (vehicle mass * value)
-- speeding: (vehicle mass * value) * velocity
FiniteFuelDrainageFormulas = {
	[FiniteFuelGasTypes.Car] = {
		idle = 0.00001,
		accelerate = 0.0000025
	},
	[FiniteFuelGasTypes.Watercraft] = {
		idle = 0.00001,
		accelerate = 0.0000025
	},
	[FiniteFuelGasTypes.Aircraft] = {
		idle = 0.00003,
		accelerate = 0.0000025
	},
}