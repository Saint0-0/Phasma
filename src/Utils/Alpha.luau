--[[
	Phasma/Utils/Alpha.luau

	Distance fade helper. Elements pass their configured transparency and the
	frame alpha from Target; far targets become gradually more transparent.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Alpha = {}

-- alpha 1 leaves the value untouched, alpha 0 makes it fully transparent.
function Alpha.apply(transparency, alpha)
	if not alpha or alpha >= 1 then
		return transparency
	end
	alpha = math.clamp(alpha, 0, 1)
	return transparency + (1 - transparency) * (1 - alpha)
end

return Alpha
