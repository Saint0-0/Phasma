--[[
	Phasma/Modules/Box.luau

	The 2D bounding box. The default style is four corner brackets over a faint
	fill, which reads as a modern overlay; "Full" and "Both" are also available.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Alpha = require("../Utils/Alpha")
local Anim = require("../Utils/Anim")
local Occlusion = require("../Utils/Occlusion")

local Box = {}
Box.__index = Box

-- Bracket length while the corners sweep in. Each corner starts a little
-- after the previous one, so the box assembles rather than snapping.
local function swept(base, progress, corner)
	if progress >= 1 then
		return base
	end
	local start = (corner - 1) * 0.08
	return base * Anim.cubic((progress - start) / 0.72)
end

function Box.New(ctx)
	local self = setmetatable({}, Box)
	self.Settings = ctx.Settings
	self.Global = ctx.Global
	-- Created first so the wide, faint outline renders behind the box.
	self.Glow = ctx.Canvas:Rect(ctx.ZIndex)
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
	local scale = state.Anim and state.Anim.Scale or 1
	local center = box.Center
	local position = center + (box.Position - center) * scale
	local size = box.Size * scale
	local alpha = state.Alpha
	local color = Occlusion.color(state.TeamColor or settings.Color, state, self.Global)
	local thickness = settings.Thickness
	local transparency = Occlusion.transparency(Alpha.apply(settings.Transparency, alpha), state, self.Global)

	if settings.Glow then
		self.Glow.Position = position
		self.Glow.Size = size
		self.Glow.Color = color
		self.Glow.Thickness = settings.GlowThickness or 3
		self.Glow.Transparency =
			Occlusion.transparency(Alpha.apply(settings.GlowTransparency or 0.88, alpha), state, self.Global)
		self.Glow.Filled = false
		self.Glow.Visible = true
	else
		self.Glow.Visible = false
	end

	if settings.Filled then
		self.Fill.Position = position
		self.Fill.Size = size
		self.Fill.Color = color
		self.Fill.Transparency =
			Occlusion.transparency(Alpha.apply(settings.FillTransparency, alpha), state, self.Global)
		self.Fill.Filled = true
		self.Fill.Visible = true
	else
		self.Fill.Visible = false
	end

	local style = settings.Style or "Corners"
	local showFull = style == "Full" or style == "Both"
	local showCorners = style == "Corners" or style == "Both"

	if showFull then
		self.Full.Position = position
		self.Full.Size = size
		self.Full.Color = color
		self.Full.Thickness = thickness
		self.Full.Transparency = transparency
		self.Full.Filled = false
		self.Full.Visible = true
	else
		self.Full.Visible = false
	end

	local x = position.X
	local y = position.Y
	local width = size.X
	local height = size.Y

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
		local sweep = state.Anim and state.Anim.SweepEased or 1

		local tl = swept(length, sweep, 1)
		local tr = swept(length, sweep, 2)
		local bl = swept(length, sweep, 3)
		local br = swept(length, sweep, 4)

		-- Top-left.
		segment(lines[1], x, y, x + tl, y, color, thickness, transparency)
		segment(lines[2], x, y, x, y + tl, color, thickness, transparency)
		-- Top-right.
		segment(lines[3], right - tr, y, right, y, color, thickness, transparency)
		segment(lines[4], right, y, right, y + tr, color, thickness, transparency)
		-- Bottom-left.
		segment(lines[5], x, bottom - bl, x, bottom, color, thickness, transparency)
		segment(lines[6], x, bottom, x + bl, bottom, color, thickness, transparency)
		-- Bottom-right.
		segment(lines[7], right, bottom - br, right, bottom, color, thickness, transparency)
		segment(lines[8], right - br, bottom, right, bottom, color, thickness, transparency)
	else
		for _, line in ipairs(self.Corners) do
			line.Visible = false
		end
	end
end

function Box:Hide()
	self.Glow.Visible = false
	self.Full.Visible = false
	self.Fill.Visible = false
	for _, line in ipairs(self.Corners) do
		line.Visible = false
	end
end

function Box:Destroy()
	self.Glow:Destroy()
	self.Full:Destroy()
	self.Fill:Destroy()
	for _, line in ipairs(self.Corners) do
		line:Destroy()
	end
	table.clear(self.Corners)
end

return Box
