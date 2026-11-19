--[[
	Phasma/Constants.luau

	Shared constants: version, overlay identity, fonts and the default palette.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = {}

Constants.Version = "0.6.0"
Constants.Name = "Phasma"

-- Overlay identity. The GUI backend uses these for its ScreenGui unless
-- Security.RandomizeNames replaces them with a random tag.
Constants.ScreenGuiName = "Phasma"
Constants.DisplayOrder = 999999
Constants.Font = Enum.Font.GothamBold
Constants.FontMedium = Enum.Font.GothamMedium
Constants.OutlineColor = Color3.fromRGB(0, 0, 0)

-- Drawing text fonts are numeric; 2 is Plex on the common executors.
Constants.DrawingFont = 2

-- Cool, desaturated palette. Text stays near-white, the accent is a soft
-- cyan, and the fills are dark enough to read against any scene.
Constants.Palette = {
	Text = Color3.fromRGB(238, 243, 252),
	Muted = Color3.fromRGB(146, 158, 180),
	Accent = Color3.fromRGB(124, 196, 255),
	Box = Color3.fromRGB(198, 220, 255),
	Tracer = Color3.fromRGB(124, 196, 255),
	Skeleton = Color3.fromRGB(188, 208, 240),
	HeadDot = Color3.fromRGB(246, 249, 255),
	HealthLow = Color3.fromRGB(244, 82, 92),
	HealthMid = Color3.fromRGB(245, 184, 75),
	HealthHigh = Color3.fromRGB(74, 222, 128),
	HighlightFill = Color3.fromRGB(108, 172, 255),
	HighlightOutline = Color3.fromRGB(198, 224, 255),
}

return Constants
