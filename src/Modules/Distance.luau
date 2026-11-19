--[[
	Phasma/Modules/Distance.luau

	Distance readout under the box. Scale converts studs into the displayed unit.
	The formatted string is only rebuilt when the rounded value changes, and the
	optional chip is measured from that string.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("../Constants")
local Alpha = require("../Utils/Alpha")
local Occlusion = require("../Utils/Occlusion")

local Distance = {}
Distance.__index = Distance

function Distance.New(ctx)
	local self = setmetatable({}, Distance)
	self.Settings = ctx.Settings
	self.Global = ctx.Global
	-- The chip is created first so it renders behind the text.
	self.Chip = ctx.Canvas:Rect(ctx.ZIndex)
	self.Text = ctx.Canvas:Text(ctx.ZIndex)
	self.Text.Centered = true
	self.Text.OutlineColor = Constants.OutlineColor
	self.LastValue = nil
	self.LastSuffix = nil
	self.LastScale = nil
	self.Bounds = Vector2.zero
	self.MeasuredText = nil
	self.MeasuredSize = nil
	self.MeasuredExact = false
	self.MeasureTries = 0
	return self
end

function Distance:Update(state)
	local settings = self.Settings
	if not settings.Enabled then
		self:Hide()
		return
	end

	local value = math.floor(state.Distance * settings.Scale + 0.5)
	if value ~= self.LastValue or settings.Suffix ~= self.LastSuffix or settings.Scale ~= self.LastScale then
		self.LastValue = value
		self.LastSuffix = settings.Suffix
		self.LastScale = settings.Scale
		self.Text.Text = string.format("%d%s", value, settings.Suffix)
	end

	self.Text.TextSize = settings.TextSize
	local label = self.Text.Text
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

	local center = Vector2.new(
		state.Box.Center.X,
		state.Box.Position.Y
			+ state.Box.Size.Y
			+ settings.Offset
			+ settings.TextSize * 0.5
			+ (state.Anim and state.Anim.SlideOffset or 0)
	)

	local alpha = state.Alpha
	if settings.Background and state.ShowChips then
		local padding = settings.Padding or 4
		local size = Vector2.new(self.Bounds.X + padding * 2, self.Bounds.Y + padding * 2)
		self.Chip.Position = center - size * 0.5
		self.Chip.Size = size
		self.Chip.Color = settings.BackgroundColor
		self.Chip.Transparency =
			Occlusion.transparency(Alpha.apply(settings.BackgroundTransparency or 0.55, alpha), state, self.Global)
		self.Chip.Filled = true
		self.Chip.Visible = true
	else
		self.Chip.Visible = false
	end

	self.Text.Color = Occlusion.color(settings.Color, state, self.Global)
	self.Text.Transparency = Occlusion.transparency(Alpha.apply(settings.Transparency, alpha), state, self.Global)
	self.Text.Outline = settings.Outline
	self.Text.OutlineTransparency =
		Occlusion.transparency(Alpha.apply(settings.OutlineTransparency or 0.5, alpha), state, self.Global)
	self.Text.Position = center
	self.Text.Visible = true
end

function Distance:Hide()
	self.Chip.Visible = false
	self.Text.Visible = false
end

function Distance:Destroy()
	self.Chip:Destroy()
	self.Text:Destroy()
end

return Distance
