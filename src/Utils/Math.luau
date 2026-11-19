--[[
	Phasma/Utils/Math.luau

	Small numeric helpers shared by the elements.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Math = {}

function Math.clamp01(value)
	if value < 0 then
		return 0
	elseif value > 1 then
		return 1
	end
	return value
end

function Math.lerp(a, b, alpha)
	return a + (b - a) * alpha
end

-- Rounds to the nearest step; a step of 0 leaves the value alone.
function Math.snap(value, step)
	if step <= 0 then
		return value
	end
	return math.floor(value / step + 0.5) * step
end

return Math
