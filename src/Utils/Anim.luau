--[[
	Phasma/Utils/Anim.luau

	Frame-rate independent easing for the canvas elements. TweenService only
	animates Instances, so the ESP uses the same exponential convergence as the
	health bar: no tweens to allocate and identical behaviour on both backends.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Anim = {}

-- Moves `current` toward `target`. `speed` is a per-second rate: larger values
-- settle sooner, and 0 snaps.
function Anim.approach(current, target, speed, delta)
	if not speed or speed <= 0 or not delta or delta <= 0 then
		return target
	end
	local nextValue = current + (target - current) * (1 - math.exp(-speed * delta))
	if math.abs(target - nextValue) < 0.001 then
		return target
	end
	return nextValue
end

return Anim
