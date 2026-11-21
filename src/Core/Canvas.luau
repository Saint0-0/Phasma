--[[
	Phasma/Core/Canvas.luau

	Returns the ScreenGui canvas. It is the renderer that is verified in
	Studio, so every box style and element looks the same on an executor.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local GuiCanvas = require("./Canvas/GuiCanvas")

local Canvas = {}

function Canvas.new(security)
	return GuiCanvas.new(security)
end

return Canvas
