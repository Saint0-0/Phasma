--[[
	Phasma/Modules/HeadDot.luau

	Small circle on the head position.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local HeadDot = {}
HeadDot.__index = HeadDot

function HeadDot.New(ctx)
	local self = setmetatable({}, HeadDot)
	self.Settings = ctx.Settings
	self.Dot = ctx.Canvas:Circle(ctx.ZIndex)
	return self
end

function HeadDot:Update(state)
	local settings = self.Settings
	if not settings.Enabled then
		self.Dot.Visible = false
		return
	end

	self.Dot.Position = state.Screen
	self.Dot.Radius = settings.Radius
	self.Dot.Color = settings.Color
	self.Dot.Filled = settings.Filled
	self.Dot.Thickness = 1
	self.Dot.Transparency = settings.Transparency
	self.Dot.Visible = true
end

function HeadDot:Hide()
	self.Dot.Visible = false
end

function HeadDot:Destroy()
	self.Dot:Destroy()
end

return HeadDot
