--[[
	Phasma/Modules/Name.luau

	Player name above the box.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("../Constants")

local Name = {}
Name.__index = Name

function Name.New(ctx)
	local self = setmetatable({}, Name)
	self.Settings = ctx.Settings
	self.Text = ctx.Canvas:Text(ctx.ZIndex)
	self.Text.Centered = true
	self.Text.OutlineColor = Constants.OutlineColor
	return self
end

function Name:Update(state)
	local settings = self.Settings
	if not settings.Enabled then
		self.Text.Visible = false
		return
	end

	local label = state.Name
	if state.Player and settings.UseDisplayName and state.Player.DisplayName ~= "" then
		label = state.Player.DisplayName
	end

	self.Text.Text = label
	self.Text.TextSize = settings.TextSize
	self.Text.Color = settings.Color
	self.Text.Transparency = settings.Transparency
	self.Text.Outline = settings.Outline
	self.Text.Position =
		Vector2.new(state.Box.Center.X, state.Box.Position.Y - settings.Offset - settings.TextSize * 0.5)
	self.Text.Visible = true
end

function Name:Hide()
	self.Text.Visible = false
end

function Name:Destroy()
	self.Text:Destroy()
end

return Name
