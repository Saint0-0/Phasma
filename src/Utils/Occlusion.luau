--[[
	Phasma/Utils/Occlusion.luau

	Shared tint for occluded targets. When VisibilityCheck is on and
	ShowOccluded is enabled, elements keep drawing with a common colour and a
	little extra transparency instead of vanishing.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Occlusion = {}

function Occlusion.color(color, state, global)
	if state.Occluded and global then
		return global.OccludedColor or color
	end
	return color
end

function Occlusion.transparency(value, state, global)
	if state.Occluded and global then
		return math.clamp(value + (global.OccludedTransparency or 0.45), 0, 1)
	end
	return value
end

return Occlusion
