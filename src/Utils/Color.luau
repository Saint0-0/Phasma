--[[
	Phasma/Utils/Color.luau

	Colour helpers for the health bar and element tints.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Color = {}

local LOW = Color3.fromRGB(235, 72, 72)
local MID = Color3.fromRGB(235, 200, 92)
local HIGH = Color3.fromRGB(96, 214, 138)

-- 0 is red, 0.5 amber, 1 green.
function Color.health(alpha)
	alpha = math.clamp(alpha, 0, 1)
	if alpha < 0.5 then
		return LOW:Lerp(MID, alpha * 2)
	end
	return MID:Lerp(HIGH, (alpha - 0.5) * 2)
end

return Color
