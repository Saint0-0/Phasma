--[[
	Phasma/Utils/Color.luau

	Colour helpers for the health bar and element tints.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("../Constants")
local Palette = Constants.Palette

local Color = {}

-- 0 is red, 0.5 amber, 1 green.
function Color.health(alpha)
	alpha = math.clamp(alpha, 0, 1)
	if alpha < 0.5 then
		return Palette.HealthLow:Lerp(Palette.HealthMid, alpha * 2)
	end
	return Palette.HealthMid:Lerp(Palette.HealthHigh, (alpha - 0.5) * 2)
end

return Color
