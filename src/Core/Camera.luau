--[[
	Phasma/Core/Camera.luau

	Camera lookup and world-to-screen projection. Elements only ever see
	Vector2 screen coordinates.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Camera = {}

function Camera.get()
	return workspace.CurrentCamera
end

-- Returns nil when the point sits behind the camera, where projection flips.
function Camera.project(camera, world)
	local point, onScreen = camera:WorldToScreenPoint(world)
	if point.Z <= 0 then
		return nil, false
	end
	return Vector2.new(point.X, point.Y), onScreen
end

function Camera.viewport(camera)
	return camera.ViewportSize
end

return Camera
