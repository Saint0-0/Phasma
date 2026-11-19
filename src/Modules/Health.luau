--[[
	Phasma/Modules/Health.luau

	Vertical health bar to the left of the box.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("../Constants")
local Color = require("../Utils/Color")

local Health = {}
Health.__index = Health

function Health.New(ctx)
	local self = setmetatable({}, Health)
	self.Settings = ctx.Settings
	self.Back = ctx.Canvas:Rect(ctx.ZIndex)
	self.Fill = ctx.Canvas:Rect(ctx.ZIndex)
	self.Text = ctx.Canvas:Text(ctx.ZIndex)
	self.Text.Centered = true
	self.Text.OutlineColor = Constants.OutlineColor
	return self
end

function Health:Update(state)
	local settings = self.Settings
	if not settings.Enabled or state.MaxHealth <= 0 then
		self.Back.Visible = false
		self.Fill.Visible = false
		self.Text.Visible = false
		return
	end

	local alpha = math.clamp(state.Health / state.MaxHealth, 0, 1)
	local width = settings.Width
	local height = state.Box.Size.Y
	local x = state.Box.Position.X - settings.Gap - width
	local y = state.Box.Position.Y
	local fillHeight = height * alpha

	self.Back.Position = Vector2.new(x, y)
	self.Back.Size = Vector2.new(width, height)
	self.Back.Color = settings.Background
	self.Back.Transparency = settings.BackgroundTransparency
	self.Back.Filled = true
	self.Back.Visible = true

	self.Fill.Position = Vector2.new(x, y + height - fillHeight)
	self.Fill.Size = Vector2.new(width, fillHeight)
	self.Fill.Color = Color.health(alpha)
	self.Fill.Transparency = settings.Transparency
	self.Fill.Filled = true
	self.Fill.Visible = fillHeight > 0

	if settings.ShowText then
		self.Text.Text = string.format("%d", math.floor(state.Health + 0.5))
		self.Text.TextSize = settings.TextSize
		self.Text.Color = Color.health(alpha)
		self.Text.Transparency = 0
		self.Text.Outline = true
		self.Text.Position = Vector2.new(x - settings.TextSize, y + height * 0.5)
		self.Text.Visible = true
	else
		self.Text.Visible = false
	end
end

function Health:Hide()
	self.Back.Visible = false
	self.Fill.Visible = false
	self.Text.Visible = false
end

function Health:Destroy()
	self.Back:Destroy()
	self.Fill:Destroy()
	self.Text:Destroy()
end

return Health
