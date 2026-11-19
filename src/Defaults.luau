--[[
	Phasma/Defaults.luau

	Default settings for CreateESP. Every key is optional; Config.resolve
	merges a user table over this one.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("./Constants")
local Palette = Constants.Palette

local Defaults = {
	Enabled = true,
	MaxDistance = 1000,
	TeamCheck = false,
	VisibilityCheck = false,
	IgnoreLocal = true,
	IncludeNPCs = false,

	Box = {
		Enabled = true,
		Color = Palette.Box,
		Thickness = 1,
		Transparency = 0.1,
		Filled = false,
	},

	Name = {
		Enabled = true,
		Color = Palette.Text,
		TextSize = 13,
		Transparency = 0,
		Outline = true,
		UseDisplayName = true,
		Offset = 3,
	},

	Distance = {
		Enabled = true,
		Color = Palette.Accent,
		TextSize = 12,
		Transparency = 0,
		Outline = true,
		Offset = 3,
		Suffix = "m",
		Scale = 1,
	},

	Health = {
		Enabled = true,
		Width = 3,
		Gap = 5,
		Transparency = 0.1,
		Background = Color3.fromRGB(15, 17, 22),
		BackgroundTransparency = 0.5,
		ShowText = false,
		TextSize = 11,
	},

	Tracer = {
		Enabled = true,
		Color = Palette.Tracer,
		Thickness = 1,
		Transparency = 0.25,
		From = "Bottom",
	},

	Skeleton = {
		Enabled = true,
		Color = Palette.Skeleton,
		Thickness = 1,
		Transparency = 0.2,
	},

	HeadDot = {
		Enabled = false,
		Color = Palette.HeadDot,
		Radius = 3,
		Filled = true,
		Transparency = 0.1,
	},

	Highlight = {
		Enabled = false,
		Fill = Palette.HighlightFill,
		Outline = Palette.HighlightOutline,
		FillTransparency = 0.65,
		OutlineTransparency = 0.15,
		DepthMode = "AlwaysOnTop",
	},
}

return Defaults
