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
-- WorldToViewportPoint is the inset-free space: (0,0) is the top-left of the
-- viewport, which matches a ScreenGui with IgnoreGuiInset and the Drawing API.
-- WorldToScreenPoint would shift everything down by the top bar.
function Camera.project(camera, world)
	local point, onScreen = camera:WorldToViewportPoint(world)
	if point.Z <= 0 then
		return nil, false
	end
	return Vector2.new(point.X, point.Y), onScreen
end

return Camera
