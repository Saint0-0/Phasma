--[[
	Phasma/Modules/Health.luau

	Vertical health bar to the left of the box. The fill eases toward the real
	health value, and filled end caps make it a capsule on both backends.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("../Constants")
local Alpha = require("../Utils/Alpha")
local Color = require("../Utils/Color")

local Health = {}
Health.__index = Health

function Health.New(ctx)
	local self = setmetatable({}, Health)
	self.Settings = ctx.Settings
	self.Back = ctx.Canvas:Rect(ctx.ZIndex)
	self.Fill = ctx.Canvas:Rect(ctx.ZIndex)
	self.BackTop = ctx.Canvas:Circle(ctx.ZIndex)
	self.BackBottom = ctx.Canvas:Circle(ctx.ZIndex)
	self.FillTop = ctx.Canvas:Circle(ctx.ZIndex)
	self.FillBottom = ctx.Canvas:Circle(ctx.ZIndex)
	self.Text = ctx.Canvas:Text(ctx.ZIndex)
	self.Text.Centered = true
	self.Text.OutlineColor = Constants.OutlineColor
	self.Shown = 1
	self.LastValue = nil
	return self
end

local function cap(circle, x, y, radius, color, transparency)
	circle.Position = Vector2.new(x, y)
	circle.Radius = radius
	circle.Color = color
	circle.Filled = true
	circle.Thickness = 1
	circle.Transparency = transparency
	circle.Visible = true
end

function Health:Update(state)
	local settings = self.Settings
	if not settings.Enabled or state.MaxHealth <= 0 then
		self:Hide()
		return
	end

	local target = math.clamp(state.Health / state.MaxHealth, 0, 1)
	local speed = settings.Smoothing or 0
	local delta = state.Delta or 0
	if speed > 0 and delta > 0 then
		local factor = 1 - math.exp(-speed * delta)
		self.Shown = self.Shown + (target - self.Shown) * factor
		if math.abs(target - self.Shown) < 0.001 then
			self.Shown = target
		end
	else
		self.Shown = target
	end

	local alpha = state.Alpha
	local width = settings.Width
	local height = state.Box.Size.Y
	local x = state.Box.Position.X - settings.Gap - width
	local y = state.Box.Position.Y
	local fillHeight = height * self.Shown
	local radius = width * 0.5
	local centerX = x + radius

	local backTransparency = Alpha.apply(settings.BackgroundTransparency, alpha)
	self.Back.Position = Vector2.new(x, y)
	self.Back.Size = Vector2.new(width, height)
	self.Back.Color = settings.Background
	self.Back.Transparency = backTransparency
	self.Back.Filled = true
	self.Back.Visible = true

	self.Fill.Position = Vector2.new(x, y + height - fillHeight)
	self.Fill.Size = Vector2.new(width, fillHeight)
	self.Fill.Color = Color.health(self.Shown)
	self.Fill.Transparency = Alpha.apply(settings.Transparency, alpha)
	self.Fill.Filled = true
	self.Fill.Visible = fillHeight > 0

	if settings.Rounded and height > width then
		cap(self.BackTop, centerX, y + radius, radius, settings.Background, backTransparency)
		cap(self.BackBottom, centerX, y + height - radius, radius, settings.Background, backTransparency)
	else
		self.BackTop.Visible = false
		self.BackBottom.Visible = false
	end

	if settings.Rounded and fillHeight > 0.5 and fillHeight >= width then
		local fillColor = Color.health(self.Shown)
		local fillTransparency = Alpha.apply(settings.Transparency, alpha)
		cap(self.FillTop, centerX, y + height - fillHeight + radius, radius, fillColor, fillTransparency)
		cap(self.FillBottom, centerX, y + height - radius, radius, fillColor, fillTransparency)
	else
		self.FillTop.Visible = false
		self.FillBottom.Visible = false
	end

	if settings.ShowText then
		local value = math.floor(state.Health + 0.5)
		if value ~= self.LastValue then
			self.LastValue = value
			self.Text.Text = tostring(value)
		end
		self.Text.TextSize = settings.TextSize
		self.Text.Color = Color.health(self.Shown)
		self.Text.Transparency = 0
		self.Text.Outline = true
		self.Text.OutlineTransparency = 0.4
		self.Text.Position = Vector2.new(x - settings.TextSize, y + height * 0.5)
		self.Text.Visible = true
	else
		self.Text.Visible = false
	end
end

function Health:Hide()
	self.Back.Visible = false
	self.Fill.Visible = false
	self.BackTop.Visible = false
	self.BackBottom.Visible = false
	self.FillTop.Visible = false
	self.FillBottom.Visible = false
	self.Text.Visible = false
end

function Health:Destroy()
	self.Back:Destroy()
	self.Fill:Destroy()
	self.BackTop:Destroy()
	self.BackBottom:Destroy()
	self.FillTop:Destroy()
	self.FillBottom:Destroy()
	self.Text:Destroy()
end

return Health
