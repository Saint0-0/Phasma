--[[
	Phasma/Modules/Direction.luau

	Small chevron above the box that points where the target is facing. The
	direction is solved in screen space by Target, so it works from any camera
	angle and needs no extra raycast.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Alpha = require("../Utils/Alpha")
local Occlusion = require("../Utils/Occlusion")

local Direction = {}
Direction.__index = Direction

function Direction.New(ctx)
	local self = setmetatable({}, Direction)
	self.Settings = ctx.Settings
	self.Global = ctx.Global
	self.LineA = ctx.Canvas:Line(ctx.ZIndex)
	self.LineB = ctx.Canvas:Line(ctx.ZIndex)
	return self
end

function Direction:Update(state)
	local settings = self.Settings
	if not settings.Enabled or state.Offscreen or not state.FacingValid then
		self:Hide()
		return
	end

	local box = state.Box
	local direction = state.Facing
	if direction.Magnitude < 0.001 then
		self:Hide()
		return
	end
	direction = direction.Unit

	local size = settings.Size or 6
	-- The marker shares the name chip's slide so the top of the target reads
	-- as one group while it settles.
	local slide = state.Anim and state.Anim.SlideOffset or 0
	local origin = Vector2.new(box.Center.X, box.Position.Y - (settings.Offset or 4) - slide * 0.6)
	local tip = origin + direction * size
	local back = origin - direction * size * 0.2
	local perpendicular = Vector2.new(-direction.Y, direction.X)
	local left = back + perpendicular * size * 0.6
	local right = back - perpendicular * size * 0.6

	local color = Occlusion.color(state.TeamColor or settings.Color, state, self.Global)
	local transparency = Occlusion.transparency(Alpha.apply(settings.Transparency, state.Alpha), state, self.Global)
	local thickness = settings.Thickness or 2

	self.LineA.From = tip
	self.LineA.To = left
	self.LineA.Color = color
	self.LineA.Thickness = thickness
	self.LineA.Transparency = transparency
	self.LineA.Visible = true

	self.LineB.From = tip
	self.LineB.To = right
	self.LineB.Color = color
	self.LineB.Thickness = thickness
	self.LineB.Transparency = transparency
	self.LineB.Visible = true
end

function Direction:Hide()
	self.LineA.Visible = false
	self.LineB.Visible = false
end

function Direction:Destroy()
	self.LineA:Destroy()
	self.LineB:Destroy()
end

return Direction
