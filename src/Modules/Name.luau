--[[
	Phasma/Modules/Name.luau

	Player name above the box. The optional chip is measured from the rendered
	text, so it hugs the label on both backends.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("../Constants")
local Alpha = require("../Utils/Alpha")

local Name = {}
Name.__index = Name

function Name.New(ctx)
	local self = setmetatable({}, Name)
	self.Settings = ctx.Settings
	-- The chip is created first so it renders behind the text.
	self.Chip = ctx.Canvas:Rect(ctx.ZIndex)
	self.Text = ctx.Canvas:Text(ctx.ZIndex)
	self.Text.Centered = true
	self.Text.OutlineColor = Constants.OutlineColor
	self.Bounds = Vector2.zero
	self.MeasuredText = nil
	self.MeasuredSize = nil
	self.MeasuredExact = false
	self.MeasureTries = 0
	return self
end

function Name:Update(state)
	local settings = self.Settings
	if not settings.Enabled then
		self:Hide()
		return
	end

	local label = state.Name
	if state.Player and settings.UseDisplayName and state.Player.DisplayName ~= "" then
		label = state.Player.DisplayName
	end

	self.Text.Text = label
	self.Text.TextSize = settings.TextSize
	local changed = label ~= self.MeasuredText or settings.TextSize ~= self.MeasuredSize
	if changed then
		self.MeasuredText = label
		self.MeasuredSize = settings.TextSize
		self.MeasureTries = 0
	end
	-- TextBounds can lag by a frame on some Drawing builds, so an estimate is
	-- retried for a few frames before it is kept.
	if changed or (not self.MeasuredExact and self.MeasureTries < 12) then
		local bounds, exact = self.Text:Measure()
		self.Bounds = bounds
		self.MeasuredExact = exact
		self.MeasureTries = self.MeasureTries + 1
	end

	local center = Vector2.new(state.Box.Center.X, state.Box.Position.Y - settings.Offset - settings.TextSize * 0.5)

	if settings.Background then
		local padding = settings.Padding or 4
		local size = Vector2.new(self.Bounds.X + padding * 2, self.Bounds.Y + padding * 2)
		self.Chip.Position = center - size * 0.5
		self.Chip.Size = size
		self.Chip.Color = settings.BackgroundColor
		self.Chip.Transparency = Alpha.apply(settings.BackgroundTransparency or 0.55, state.Alpha)
		self.Chip.Filled = true
		self.Chip.Visible = true
	else
		self.Chip.Visible = false
	end

	self.Text.Color = state.TeamColor or settings.Color
	self.Text.Transparency = settings.Transparency
	self.Text.Outline = settings.Outline
	self.Text.OutlineTransparency = settings.OutlineTransparency or 0.45
	self.Text.Position = center
	self.Text.Visible = true
end

function Name:Hide()
	self.Chip.Visible = false
	self.Text.Visible = false
end

function Name:Destroy()
	self.Chip:Destroy()
	self.Text:Destroy()
end

return Name
