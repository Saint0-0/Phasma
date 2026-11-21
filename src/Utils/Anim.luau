--[[
	Phasma/Utils/Anim.luau

	Frame-rate independent easing for the canvas elements. The ESP runs its own
	scalar tracks rather than one tween per channel, so the cost stays flat and
	the same tracks drive every element.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Anim = {}

local function clamp01(value)
	if value < 0 then
		return 0
	elseif value > 1 then
		return 1
	end
	return value
end

-- Moves `current` toward `target`. `speed` is a per-second rate: larger values
-- settle sooner, and 0 snaps. Kept for callers that want a convergence rate
-- rather than a fixed duration.
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

-- Steps a 0..1 track by `delta / duration` toward `target`, never overshooting.
-- A non-positive duration snaps, which is how a disabled animation behaves.
function Anim.step(current, target, duration, delta)
	if not duration or duration <= 0 or not delta or delta <= 0 then
		return target
	end
	local distance = target - current
	if math.abs(distance) <= 0.0001 then
		return target
	end
	local amount = delta / duration
	if distance > 0 then
		return math.min(current + amount, target)
	end
	return math.max(current - amount, target)
end

-- Ease-out cubic: fast departure, soft landing. The default for fades and
-- slides because it reads as motion rather than a linear ramp.
function Anim.cubic(value)
	local t = clamp01(value)
	local inverse = 1 - t
	return 1 - inverse * inverse * inverse
end

-- Ease-out back: overshoots past 1 before settling, which gives the box pop
-- its snap. `overshoot` of 0 is a plain cubic.
function Anim.back(value, overshoot)
	local t = clamp01(value)
	local strength = overshoot or 1.4
	local c = strength + 1
	local p = t - 1
	return 1 + c * p * p * p + strength * p * p
end

return Anim
