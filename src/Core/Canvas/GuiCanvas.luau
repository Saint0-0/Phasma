--[[
	Phasma/Core/Canvas/GuiCanvas.luau

	ScreenGui backend used in Studio and on executors without Drawing. Same
	proxy surface as DrawingCanvas, built from Frames, TextLabels and UIStrokes.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Players = game:GetService("Players")

local Constants = require("../../Constants")

-- Executor globals live in the script environment; getfenv reaches them.
local gethui = getfenv().gethui

local GuiCanvas = {}
GuiCanvas.__index = GuiCanvas

local function resolveParent()
	if type(gethui) == "function" then
		local ok, parent = pcall(gethui)
		if ok and typeof(parent) == "Instance" then
			return parent
		end
	end
	local player = Players.LocalPlayer
	if player then
		return player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
	end
	return nil
end

local function updateLine(object)
	local props = rawget(object, "_props")
	local frame = rawget(object, "_frame")
	local from = props.From
	local to = props.To
	local delta = to - from
	local length = delta.Magnitude

	frame.Position = UDim2.fromOffset(from.X, from.Y)
	frame.Size = UDim2.fromOffset(length, props.Thickness)
	frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
	frame.BackgroundColor3 = props.Color
	frame.BackgroundTransparency = props.Transparency
	frame.Visible = props.Visible and length > 0
end

local function apply(object, key)
	local props = rawget(object, "_props")
	local kind = rawget(object, "_kind")
	local frame = rawget(object, "_frame")
	local stroke = rawget(object, "_stroke")

	if not frame then
		return
	end

	if key == "Visible" then
		frame.Visible = props.Visible
	elseif key == "ZIndex" then
		frame.ZIndex = props.ZIndex
	elseif key == "Color" then
		if kind == "Text" then
			frame.TextColor3 = props.Color
		else
			frame.BackgroundColor3 = props.Color
		end
		if stroke then
			stroke.Color = props.Color
		end
	elseif key == "Transparency" then
		if kind == "Text" then
			frame.TextTransparency = props.Transparency
		elseif kind == "Line" then
			frame.BackgroundTransparency = props.Transparency
		else
			frame.BackgroundTransparency = props.Filled and props.Transparency or 1
			if stroke then
				stroke.Transparency = props.Filled and 1 or props.Transparency
			end
		end
	elseif key == "Thickness" then
		if stroke then
			stroke.Thickness = props.Thickness
		end
	elseif key == "Filled" then
		if kind == "Rect" or kind == "Circle" then
			frame.BackgroundTransparency = props.Filled and props.Transparency or 1
			if stroke then
				stroke.Transparency = props.Filled and 1 or props.Transparency
			end
		end
	elseif key == "Position" then
		frame.Position = UDim2.fromOffset(props.Position.X, props.Position.Y)
	elseif key == "Size" then
		frame.Size = UDim2.fromOffset(props.Size.X, props.Size.Y)
	elseif key == "Radius" then
		frame.Size = UDim2.fromOffset(props.Radius * 2, props.Radius * 2)
	elseif key == "Text" then
		frame.Text = props.Text
	elseif key == "TextSize" then
		frame.TextSize = props.TextSize
	elseif key == "Centered" then
		frame.TextXAlignment = props.Centered and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
		frame.AnchorPoint = props.Centered and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
	elseif key == "Outline" then
		frame.TextStrokeTransparency = props.Outline and 0.3 or 1
	elseif key == "OutlineColor" then
		frame.TextStrokeColor3 = props.OutlineColor
	end

	if kind == "Line" and (key == "From" or key == "To" or key == "Thickness" or key == "Visible") then
		updateLine(object)
	end
end

local Object = {}
Object.__index = function(self, key)
	local method = Object[key]
	if method ~= nil then
		return method
	end
	return rawget(self, "_props")[key]
end
Object.__newindex = function(self, key, value)
	rawset(rawget(self, "_props"), key, value)
	apply(self, key)
end

-- Drops the frame from the ScreenGui and from the owner's list.
function Object:Destroy()
	local frame = rawget(self, "_frame")
	if not frame then
		return
	end
	rawset(self, "_frame", nil)
	rawset(rawget(self, "_props"), "Visible", false)

	local owner = rawget(self, "_owner")
	if owner then
		owner._objects[frame] = nil
	end
	frame:Destroy()
end

function GuiCanvas.new()
	local self = setmetatable({ Kind = "Gui", _objects = {} }, GuiCanvas)

	local gui = Instance.new("ScreenGui")
	gui.Name = Constants.ScreenGuiName
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = Constants.DisplayOrder
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = true
	gui.Parent = resolveParent()

	self.Gui = gui
	return self
end

function GuiCanvas:_object(kind, frame, stroke, props)
	local object = setmetatable({}, Object)
	rawset(object, "_kind", kind)
	rawset(object, "_frame", frame)
	rawset(object, "_stroke", stroke)
	rawset(object, "_props", props)
	rawset(object, "_owner", self)
	self._objects[frame] = true
	return object
end

function GuiCanvas:Line(zIndex)
	local frame = Instance.new("Frame")
	frame.Name = "PhasmaLine"
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.ZIndex = zIndex
	frame.Visible = false
	frame.Parent = self.Gui

	return self:_object("Line", frame, nil, {
		Visible = false,
		ZIndex = zIndex,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
		Thickness = 1,
		From = Vector2.zero,
		To = Vector2.zero,
	})
end

function GuiCanvas:Rect(zIndex)
	local frame = Instance.new("Frame")
	frame.Name = "PhasmaRect"
	frame.BorderSizePixel = 0
	frame.BackgroundTransparency = 1
	frame.ZIndex = zIndex
	frame.Visible = false

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Miter
	stroke.Thickness = 1
	stroke.Transparency = 0
	stroke.Parent = frame

	frame.Parent = self.Gui

	return self:_object("Rect", frame, stroke, {
		Visible = false,
		ZIndex = zIndex,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
		Thickness = 1,
		Filled = false,
		Position = Vector2.zero,
		Size = Vector2.zero,
	})
end

function GuiCanvas:Text(zIndex)
	local label = Instance.new("TextLabel")
	label.Name = "PhasmaText"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.RichText = false
	label.Font = Constants.Font
	label.Text = ""
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Constants.OutlineColor
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.fromOffset(0, 0)
	label.ZIndex = zIndex
	label.Visible = false
	label.Parent = self.Gui

	return self:_object("Text", label, nil, {
		Visible = false,
		ZIndex = zIndex,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
		Text = "",
		TextSize = 13,
		Centered = true,
		Outline = true,
		OutlineColor = Constants.OutlineColor,
		Position = Vector2.zero,
	})
end

function GuiCanvas:Circle(zIndex)
	local frame = Instance.new("Frame")
	frame.Name = "PhasmaCircle"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BorderSizePixel = 0
	frame.BackgroundTransparency = 1
	frame.ZIndex = zIndex
	frame.Visible = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 1
	stroke.Transparency = 0
	stroke.Parent = frame

	frame.Parent = self.Gui

	return self:_object("Circle", frame, stroke, {
		Visible = false,
		ZIndex = zIndex,
		Color = Color3.new(1, 1, 1),
		Transparency = 0,
		Thickness = 1,
		Filled = false,
		Position = Vector2.zero,
		Radius = 4,
	})
end

function GuiCanvas:Destroy()
	if self.Gui then
		self.Gui:Destroy()
		self.Gui = nil
	end
	table.clear(self._objects)
end

return GuiCanvas
