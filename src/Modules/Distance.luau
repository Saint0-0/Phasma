--[[
	Phasma/Modules/Distance.luau

	Distance readout under the box. Scale converts studs into the displayed unit.
	The formatted string is only rebuilt when the rounded value changes.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("../Constants")

local Distance = {}
Distance.__index = Distance

function Distance.New(ctx)
	local self = setmetatable({}, Distance)
	self.Settings = ctx.Settings
	self.Text = ctx.Canvas:Text(ctx.ZIndex)
	self.Text.Centered = true
	self.Text.OutlineColor = Constants.OutlineColor
	self.LastValue = nil
	self.LastSuffix = nil
	self.LastScale = nil
	return self
end

function Distance:Update(state)
	local settings = self.Settings
	if not settings.Enabled then
		self.Text.Visible = false
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
	self.Text.Color = settings.Color
	self.Text.Transparency = settings.Transparency
	self.Text.Outline = settings.Outline
	self.Text.OutlineTransparency = settings.OutlineTransparency or 0.5
	self.Text.Position = Vector2.new(
		state.Box.Center.X,
		state.Box.Position.Y + state.Box.Size.Y + settings.Offset + settings.TextSize * 0.5
	)
	self.Text.Visible = true
end

function Distance:Hide()
	self.Text.Visible = false
end

function Distance:Destroy()
	self.Text:Destroy()
end

return Distance
