--[[
	Phasma/Modules/Box.luau

	The 2D bounding box. The default style is four corner brackets over a faint
	fill, which reads as a modern overlay; "Full" and "Both" are also available.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Alpha = require("../Utils/Alpha")

local Box = {}
Box.__index = Box

function Box.New(ctx)
	local self = setmetatable({}, Box)
	self.Settings = ctx.Settings
	self.Full = ctx.Canvas:Rect(ctx.ZIndex)
	self.Fill = ctx.Canvas:Rect(ctx.ZIndex)
	self.Corners = table.create(8)
	for index = 1, 8 do
		self.Corners[index] = ctx.Canvas:Line(ctx.ZIndex)
	end
	return self
end

local function segment(line, fromX, fromY, toX, toY, color, thickness, transparency)
	line.From = Vector2.new(fromX, fromY)
	line.To = Vector2.new(toX, toY)
	line.Color = color
	line.Thickness = thickness
	line.Transparency = transparency
	line.Visible = true
end

function Box:Update(state)
	local settings = self.Settings
	if not settings.Enabled then
		self:Hide()
		return
	end

	local box = state.Box
	local alpha = state.Alpha
	local color = settings.Color
	local thickness = settings.Thickness
	local transparency = Alpha.apply(settings.Transparency, alpha)

	if settings.Filled then
		self.Fill.Position = box.Position
		self.Fill.Size = box.Size
		self.Fill.Color = color
		self.Fill.Transparency = Alpha.apply(settings.FillTransparency, alpha)
		self.Fill.Filled = true
		self.Fill.Visible = true
	else
		self.Fill.Visible = false
	end

	local style = settings.Style or "Corners"
	local showFull = style == "Full" or style == "Both"
	local showCorners = style == "Corners" or style == "Both"

	if showFull then
		self.Full.Position = box.Position
		self.Full.Size = box.Size
		self.Full.Color = color
		self.Full.Thickness = thickness
		self.Full.Transparency = transparency
		self.Full.Filled = false
		self.Full.Visible = true
	else
		self.Full.Visible = false
	end

	local x = box.Position.X
	local y = box.Position.Y
	local width = box.Size.X
	local height = box.Size.Y

	local length = math.min(width, height) * (settings.CornerScale or 0.22)
	local minLength = settings.CornerMin or 5
	local maxLength = settings.CornerMax or 16
	if maxLength < minLength then
		maxLength = minLength
	end
	length = math.clamp(length, minLength, maxLength)
	length = math.min(length, width * 0.5, height * 0.5)

	if showCorners and width > 2 and height > 2 and length > 0.5 then
		local right = x + width
		local bottom = y + height
		local lines = self.Corners

		-- Top-left.
		segment(lines[1], x, y, x + length, y, color, thickness, transparency)
		segment(lines[2], x, y, x, y + length, color, thickness, transparency)
		-- Top-right.
		segment(lines[3], right - length, y, right, y, color, thickness, transparency)
		segment(lines[4], right, y, right, y + length, color, thickness, transparency)
		-- Bottom-left.
		segment(lines[5], x, bottom - length, x, bottom, color, thickness, transparency)
		segment(lines[6], x, bottom, x + length, bottom, color, thickness, transparency)
		-- Bottom-right.
		segment(lines[7], right, bottom - length, right, bottom, color, thickness, transparency)
		segment(lines[8], right - length, bottom, right, bottom, color, thickness, transparency)
	else
		for _, line in ipairs(self.Corners) do
			line.Visible = false
		end
	end
end

function Box:Hide()
	self.Full.Visible = false
	self.Fill.Visible = false
	for _, line in ipairs(self.Corners) do
		line.Visible = false
	end
end

function Box:Destroy()
	self.Full:Destroy()
	self.Fill:Destroy()
	for _, line in ipairs(self.Corners) do
		line:Destroy()
	end
	table.clear(self.Corners)
end

return Box
