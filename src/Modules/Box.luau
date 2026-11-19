--[[
	Phasma/Modules/Box.luau

	The 2D bounding box around the target.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Box = {}
Box.__index = Box

function Box.New(ctx)
	local self = setmetatable({}, Box)
	self.Settings = ctx.Settings
	self.Rect = ctx.Canvas:Rect(ctx.ZIndex)
	return self
end

function Box:Update(state)
	local settings = self.Settings
	if not settings.Enabled then
		self.Rect.Visible = false
		return
	end

	self.Rect.Position = state.Box.Position
	self.Rect.Size = state.Box.Size
	self.Rect.Color = settings.Color
	self.Rect.Thickness = settings.Thickness
	self.Rect.Filled = settings.Filled
	self.Rect.Transparency = settings.Transparency
	self.Rect.Visible = true
end

function Box:Hide()
	self.Rect.Visible = false
end

function Box:Destroy()
	self.Rect:Destroy()
end

return Box
