FiniteFuelVehicleTypes = {
	Car = 1,
	Watercraft = 2,
	Airplane = 3,
	Helicopter = 4
}

FiniteFuelVehicles = {
	-- Watercraft
	[38] = FiniteFuelVehicleTypes.Watercraft,
	[5] = FiniteFuelVehicleTypes.Watercraft,
	[6] = FiniteFuelVehicleTypes.Watercraft,
	[19] = FiniteFuelVehicleTypes.Watercraft,
	[45] = FiniteFuelVehicleTypes.Watercraft,
	[16] = FiniteFuelVehicleTypes.Watercraft,
	[25] = FiniteFuelVehicleTypes.Watercraft,
	[28] = FiniteFuelVehicleTypes.Watercraft,
	[50] = FiniteFuelVehicleTypes.Watercraft,
	[80] = FiniteFuelVehicleTypes.Watercraft,
	[27] = FiniteFuelVehicleTypes.Watercraft,
	[88] = FiniteFuelVehicleTypes.Watercraft,
	[69] = FiniteFuelVehicleTypes.Watercraft,
	[53] = FiniteFuelVehicleTypes.Watercraft,
	-- Airplanes
	[59] = FiniteFuelVehicleTypes.Airplane,
	[81] = FiniteFuelVehicleTypes.Airplane,
	[51] = FiniteFuelVehicleTypes.Airplane,
	[30] = FiniteFuelVehicleTypes.Airplane,
	[34] = FiniteFuelVehicleTypes.Airplane,
	[85] = FiniteFuelVehicleTypes.Airplane,
	[39] = FiniteFuelVehicleTypes.Airplane,
	[24] = FiniteFuelVehicleTypes.Airplane,
	-- Helicopters
	[3] = FiniteFuelVehicleTypes.Helicopter,
	[14] = FiniteFuelVehicleTypes.Helicopter,
	[67] = FiniteFuelVehicleTypes.Helicopter,
	[37] = FiniteFuelVehicleTypes.Helicopter,
	[57] = FiniteFuelVehicleTypes.Helicopter,
	[64] = FiniteFuelVehicleTypes.Helicopter,
	[65] = FiniteFuelVehicleTypes.Helicopter,
	[62] = FiniteFuelVehicleTypes.Helicopter
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

FiniteFuelDrainageFormulas = {
	[FiniteFuelVehicleTypes.Car] = {
		idle = 0.00001,
		accelerate = 0.0000025
	},
	[FiniteFuelVehicleTypes.Airplane] = {
		idle = 0.00003,
		accelerate = 0.0000025
	},
}
FiniteFuelDrainageFormulas[FiniteFuelVehicleTypes.Watercraft] = FiniteFuelDrainageFormulas[FiniteFuelVehicleTypes.Car] -- Same as for cars
FiniteFuelDrainageFormulas[FiniteFuelVehicleTypes.Helicopter] = FiniteFuelDrainageFormulas[FiniteFuelVehicleTypes.Airplane] -- Same as for airplanes