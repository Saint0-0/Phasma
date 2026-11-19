--[[
	Phasma/Core/Canvas.luau

	Picks the rendering backend. Drawing first, ScreenGui everywhere else.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local DrawingCanvas = require("./Canvas/DrawingCanvas")
local GuiCanvas = require("./Canvas/GuiCanvas")

local Canvas = {}

function Canvas.new(security)
	if DrawingCanvas.available() then
		return DrawingCanvas.new()
	end
	return GuiCanvas.new(security)
end

return Canvas
