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
	-- Seconds between visibility raycasts for one target. The result is reused
	-- in between, which keeps the cost flat on crowded servers.
	VisibilityInterval = 0.12,
	IgnoreLocal = true,
	IncludeNPCs = false,
	-- Far targets dim slightly instead of staying at full brightness.
	FadeWithDistance = true,
	FadeFloor = 0.72,

	Box = {
		Enabled = true,
		-- "Corners" is the modern bracket look; "Full" is a plain outline and
		-- "Both" draws the brackets over a faint outline.
		Style = "Corners",
		Color = Palette.Box,
		Thickness = 1,
		Transparency = 0.05,
		Filled = true,
		FillTransparency = 0.94,
		CornerScale = 0.22,
		CornerMin = 5,
		CornerMax = 16,
	},

	Name = {
		Enabled = true,
		Color = Palette.Text,
		TextSize = 12,
		Transparency = 0,
		Outline = true,
		OutlineTransparency = 0.45,
		UseDisplayName = true,
		Offset = 4,
	},

	Distance = {
		Enabled = true,
		Color = Palette.Muted,
		TextSize = 11,
		Transparency = 0,
		Outline = true,
		OutlineTransparency = 0.5,
		Offset = 3,
		Suffix = "m",
		Scale = 1,
	},

	Health = {
		Enabled = true,
		Width = 3,
		Gap = 6,
		Transparency = 0.05,
		Background = Color3.fromRGB(10, 12, 16),
		BackgroundTransparency = 0.65,
		ShowText = false,
		TextSize = 11,
		-- Higher converges faster. 0 disables smoothing.
		Smoothing = 14,
		Rounded = true,
	},

	Tracer = {
		Enabled = true,
		Color = Palette.Tracer,
		Thickness = 1,
		Transparency = 0.35,
		From = "Bottom",
	},

	Skeleton = {
		Enabled = true,
		Color = Palette.Skeleton,
		Thickness = 1,
		Transparency = 0.25,
		Joints = false,
		JointRadius = 2,
	},

	HeadDot = {
		Enabled = true,
		Color = Palette.HeadDot,
		Radius = 2.5,
		Filled = true,
		Transparency = 0.1,
	},

	Highlight = {
		Enabled = true,
		Fill = Palette.HighlightFill,
		Outline = Palette.HighlightOutline,
		FillTransparency = 0.85,
		OutlineTransparency = 0.35,
		DepthMode = "AlwaysOnTop",
	},

	-- Reduces casual detection only. Nothing client-side can hide from a
	-- determined anti-cheat, so treat this as noise reduction, not invisibility.
	Security = {
		Enabled = true,
		RandomizeNames = true,
		ProtectGui = true,
		HideHighlight = true,
	},
}

return Defaults
