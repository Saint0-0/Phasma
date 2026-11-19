--[[
	Phasma/Constants.luau

	Shared constants: version, overlay identity, fonts and the default palette.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = {}

Constants.Version = "0.1.0"
Constants.Name = "Phasma"

-- Overlay identity. The GUI backend uses these for its ScreenGui.
Constants.ScreenGuiName = "Phasma"
Constants.DisplayOrder = 999999
Constants.Font = Enum.Font.GothamBold
Constants.OutlineColor = Color3.fromRGB(0, 0, 0)

-- Drawing text fonts are numeric; 2 is Plex on the common executors.
Constants.DrawingFont = 2

Constants.Palette = {
	Text = Color3.fromRGB(235, 238, 245),
	Accent = Color3.fromRGB(158, 198, 255),
	Box = Color3.fromRGB(220, 228, 245),
	Tracer = Color3.fromRGB(158, 198, 255),
	Skeleton = Color3.fromRGB(200, 214, 240),
	HeadDot = Color3.fromRGB(240, 244, 252),
	HighlightFill = Color3.fromRGB(140, 180, 255),
	HighlightOutline = Color3.fromRGB(220, 232, 255),
}

return Constants
