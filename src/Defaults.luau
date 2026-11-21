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

	-- Target-level transitions. Time-based scalar tracks rather than one tween
	-- per channel. Every channel has its own switch, so any one of them can be
	-- left instant while the rest move.
	Animations = {
		Enabled = true,
		-- Duration multiplier: 2 is twice as fast, 0.5 is half speed, 0 snaps.
		Speed = 1,
		-- Fade the whole target in and out.
		Fade = true,
		FadeDuration = 0.25,
		-- Settle the box from slightly smaller with a soft overshoot.
		Pop = true,
		PopAmount = 0.14,
		PopDuration = 0.34,
		-- Slide the name and distance chips out from the box edge.
		Slide = true,
		SlideDistance = 14,
		SlideDuration = 0.3,
		-- Draw the corner brackets outward from their corners.
		Sweep = true,
		SweepDuration = 0.36,
		-- Grow the tracer from its origin to the target.
		Tracer = true,
		TracerDuration = 0.5,
		-- Slide the edge arrow in from outside the viewport.
		Arrow = true,
		ArrowDuration = 0.32,
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

	-- Draw one chosen target and ignore every other candidate. Target accepts
	-- a Player, Model, Humanoid or BasePart. Set it at runtime with
	-- esp:SetTarget(instance), esp:ClearTarget() or by assigning this value.
	-- Explicit focus bypasses filters, distance cutoffs and include flags.
	Focus = {
		Target = nil,
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
		-- Draw the edge arrow while an object is off screen.
		ShowArrow = true,
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
		-- A wide, faint line behind the tracer reads as light rather than a
		-- second line. The spark rides the tip while the tracer draws in.
		Glow = true,
		GlowThickness = 4,
		-- Added to the core transparency, so the glow stays fainter than the
		-- line it sits behind.
		GlowTransparency = 0.35,
		Spark = true,
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
