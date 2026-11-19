--[[
	Phasma/Modules/Arrow.luau

	Edge chevron for targets outside the viewport, including behind the camera.
	The direction comes from Target, the edge position is solved against the
	inset viewport here, and the label reuses Distance's suffix and scale.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Alpha = require("../Utils/Alpha")
local Occlusion = require("../Utils/Occlusion")

local Arrow = {}
Arrow.__index = Arrow

function Arrow.New(ctx)
	local self = setmetatable({}, Arrow)
	self.Settings = ctx.Settings
	self.Global = ctx.Global
	-- Entry keeps every other element hidden while this one draws.
	self.OffscreenOnly = true
	self.LineA = ctx.Canvas:Line(ctx.ZIndex)
	self.LineB = ctx.Canvas:Line(ctx.ZIndex)
	self.Text = ctx.Canvas:Text(ctx.ZIndex)
	self.Text.Centered = true
	self.LastValue = nil
	self.LastSuffix = nil
	return self
end

function Arrow:Update(state)
	local settings = self.Settings
	local camera = workspace.CurrentCamera
	if not settings.Enabled or state.ShowArrow == false or not state.Offscreen or not camera then
		self:Hide()
		return
	end

	local anim = state.Anim
	local progress = anim and (anim.ArrowEased or anim.Arrow) or 1
	if progress <= 0.01 then
		self:Hide()
		return
	end

	local viewport = camera.ViewportSize
	local baseSize = settings.Size or 9
	local inset = (settings.Offset or 16) + baseSize
	-- A viewport smaller than the inset cannot host the chevron. Clamping with
	-- max < min would throw while the camera is still settling after a join.
	if viewport.X <= inset * 2 or viewport.Y <= inset * 2 then
		self:Hide()
		return
	end

	local direction = state.ArrowDirection
	if direction.Magnitude < 0.001 then
		direction = Vector2.new(0, 1)
	else
		direction = direction.Unit
	end

	local reach = viewport * 0.5 - Vector2.new(inset, inset)
	reach = Vector2.new(math.max(reach.X, 1), math.max(reach.Y, 1))

	-- Intersect the direction ray from the viewport centre with the inset box.
	local scaleX = math.abs(direction.X) > 0.0001 and reach.X / math.abs(direction.X) or math.huge
	local scaleY = math.abs(direction.Y) > 0.0001 and reach.Y / math.abs(direction.Y) or math.huge
	local tip = viewport * 0.5 + direction * math.min(scaleX, scaleY)
	tip = Vector2.new(math.clamp(tip.X, inset, viewport.X - inset), math.clamp(tip.Y, inset, viewport.Y - inset))
	-- Slide in from outside the viewport as the target first goes off screen.
	local entryPoint = tip + direction * (settings.Offset or 16)
	tip = entryPoint + (tip - entryPoint) * progress

	-- The chevron also grows from 65% as it slides in, so it lands rather
	-- than simply stopping.
	local size = baseSize * (0.65 + 0.35 * progress)
	local perpendicular = Vector2.new(-direction.Y, direction.X)
	local back = tip - direction * size
	local left = back + perpendicular * size * 0.6
	local right = back - perpendicular * size * 0.6

	local color = Occlusion.color(settings.Color, state, self.Global)
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

	if settings.Label then
		local distance = self.Global.Distance
		local scale = distance and distance.Scale or 1
		local suffix = distance and distance.Suffix or "m"
		local value = math.floor(state.Distance * scale + 0.5)
		if value ~= self.LastValue or suffix ~= self.LastSuffix then
			self.LastValue = value
			self.LastSuffix = suffix
			self.Text.Text = string.format("%d%s", value, suffix)
		end
		self.Text.TextSize = settings.TextSize or 11
		self.Text.Color = color
		self.Text.Transparency = transparency
		self.Text.Outline = true
		self.Text.OutlineTransparency = Occlusion.transparency(Alpha.apply(0.4, state.Alpha), state, self.Global)
		self.Text.Position = tip - direction * (settings.TextGap or 28)
		self.Text.Visible = true
	else
		self.Text.Visible = false
	end
end

function Arrow:Hide()
	self.LineA.Visible = false
	self.LineB.Visible = false
	self.Text.Visible = false
end

function Arrow:Destroy()
	self.LineA:Destroy()
	self.LineB:Destroy()
	self.Text:Destroy()
end

return Arrow
