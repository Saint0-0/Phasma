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
	-- Occluded targets keep drawing with a shared tint instead of vanishing.
	-- Applies only while VisibilityCheck is on.
	ShowOccluded = true,
	OccludedColor = Color3.fromRGB(132, 140, 156),
	OccludedTransparency = 0.45,
	IgnoreLocal = true,
	IncludeNPCs = false,
	-- Players with a Team take their TeamColor for the box, name, tracer,
	-- skeleton and head dot. NPCs and teamless players keep the settings colours.
	TeamColor = true,
	-- Far targets dim slightly instead of staying at full brightness.
	FadeWithDistance = true,
	FadeFloor = 0.72,

	-- Target-level transitions. Exponential convergence rather than
	-- TweenService: Drawing objects are not Instances.
	Animations = {
		Enabled = true,
		-- Higher converges faster; 0 snaps.
		Speed = 12,
		-- Pixels the name and distance slide while fading in.
		Slide = 8,
		-- Fraction the box shrinks by at the start of a fade-in.
		Pop = 0.06,
		Tracer = true,
		Arrow = true,
	},

	-- Optional target whitelist/blacklist and per-frame cap.
	Filters = {
		Enabled = false,
		Whitelist = {},
		Blacklist = {},
		NameContains = "",
		-- 0 keeps every matching target.
		MaxTargets = 0,
		-- Distance, Health or Name.
		Priority = "Distance",
	},

	-- Cheap detail beyond DetailDistance: hide the expensive elements and
	-- rebuild far targets less often.
	LOD = {
		Enabled = true,
		DetailDistance = 600,
		Skeleton = false,
		Chips = false,
		Tracer = false,
		UpdateInterval = 0.05,
	},

	-- Object ESP: models or parts matched by name, class or CollectionService
	-- tag, drawn with Box, Name, Distance and Arrow.
	Objects = {
		Enabled = false,
		MaxDistance = 1000,
		ScanInterval = 0.5,
		Names = {},
		Classes = { "Model" },
		Tags = {},
		Color = Palette.Muted,
	},

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
		-- A wide, faint outline behind the box reads as a soft glow.
		Glow = true,
		GlowThickness = 3,
		GlowTransparency = 0.88,
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
		Background = true,
		BackgroundColor = Color3.fromRGB(10, 12, 16),
		BackgroundTransparency = 0.55,
		Padding = 4,
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
		Background = true,
		BackgroundColor = Color3.fromRGB(10, 12, 16),
		BackgroundTransparency = 0.55,
		Padding = 4,
	},

	Health = {
		Enabled = true,
		Width = 3,
		Gap = 6,
		Transparency = 0.05,
		Background = Color3.fromRGB(10, 12, 16),
		BackgroundTransparency = 0.65,
		ShowText = false,
		Percent = false,
		TextSize = 11,
		-- "Vertical" is the classic bar beside the box; "Horizontal" is a
		-- strip under it.
		Style = "Vertical",
		-- Left, Right, Above or Below, relative to the bar.
		TextSide = "Left",
		-- Higher converges faster. 0 disables smoothing.
		Smoothing = 14,
		Rounded = true,
		-- Breathe the fill when the target is below a quarter health.
		Pulse = true,
		-- Optional second bar from a Humanoid attribute, for games that
		-- expose armour or shields.
		Secondary = {
			Enabled = false,
			Attribute = "Armor",
			MaxAttribute = "MaxArmor",
			Color = Color3.fromRGB(120, 180, 255),
			Transparency = 0.2,
		},
	},

	Tracer = {
		Enabled = true,
		Color = Palette.Tracer,
		Thickness = 1,
		Transparency = 0.35,
		-- Bottom, Top, Left, Right, Center or Mouse.
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
		-- Custom, Solid, Outline, Glow or Soft. A preset overrides the four
		-- colour/transparency keys below.
		Preset = "Custom",
		UseTeamColor = true,
		-- The engine only keeps 31 Highlights alive.
		MaxInstances = 31,
		Fill = Palette.HighlightFill,
		Outline = Palette.HighlightOutline,
		FillTransparency = 0.85,
		OutlineTransparency = 0.35,
		DepthMode = "AlwaysOnTop",
	},

	-- Small chevron above the box showing where the target is facing.
	Direction = {
		Enabled = true,
		Color = Palette.Accent,
		Size = 6,
		Thickness = 2,
		Transparency = 0.1,
		Offset = 4,
	},

	-- Edge chevrons for targets outside the viewport, including behind you.
	Arrow = {
		Enabled = true,
		Color = Palette.Accent,
		Size = 9,
		Thickness = 2,
		Transparency = 0.1,
		-- Distance from the screen edge to the arrow tip.
		Offset = 16,
		-- Shows the target distance just inside the arrow.
		Label = true,
		TextSize = 11,
		-- Distance from the tip back toward the viewport centre.
		TextGap = 28,
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
