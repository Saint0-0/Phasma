--[[
	Phasma/dev/PhasmaDebug.client.luau

	Dev-only control panel for the test place. One draggable window with a tab
	bar and a scrolling page per group: ESP, STYLE, ELEMENTS and COLOURS. It
	owns the single ESP instance for the place.

	Nothing under src/ requires this file, so it never reaches dist/Phasma.luau
	or dist/Phasma.rbxm. It exists only inside the test place.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

print("[Phasma] debug script started")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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

local ELEMENTS = { "Box", "Name", "Distance", "Health", "Tracer", "Skeleton", "HeadDot", "Highlight", "Arrow" }
local DISTANCES = { 250, 500, 1000, 2000 }
local TABS = { "ESP", "STYLE", "ELEMENTS", "COLOURS" }

-- Assigned once the library loads, so the row builders can close over it.
local esp

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
	row.Size = UDim2.new(1, 0, 0, 22)
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
	text.Active = true
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

	-- A click can arrive from the button or from the label on top of it; the
	-- debounce keeps one press from toggling twice.
	local last = 0
	local function toggle()
		local now = os.clock()
		if now - last < 0.15 then
			return
		end
		last = now
		set(not get())
		refresh()
		print(string.format("[Phasma] %s = %s", label, tostring(get())))
	end

	row.MouseButton1Click:Connect(toggle)
	text.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			toggle()
		end
	end)

	refresh()
	return row
end

local function distanceRow(parent, order)
	local holder = Instance.new("Frame")
	holder.Name = "MaxDistance"
	holder.LayoutOrder = order
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 22)
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
			refresh()
		end)

		buttons[value] = button
	end

	refresh()
	return holder
end

local function sectionLabel(parent, order, text)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, 14)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 10
	label.TextColor3 = COLORS.Muted
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = parent
	return label
end

-- The shell is built before the library is touched. If Phasma is missing or
-- errors, the window still appears and says so instead of failing silently.
local previous = playerGui:FindFirstChild("PhasmaDebug")
if previous then
	previous:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "PhasmaDebug"
-- Inset-aware: the panel is UI, so it sits inside the safe area, below the
-- top bar, instead of being drawn under it.
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = true
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Position = UDim2.fromOffset(16, 16)
panel.Size = UDim2.fromOffset(300, 520)
panel.BackgroundColor3 = COLORS.Panel
panel.BorderSizePixel = 0
panel.Active = true
panel.Visible = true
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

local title = Instance.new("Frame")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Active = true
title.Size = UDim2.new(1, 0, 0, 24)
title.Parent = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 12
titleLabel.TextColor3 = COLORS.Text
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = "PHASMA"
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

local tabBar = Instance.new("Frame")
tabBar.Name = "Tabs"
tabBar.Position = UDim2.fromOffset(0, 30)
tabBar.Size = UDim2.new(1, 0, 0, 26)
tabBar.BackgroundTransparency = 1
tabBar.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabBar

-- Pages are clipped to this frame; each page is a ScrollingFrame of its own.
local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(0, 62)
content.Size = UDim2.new(1, 0, 1, -82)
content.BackgroundTransparency = 1
content.ClipsDescendants = true
content.Parent = panel

local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(0, 1)
status.Position = UDim2.fromScale(0, 1)
status.Size = UDim2.new(1, 0, 0, 16)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamMedium
status.TextSize = 10
status.TextColor3 = COLORS.Muted
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "loading library"
status.Parent = panel

local tabButtons = {}
local pages = {}
local orders = {}

local function selectTab(name)
	for key, page in pairs(pages) do
		page.Visible = key == name
	end
	for key, button in pairs(tabButtons) do
		local on = key == name
		button.BackgroundColor3 = on and COLORS.Accent or COLORS.Row
		button.TextColor3 = on and COLORS.KnobOn or COLORS.Text
	end
end

for index, name in ipairs(TABS) do
	local button = Instance.new("TextButton")
	button.Name = name
	button.LayoutOrder = index
	button.Size = UDim2.new(0.25, -3, 1, 0)
	button.BackgroundColor3 = COLORS.Row
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 10
	button.TextColor3 = COLORS.Text
	button.Text = name
	button.Parent = tabBar
	rounded(button, 4)
	button.MouseButton1Click:Connect(function()
		selectTab(name)
	end)
	tabButtons[name] = button
end

local function nextOrder(page)
	orders[page] = (orders[page] or 0) + 1
	return orders[page]
end

local function makePage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ClipsDescendants = true
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = COLORS.Stroke
	page.ScrollBarImageTransparency = 0.2
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.CanvasSize = UDim2.fromOffset(0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page

	pages[name] = page
	return page
end

-- Library lookup is bounded and reported, so a missing bundle cannot hang the
-- panel. rojo serve must be running and dist/Phasma.luau must exist.
local folder = ReplicatedStorage:WaitForChild("Phasma", 10)
local init = folder and folder:WaitForChild("Init", 10)
local loaded, Phasma = pcall(function()
	if not init then
		error("ReplicatedStorage.Phasma.Init was not found (is rojo serving dist/Phasma.luau?)")
	end
	return require(init)
end)

if not loaded then
	status.Text = "library missing - see Output"
	warn("[Phasma] debug panel: " .. tostring(Phasma))
	return
end

titleLabel.Text = "PHASMA  v" .. Phasma.Version

-- One frame first, so any script that creates an ESP on startup has already
-- done so. StopAll then removes every earlier engine, leaving exactly one.
task.wait()
if Phasma.StopAll then
	Phasma:StopAll()
end

local created, result = pcall(function()
	return Phasma:CreateESP({
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
end)

if not created then
	status.Text = "CreateESP failed - see Output"
	warn("[Phasma] debug panel: " .. tostring(result))
	return
end

esp = result

-- ESP ----------------------------------------------------------------------
local espPage = makePage("ESP")
sectionLabel(espPage, nextOrder(espPage), "GLOBAL")
toggleRow(espPage, nextOrder(espPage), "ESP", function()
	return esp.Settings.Enabled
end, function(value)
	esp:SetEnabled(value)
end)
toggleRow(espPage, nextOrder(espPage), "Visibility check", function()
	return esp.Settings.VisibilityCheck
end, function(value)
	esp.Settings.VisibilityCheck = value
end)
toggleRow(espPage, nextOrder(espPage), "Team check", function()
	return esp.Settings.TeamCheck
end, function(value)
	esp.Settings.TeamCheck = value
end)
toggleRow(espPage, nextOrder(espPage), "NPCs", function()
	return esp.Settings.IncludeNPCs
end, function(value)
	esp.Settings.IncludeNPCs = value
end)
toggleRow(espPage, nextOrder(espPage), "Occluded", function()
	return esp.Settings.ShowOccluded
end, function(value)
	esp.Settings.ShowOccluded = value
end)
sectionLabel(espPage, nextOrder(espPage), "MAX DISTANCE")
distanceRow(espPage, nextOrder(espPage))

-- STYLE --------------------------------------------------------------------
local stylePage = makePage("STYLE")
sectionLabel(stylePage, nextOrder(stylePage), "LOOK")
toggleRow(stylePage, nextOrder(stylePage), "Team colours", function()
	return esp.Settings.TeamColor
end, function(value)
	esp.Settings.TeamColor = value
end)
toggleRow(stylePage, nextOrder(stylePage), "Box glow", function()
	return esp.Settings.Box.Glow
end, function(value)
	esp.Settings.Box.Glow = value
end)
toggleRow(stylePage, nextOrder(stylePage), "Health pulse", function()
	return esp.Settings.Health.Pulse
end, function(value)
	esp.Settings.Health.Pulse = value
end)
toggleRow(stylePage, nextOrder(stylePage), "Health %", function()
	return esp.Settings.Health.Percent
end, function(value)
	esp.Settings.Health.Percent = value
	esp.Settings.Health.ShowText = value
end)
toggleRow(stylePage, nextOrder(stylePage), "Name chip", function()
	return esp.Settings.Name.Background
end, function(value)
	esp.Settings.Name.Background = value
end)
toggleRow(stylePage, nextOrder(stylePage), "Distance chip", function()
	return esp.Settings.Distance.Background
end, function(value)
	esp.Settings.Distance.Background = value
end)
toggleRow(stylePage, nextOrder(stylePage), "Joint dots", function()
	return esp.Settings.Skeleton.Joints
end, function(value)
	esp.Settings.Skeleton.Joints = value
end)

-- ELEMENTS -----------------------------------------------------------------
local elementsPage = makePage("ELEMENTS")
sectionLabel(elementsPage, nextOrder(elementsPage), "ELEMENTS")
for _, name in ipairs(ELEMENTS) do
	toggleRow(elementsPage, nextOrder(elementsPage), name, function()
		return esp.Settings[name].Enabled
	end, function(value)
		esp.Settings[name].Enabled = value
	end)
end

-- COLOURS ------------------------------------------------------------------
local COLOUR_TARGETS = {
	{ Name = "Box", Table = "Box", Key = "Color" },
	{ Name = "Name", Table = "Name", Key = "Color" },
	{ Name = "Distance", Table = "Distance", Key = "Color" },
	{ Name = "Tracer", Table = "Tracer", Key = "Color" },
	{ Name = "Skeleton", Table = "Skeleton", Key = "Color" },
	{ Name = "HeadDot", Table = "HeadDot", Key = "Color" },
	{ Name = "Health bg", Table = "Health", Key = "Background" },
	{ Name = "HL fill", Table = "Highlight", Key = "Fill" },
	{ Name = "HL outline", Table = "Highlight", Key = "Outline" },
	{ Name = "Arrow", Table = "Arrow", Key = "Color" },
}

local colourPage = makePage("COLOURS")
sectionLabel(colourPage, nextOrder(colourPage), "TARGET")

local chipHolder = Instance.new("Frame")
chipHolder.LayoutOrder = nextOrder(colourPage)
chipHolder.BackgroundTransparency = 1
chipHolder.Size = UDim2.new(1, 0, 0, 126)
chipHolder.Parent = colourPage

local chipGrid = Instance.new("UIGridLayout")
chipGrid.CellSize = UDim2.new(0.5, -3, 0, 22)
chipGrid.CellPadding = UDim2.fromOffset(6, 4)
chipGrid.SortOrder = Enum.SortOrder.LayoutOrder
chipGrid.Parent = chipHolder

local preview = Instance.new("Frame")
preview.LayoutOrder = nextOrder(colourPage)
preview.Size = UDim2.new(1, 0, 0, 30)
preview.BackgroundColor3 = Color3.new(1, 1, 1)
preview.BorderSizePixel = 0
preview.Parent = colourPage
rounded(preview, 6)

local previewStroke = Instance.new("UIStroke")
previewStroke.Color = COLORS.Stroke
previewStroke.Thickness = 1
previewStroke.Parent = preview

local previewName = Instance.new("TextLabel")
previewName.BackgroundTransparency = 1
previewName.Position = UDim2.fromOffset(10, 0)
previewName.Size = UDim2.new(0.5, -10, 1, 0)
previewName.Font = Enum.Font.GothamMedium
previewName.TextSize = 11
previewName.TextColor3 = COLORS.KnobOn
previewName.TextXAlignment = Enum.TextXAlignment.Left
previewName.Text = "Box"
previewName.Parent = preview

local previewValue = Instance.new("TextLabel")
previewValue.AnchorPoint = Vector2.new(1, 0)
previewValue.Position = UDim2.fromScale(1, 0)
previewValue.Size = UDim2.new(0.5, -10, 1, 0)
previewValue.BackgroundTransparency = 1
previewValue.Font = Enum.Font.GothamBold
previewValue.TextSize = 11
previewValue.TextColor3 = COLORS.KnobOn
previewValue.TextXAlignment = Enum.TextXAlignment.Right
previewValue.Text = "#FFFFFF"
previewValue.Parent = preview

sectionLabel(colourPage, nextOrder(colourPage), "CHANNELS")

local CHANNELS = { "R", "G", "B" }
local sliders = {}
local selected = 1
local refreshColour
local activeSlider = nil

local function channelColor(index)
	if index == 1 then
		return Color3.fromRGB(240, 96, 96)
	elseif index == 2 then
		return Color3.fromRGB(110, 214, 130)
	end
	return Color3.fromRGB(110, 160, 255)
end

for index, channel in ipairs(CHANNELS) do
	local row = Instance.new("Frame")
	row.LayoutOrder = nextOrder(colourPage)
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 24)
	row.Parent = colourPage

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromOffset(14, 24)
	name.Font = Enum.Font.GothamMedium
	name.TextSize = 11
	name.TextColor3 = COLORS.Muted
	name.Text = channel
	name.Parent = row

	local track = Instance.new("TextButton")
	track.Position = UDim2.fromOffset(18, 0)
	track.Size = UDim2.new(1, -58, 1, 0)
	track.BackgroundTransparency = 1
	track.Text = ""
	track.AutoButtonColor = false
	track.Parent = row

	local rail = Instance.new("Frame")
	rail.AnchorPoint = Vector2.new(0, 0.5)
	rail.Position = UDim2.fromScale(0, 0.5)
	rail.Size = UDim2.new(1, 0, 0, 6)
	rail.BackgroundColor3 = COLORS.Row
	rail.BorderSizePixel = 0
	rail.Parent = track
	rounded(rail, 3)

	local fill = Instance.new("Frame")
	fill.AnchorPoint = Vector2.new(0, 0.5)
	fill.Position = UDim2.fromScale(0, 0.5)
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = channelColor(index)
	fill.BorderSizePixel = 0
	fill.Parent = track
	rounded(fill, 3)

	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.fromScale(0, 0.5)
	knob.Size = UDim2.fromOffset(10, 10)
	knob.BackgroundColor3 = COLORS.Text
	knob.BorderSizePixel = 0
	knob.Parent = track
	rounded(knob, 5)

	local value = Instance.new("TextLabel")
	value.AnchorPoint = Vector2.new(1, 0.5)
	value.Position = UDim2.fromScale(1, 0.5)
	value.Size = UDim2.fromOffset(34, 24)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamMedium
	value.TextSize = 10
	value.TextColor3 = COLORS.Text
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Text = "0"
	value.Parent = row

	local function apply(input)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / width, 0, 1)
		local spec = COLOUR_TARGETS[selected]
		local settings = esp.Settings[spec.Table]
		local color = settings[spec.Key]
		local r, g, b = color.R, color.G, color.B
		if index == 1 then
			r = rel
		elseif index == 2 then
			g = rel
		else
			b = rel
		end
		settings[spec.Key] = Color3.new(r, g, b)
		refreshColour()
	end

	track.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			activeSlider = apply
			apply(input)
		end
	end)

	sliders[index] = {
		Refresh = function()
			local spec = COLOUR_TARGETS[selected]
			local color = esp.Settings[spec.Table][spec.Key]
			local amount = index == 1 and color.R or (index == 2 and color.G or color.B)
			fill.Size = UDim2.fromScale(amount, 1)
			knob.Position = UDim2.fromScale(amount, 0.5)
			value.Text = tostring(math.floor(amount * 255 + 0.5))
		end,
	}
end

UserInputService.InputChanged:Connect(function(input)
	if not activeSlider then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		activeSlider(input)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		activeSlider = nil
	end
end)

refreshColour = function()
	local spec = COLOUR_TARGETS[selected]
	local color = esp.Settings[spec.Table][spec.Key]
	preview.BackgroundColor3 = color
	local r = math.floor(color.R * 255 + 0.5)
	local g = math.floor(color.G * 255 + 0.5)
	local b = math.floor(color.B * 255 + 0.5)
	previewName.Text = spec.Name
	previewValue.Text = string.format("#%02X%02X%02X", r, g, b)
	local luma = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	local foreground = luma > 0.55 and COLORS.KnobOn or COLORS.Text
	previewName.TextColor3 = foreground
	previewValue.TextColor3 = foreground
	for _, slider in ipairs(sliders) do
		slider.Refresh()
	end
end

local chips = {}

local function selectChip(index)
	selected = index
	for chipIndex, chip in ipairs(chips) do
		local on = chipIndex == index
		chip.BackgroundColor3 = on and COLORS.Accent or COLORS.Row
		chip.TextColor3 = on and COLORS.KnobOn or COLORS.Text
	end
	refreshColour()
end

for index, spec in ipairs(COLOUR_TARGETS) do
	local chip = Instance.new("TextButton")
	chip.Name = spec.Name
	chip.LayoutOrder = index
	chip.BackgroundColor3 = COLORS.Row
	chip.BorderSizePixel = 0
	chip.AutoButtonColor = false
	chip.Font = Enum.Font.GothamMedium
	chip.TextSize = 10
	chip.TextColor3 = COLORS.Text
	chip.Text = spec.Name
	chip.Parent = chipHolder
	rounded(chip, 4)
	chip.MouseButton1Click:Connect(function()
		selectChip(index)
	end)
	chips[index] = chip
end

selectChip(1)
selectTab("ESP")
status.Text = "ready"

-- The entry map is internal; a dev panel may read it for a live count.
local elapsed = 0
RunService.Heartbeat:Connect(function(delta)
	elapsed = elapsed + delta
	if elapsed < 0.25 or not esp then
		return
	end
	elapsed = 0

	local count = 0
	for _ in pairs(esp._entries) do
		count = count + 1
	end

	local overlays = 0
	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") and child.Name == "Phasma" then
			overlays = overlays + 1
		end
	end

	local engines = 0
	if Phasma.GetActiveCount then
		engines = Phasma:GetActiveCount()
	end

	status.Text = string.format("%s | %d targets | %d esp | %d overlay", esp.Canvas.Kind, count, engines, overlays)
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

-- One line that proves where the panel ended up, whatever the layout did.
task.delay(0.5, function()
	print(
		string.format(
			"[Phasma] panel visible=%s %.0fx%.0f at (%.0f, %.0f) gui=%s parent=%s",
			tostring(panel.Visible),
			panel.AbsoluteSize.X,
			panel.AbsoluteSize.Y,
			panel.AbsolutePosition.X,
			panel.AbsolutePosition.Y,
			tostring(gui.Enabled),
			gui.Parent and gui.Parent:GetFullName() or "nil"
		)
	)
end)
