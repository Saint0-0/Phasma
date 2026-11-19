--[[
	Phasma/dev/PhasmaDebug.client.luau

	Dev-only control panel for the test place. It owns the single ESP instance
	and exposes every element toggle plus the distance cutoff.

	Nothing under src/ requires this file, so it never reaches dist/Phasma.luau
	or dist/Phasma.rbxm. It exists only inside the test place.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Phasma = require(ReplicatedStorage:WaitForChild("Phasma"):WaitForChild("Init"))

local COLORS = {
	Panel = Color3.fromRGB(18, 20, 26),
	Row = Color3.fromRGB(26, 29, 37),
	Text = Color3.fromRGB(226, 231, 240),
	Muted = Color3.fromRGB(138, 146, 162),
	Accent = Color3.fromRGB(158, 198, 255),
	Stroke = Color3.fromRGB(54, 60, 74),
	PillOff = Color3.fromRGB(48, 53, 64),
	KnobOn = Color3.fromRGB(18, 20, 26),
	KnobOff = Color3.fromRGB(150, 158, 172),
}

local ELEMENTS = { "Box", "Name", "Distance", "Health", "Tracer", "Skeleton", "HeadDot", "Highlight" }
local DISTANCES = { 250, 500, 1000, 2000 }

local esp = Phasma:CreateESP({
	MaxDistance = 1200,
	IncludeNPCs = true, -- the dummies are humanoid models, not players
	Box = { Enabled = true, Color = Color3.fromRGB(170, 205, 255) },
	Name = { Enabled = true },
	Distance = { Enabled = true },
	Health = { Enabled = true },
	Tracer = { Enabled = true, From = "Bottom" },
	Skeleton = { Enabled = true },
	HeadDot = { Enabled = true },
	Highlight = { Enabled = true, FillTransparency = 0.75, OutlineTransparency = 0.1 },
})

local refreshers = {}

local function rounded(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
	return corner
end

-- Rows read their value through get() and write through set(), so the panel
-- never needs a copy of the settings table.
local function toggleRow(parent, order, label, get, set)
	local row = Instance.new("TextButton")
	row.Name = label
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundColor3 = COLORS.Row
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	row.Parent = parent
	rounded(row, 4)

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromOffset(10, 0)
	text.Size = UDim2.new(1, -60, 1, 0)
	text.Font = Enum.Font.GothamMedium
	text.TextSize = 12
	text.TextColor3 = COLORS.Text
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.Text = label
	text.Parent = row

	local pill = Instance.new("Frame")
	pill.AnchorPoint = Vector2.new(1, 0.5)
	pill.Position = UDim2.new(1, -10, 0.5, 0)
	pill.Size = UDim2.fromOffset(28, 14)
	pill.BorderSizePixel = 0
	pill.Parent = row
	rounded(pill, 7)

	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Size = UDim2.fromOffset(10, 10)
	knob.BorderSizePixel = 0
	knob.Parent = pill
	rounded(knob, 5)

	local function refresh()
		local on = get() == true
		pill.BackgroundColor3 = on and COLORS.Accent or COLORS.PillOff
		knob.BackgroundColor3 = on and COLORS.KnobOn or COLORS.KnobOff
		knob.Position = on and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
	end

	row.MouseButton1Click:Connect(function()
		set(not get())
		for _, refreshRow in ipairs(refreshers) do
			refreshRow()
		end
	end)

	refreshers[#refreshers + 1] = refresh
	refresh()
	return row
end

local function distanceRow(parent, order)
	local holder = Instance.new("Frame")
	holder.Name = "MaxDistance"
	holder.LayoutOrder = order
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 24)
	holder.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder

	local buttons = {}

	local function refresh()
		for value, button in pairs(buttons) do
			local active = esp.Settings.MaxDistance == value
			button.BackgroundColor3 = active and COLORS.Accent or COLORS.Row
			button.TextColor3 = active and COLORS.KnobOn or COLORS.Text
		end
	end

	for index, value in ipairs(DISTANCES) do
		local button = Instance.new("TextButton")
		button.Name = tostring(value)
		button.LayoutOrder = index
		button.Size = UDim2.new(0.25, -3, 1, 0)
		button.BackgroundColor3 = COLORS.Row
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 11
		button.TextColor3 = COLORS.Text
		button.Text = tostring(value)
		button.Parent = holder
		rounded(button, 4)

		button.MouseButton1Click:Connect(function()
			esp:SetMaxDistance(value)
			for _, refreshRow in ipairs(refreshers) do
				refreshRow()
			end
		end)

		buttons[value] = button
	end

	refreshers[#refreshers + 1] = refresh
	refresh()
end

local function sectionLabel(parent, order, text)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, 16)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 10
	label.TextColor3 = COLORS.Muted
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = parent
	return label
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "PhasmaDebug"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000000
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Position = UDim2.fromOffset(24, 24)
panel.Size = UDim2.fromOffset(248, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = COLORS.Panel
panel.BorderSizePixel = 0
panel.Parent = gui
rounded(panel, 8)

local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.Stroke
stroke.Thickness = 1
stroke.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local order = 0
local function nextOrder()
	order = order + 1
	return order
end

local title = Instance.new("Frame")
title.Name = "Title"
title.LayoutOrder = nextOrder()
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 24)
title.Parent = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, -44, 1, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 12
titleLabel.TextColor3 = COLORS.Text
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "PHASMA  v" .. Phasma.Version
titleLabel.Parent = title

local hint = Instance.new("TextLabel")
hint.AnchorPoint = Vector2.new(1, 0.5)
hint.Position = UDim2.fromScale(1, 0.5)
hint.Size = UDim2.fromOffset(44, 24)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.GothamMedium
hint.TextSize = 10
hint.TextColor3 = COLORS.Muted
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Text = "RAlt"
hint.Parent = title

sectionLabel(panel, nextOrder(), "GLOBAL")
toggleRow(panel, nextOrder(), "ESP", function()
	return esp.Settings.Enabled
end, function(value)
	esp:SetEnabled(value)
end)
toggleRow(panel, nextOrder(), "Visibility check", function()
	return esp.Settings.VisibilityCheck
end, function(value)
	esp.Settings.VisibilityCheck = value
end)
toggleRow(panel, nextOrder(), "Team check", function()
	return esp.Settings.TeamCheck
end, function(value)
	esp.Settings.TeamCheck = value
end)
toggleRow(panel, nextOrder(), "NPCs", function()
	return esp.Settings.IncludeNPCs
end, function(value)
	esp.Settings.IncludeNPCs = value
end)

sectionLabel(panel, nextOrder(), "ELEMENTS")
for _, name in ipairs(ELEMENTS) do
	toggleRow(panel, nextOrder(), name, function()
		return esp.Settings[name].Enabled
	end, function(value)
		esp.Settings[name].Enabled = value
	end)
end

sectionLabel(panel, nextOrder(), "MAX DISTANCE")
distanceRow(panel, nextOrder())

local status = Instance.new("TextLabel")
status.Name = "Status"
status.LayoutOrder = nextOrder()
status.BackgroundTransparency = 1
status.Size = UDim2.new(1, 0, 0, 16)
status.Font = Enum.Font.GothamMedium
status.TextSize = 10
status.TextColor3 = COLORS.Muted
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "starting"
status.Parent = panel

-- The entry map is internal; a dev panel may read it for a live count.
local elapsed = 0
RunService.Heartbeat:Connect(function(delta)
	elapsed = elapsed + delta
	if elapsed < 0.25 then
		return
	end
	elapsed = 0

	local count = 0
	for _ in pairs(esp._entries) do
		count = count + 1
	end
	status.Text = string.format("%s backend  |  %d targets", esp.Canvas.Kind, count)
end)

local dragging = false
local dragStart = nil
local dragOrigin = nil

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		dragOrigin = panel.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		panel.Position = UDim2.new(
			dragOrigin.X.Scale,
			dragOrigin.X.Offset + delta.X,
			dragOrigin.Y.Scale,
			dragOrigin.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightAlt then
		gui.Enabled = not gui.Enabled
	end
end)

print(string.format("[Phasma] debug panel ready on the %s backend.", esp.Canvas.Kind))
