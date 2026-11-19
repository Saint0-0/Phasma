--[[
	Phasma/example/Phasma_Test.client.luau

	Showcase config for the test place. RightShift toggles the ESP,
	RightControl toggles the visibility check.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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
print("[Phasma] RightShift toggles the ESP, RightControl toggles the visibility check.")

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.RightShift then
		print("[Phasma] ESP", esp:Toggle() and "on" or "off")
	elseif input.KeyCode == Enum.KeyCode.RightControl then
		esp.Settings.VisibilityCheck = not esp.Settings.VisibilityCheck
		print("[Phasma] visibility check", esp.Settings.VisibilityCheck and "on" or "off")
	end
end)
