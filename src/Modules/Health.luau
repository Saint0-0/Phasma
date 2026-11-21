--[[
	Phasma/Modules/Health.luau

	Health bar beside (vertical) or under (horizontal) the box. The fill eases
	toward the real health value, and filled end caps make it a capsule at any
	size. An optional attribute-driven bar covers armour or shields.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("../Constants")
local Alpha = require("../Utils/Alpha")
local Color = require("../Utils/Color")
local Occlusion = require("../Utils/Occlusion")

local Health = {}
Health.__index = Health

function Health.New(ctx)
	local self = setmetatable({}, Health)
	self.Settings = ctx.Settings
	self.Global = ctx.Global
	self.Canvas = ctx.Canvas
	self.ZIndex = ctx.ZIndex
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
	self.LastPercent = nil
	self.Time = 0
	-- Secondary bars are created on first use so the default settings do not
	-- pay for two extra canvas objects per target.
	self.SecondaryBack = nil
	self.SecondaryFill = nil
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

local function textPosition(settings, x, y, width, height)
	local size = settings.TextSize
	local side = settings.TextSide or "Left"
	if side == "Right" then
		return Vector2.new(x + width + size, y + height * 0.5)
	elseif side == "Above" then
		return Vector2.new(x + width * 0.5, y - size)
	elseif side == "Below" then
		return Vector2.new(x + width * 0.5, y + height + size)
	end
	return Vector2.new(x - size, y + height * 0.5)
end

local function ensureSecondary(self)
	if not self.SecondaryBack then
		self.SecondaryBack = self.Canvas:Rect(self.ZIndex)
		self.SecondaryFill = self.Canvas:Rect(self.ZIndex)
	end
end

local function hideSecondary(self)
	if self.SecondaryBack then
		self.SecondaryBack.Visible = false
		self.SecondaryFill.Visible = false
	end
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
	local style = settings.Style or "Vertical"
	local horizontal = style == "Horizontal"
	local width = horizontal and state.Box.Size.X or settings.Width
	local height = horizontal and settings.Width or state.Box.Size.Y
	local x = horizontal and state.Box.Position.X or (state.Box.Position.X - settings.Gap - width)
	local y = horizontal and (state.Box.Position.Y + state.Box.Size.Y + settings.Gap) or state.Box.Position.Y

	local fillTransparency = Alpha.apply(settings.Transparency, alpha)
	self.Time = self.Time + delta
	-- Below a quarter health the fill breathes, which pulls the eye to a
	-- target that is about to die without adding another element.
	if settings.Pulse and self.Shown < 0.25 then
		local wave = (math.sin(self.Time * 6) + 1) * 0.5
		fillTransparency = math.clamp(fillTransparency + wave * 0.4, 0, 1)
	end
	fillTransparency = Occlusion.transparency(fillTransparency, state, self.Global)
	local backTransparency =
		Occlusion.transparency(Alpha.apply(settings.BackgroundTransparency, alpha), state, self.Global)

	self.Back.Position = Vector2.new(x, y)
	self.Back.Size = Vector2.new(width, height)
	self.Back.Color = settings.Background
	self.Back.Transparency = backTransparency
	self.Back.Filled = true
	self.Back.Visible = true

	local fillColor = Color.health(self.Shown)
	if horizontal then
		local fillWidth = width * self.Shown
		self.Fill.Position = Vector2.new(x, y)
		self.Fill.Size = Vector2.new(fillWidth, height)
		self.Fill.Color = fillColor
		self.Fill.Transparency = fillTransparency
		self.Fill.Filled = true
		self.Fill.Visible = fillWidth > 0
	else
		local fillHeight = height * self.Shown
		self.Fill.Position = Vector2.new(x, y + height - fillHeight)
		self.Fill.Size = Vector2.new(width, fillHeight)
		self.Fill.Color = fillColor
		self.Fill.Transparency = fillTransparency
		self.Fill.Filled = true
		self.Fill.Visible = fillHeight > 0
	end

	if horizontal then
		local radius = height * 0.5
		if settings.Rounded and width > height then
			cap(self.BackTop, x + radius, y + radius, radius, settings.Background, backTransparency)
			cap(self.BackBottom, x + width - radius, y + radius, radius, settings.Background, backTransparency)
		else
			self.BackTop.Visible = false
			self.BackBottom.Visible = false
		end

		local fillWidth = width * self.Shown
		if settings.Rounded and fillWidth > 0.5 and fillWidth >= height then
			cap(self.FillTop, x + radius, y + radius, radius, fillColor, fillTransparency)
			cap(self.FillBottom, x + fillWidth - radius, y + radius, radius, fillColor, fillTransparency)
		else
			self.FillTop.Visible = false
			self.FillBottom.Visible = false
		end
	else
		local radius = width * 0.5
		local centerX = x + radius
		if settings.Rounded and height > width then
			cap(self.BackTop, centerX, y + radius, radius, settings.Background, backTransparency)
			cap(self.BackBottom, centerX, y + height - radius, radius, settings.Background, backTransparency)
		else
			self.BackTop.Visible = false
			self.BackBottom.Visible = false
		end

		local fillHeight = height * self.Shown
		if settings.Rounded and fillHeight > 0.5 and fillHeight >= width then
			cap(self.FillTop, centerX, y + height - fillHeight + radius, radius, fillColor, fillTransparency)
			cap(self.FillBottom, centerX, y + height - radius, radius, fillColor, fillTransparency)
		else
			self.FillTop.Visible = false
			self.FillBottom.Visible = false
		end
	end

	local secondary = settings.Secondary
	if secondary and secondary.Enabled and state.Humanoid then
		local value = state.Humanoid:GetAttribute(secondary.Attribute)
		if typeof(value) == "number" and value > 0 then
			local maximum = state.Humanoid:GetAttribute(secondary.MaxAttribute)
			if typeof(maximum) ~= "number" or maximum <= 0 then
				maximum = 100
			end

			ensureSecondary(self)
			local ratio = math.clamp(value / maximum, 0, 1)
			local secondaryTransparency =
				Occlusion.transparency(Alpha.apply(secondary.Transparency or 0.2, alpha), state, self.Global)

			if horizontal then
				local barHeight = math.max(2, height * 0.6)
				local barY = y + height + 2
				self.SecondaryBack.Position = Vector2.new(x, barY)
				self.SecondaryBack.Size = Vector2.new(width, barHeight)
				self.SecondaryFill.Position = Vector2.new(x, barY)
				self.SecondaryFill.Size = Vector2.new(width * ratio, barHeight)
			else
				local barWidth = math.max(2, width * 0.6)
				local barX = x + width + 2
				local barHeight = height * ratio
				self.SecondaryBack.Position = Vector2.new(barX, y)
				self.SecondaryBack.Size = Vector2.new(barWidth, height)
				self.SecondaryFill.Position = Vector2.new(barX, y + height - barHeight)
				self.SecondaryFill.Size = Vector2.new(barWidth, barHeight)
			end

			self.SecondaryBack.Color = secondary.Color
			self.SecondaryBack.Transparency = Occlusion.transparency(Alpha.apply(0.65, alpha), state, self.Global)
			self.SecondaryBack.Filled = true
			self.SecondaryBack.Visible = true

			self.SecondaryFill.Color = secondary.Color
			self.SecondaryFill.Transparency = secondaryTransparency
			self.SecondaryFill.Filled = true
			self.SecondaryFill.Visible = ratio > 0
		else
			hideSecondary(self)
		end
	else
		hideSecondary(self)
	end

	if settings.ShowText then
		if settings.Percent then
			local percent = math.floor(target * 100 + 0.5)
			if percent ~= self.LastValue or not self.LastPercent then
				self.LastValue = percent
				self.LastPercent = true
				self.Text.Text = string.format("%d%%", percent)
			end
		else
			local value = math.floor(state.Health + 0.5)
			if value ~= self.LastValue or self.LastPercent ~= false then
				self.LastValue = value
				self.LastPercent = false
				self.Text.Text = tostring(value)
			end
		end
		self.Text.TextSize = settings.TextSize
		self.Text.Color = fillColor
		self.Text.Transparency = Occlusion.transparency(Alpha.apply(0, alpha), state, self.Global)
		self.Text.Outline = true
		self.Text.OutlineTransparency = Occlusion.transparency(Alpha.apply(0.4, alpha), state, self.Global)
		self.Text.Position = textPosition(settings, x, y, width, height)
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
	hideSecondary(self)
end

function Health:Destroy()
	self.Back:Destroy()
	self.Fill:Destroy()
	self.BackTop:Destroy()
	self.BackBottom:Destroy()
	self.FillTop:Destroy()
	self.FillBottom:Destroy()
	self.Text:Destroy()
	if self.SecondaryBack then
		self.SecondaryBack:Destroy()
		self.SecondaryFill:Destroy()
	end
end

return Health
