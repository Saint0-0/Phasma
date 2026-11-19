--[[
	Phasma/example/Phasma_Test.client.luau

	Showcase config for the test place.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Phasma = require(ReplicatedStorage:WaitForChild("Phasma"):WaitForChild("Init"))

local esp = Phasma:CreateESP({
	MaxDistance = 1200,
	TeamCheck = false,
	VisibilityCheck = false,
	IncludeNPCs = true, -- the test dummies are humanoid models, not players

	-- Target transitions: fade/pop/slide in, fade out, tracer draw-on and
	-- arrow slide. Element toggles stay instant.
	Animations = {
		Enabled = true,
		Speed = 12,
		Slide = 8,
		Tracer = true,
		Arrow = true,
	},

	-- Far targets get a cheaper element set and rebuild less often.
	LOD = {
		Enabled = true,
		DetailDistance = 600,
		Skeleton = false,
		Chips = false,
		Tracer = false,
		UpdateInterval = 0.05,
	},

	-- The test range tags a few loot models with "PhasmaLoot".
	Objects = {
		Enabled = true,
		MaxDistance = 800,
		Tags = { "PhasmaLoot" },
		Classes = { "Model" },
		Color = Color3.fromRGB(255, 206, 132),
		-- Off-screen objects keep the edge arrow by default.
		ShowArrow = true,
	},

	Box = {
		Enabled = true,
		Color = Color3.fromRGB(170, 205, 255),
		Thickness = 1,
		Transparency = 0.05,
	},
	Name = {
		Enabled = true,
		UseDisplayName = true,
	},
	Distance = {
		Enabled = true,
	},
	Health = {
		Enabled = true,
		ShowText = true,
		Percent = true,
		Style = "Vertical",
		TextSide = "Left",
	},
	Tracer = {
		Enabled = true,
		-- Bottom, Top, Left, Right, Center or Mouse.
		From = "Bottom",
	},
	Skeleton = {
		Enabled = true,
	},
	HeadDot = {
		Enabled = true,
	},
	Direction = {
		Enabled = true,
	},
	Highlight = {
		Enabled = true,
		Preset = "Solid",
		UseTeamColor = true,
	},
	Arrow = {
		Enabled = true,
		Label = true,
	},
})

-- Named looks: "Default", "Minimal", "Clean", "Sniper", "Rage", "Chams",
-- "Performance". Applying one only touches the appearance blocks.
-- esp:ApplyPreset("Clean")

print(("[Phasma] v%s running on the %s backend."):format(Phasma.Version, esp.Canvas.Kind))
print(("[Phasma] presets: %s"):format(table.concat(esp:ListPresets(), ", ")))
