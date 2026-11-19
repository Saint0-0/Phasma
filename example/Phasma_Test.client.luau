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
		ShowText = false,
	},
	Tracer = {
		Enabled = true,
		From = "Bottom",
	},
	Skeleton = {
		Enabled = true,
	},
	HeadDot = {
		Enabled = true,
	},
	Highlight = {
		Enabled = true,
		FillTransparency = 0.75,
		OutlineTransparency = 0.1,
	},
})

print(("[Phasma] v%s running on the %s backend."):format(Phasma.Version, esp.Canvas.Kind))
