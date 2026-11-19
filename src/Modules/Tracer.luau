--[[
	Phasma/Modules/Tracer.luau

	Line from the screen edge to the target's feet. The line draws out of its
	origin on spawn, a faint wider line behind it reads as glow, and a spark
	rides the tip while the draw is still in progress.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UserInputService = game:GetService("UserInputService")

local Alpha = require("../Utils/Alpha")
local Occlusion = require("../Utils/Occlusion")

local Tracer = {}
Tracer.__index = Tracer

function Tracer.New(ctx)
	local self = setmetatable({}, Tracer)
	self.Settings = ctx.Settings
	self.Global = ctx.Global
	-- Created first so the glow sits behind the core line.
	self.Glow = ctx.Canvas:Line(ctx.ZIndex)
	self.Line = ctx.Canvas:Line(ctx.ZIndex)
	self.Spark = ctx.Canvas:Circle(ctx.ZIndex)
	return self
end

local function originFor(mode, viewport)
	if mode == "Top" then
		return Vector2.new(viewport.X * 0.5, 0)
	elseif mode == "Left" then
		return Vector2.new(0, viewport.Y * 0.5)
	elseif mode == "Right" then
		return Vector2.new(viewport.X, viewport.Y * 0.5)
	elseif mode == "Center" then
		return Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
	elseif mode == "Mouse" then
		return UserInputService:GetMouseLocation()
	end
	return Vector2.new(viewport.X * 0.5, viewport.Y)
end

function Tracer:Update(state)
	local settings = self.Settings
	local camera = workspace.CurrentCamera
	if not settings.Enabled or not state.ShowTracer or not camera then
		self:Hide()
		return
	end

	local anim = state.Anim
	local progress = anim and (anim.TracerEased or anim.Tracer) or 1
	if progress <= 0.01 then
		self:Hide()
		return
	end

	local from = originFor(settings.From, camera.ViewportSize)
	local target = Vector2.new(state.Box.Center.X, state.Box.Position.Y + state.Box.Size.Y)
	local tip = from + (target - from) * progress

	local color = Occlusion.color(state.TeamColor or settings.Color, state, self.Global)
	local transparency = Occlusion.transparency(Alpha.apply(settings.Transparency, state.Alpha), state, self.Global)
	local thickness = settings.Thickness or 1

	if settings.Glow ~= false then
		self.Glow.From = from
		self.Glow.To = tip
		self.Glow.Color = color
		self.Glow.Thickness = settings.GlowThickness or math.max(3, thickness + 2)
		self.Glow.Transparency = math.clamp(transparency + (settings.GlowTransparency or 0.35), 0, 1)
		self.Glow.Visible = true
	else
		self.Glow.Visible = false
	end

	self.Line.From = from
	self.Line.To = tip
	self.Line.Color = color
	self.Line.Thickness = thickness
	self.Line.Transparency = transparency
	self.Line.Visible = true

	-- The spark only exists during the draw, so it disappears once the line
	-- has reached the target instead of pulsing forever.
	if settings.Spark ~= false and progress < 0.995 then
		-- Fade the spark over the last stretch so it hands off to the finished
		-- line instead of blinking out.
		local sparkFade = math.clamp((0.995 - progress) / 0.2, 0, 1)
		self.Spark.Position = tip
		self.Spark.Radius = thickness * 1.6 + 1
		self.Spark.Color = color
		self.Spark.Filled = true
		self.Spark.Thickness = 1
		self.Spark.Transparency = math.clamp(transparency - 0.15 + (1 - sparkFade) * 0.8, 0, 1)
		self.Spark.Visible = true
	else
		self.Spark.Visible = false
	end
end

function Tracer:Hide()
	self.Glow.Visible = false
	self.Line.Visible = false
	self.Spark.Visible = false
end

function Tracer:Destroy()
	self.Glow:Destroy()
	self.Line:Destroy()
	self.Spark:Destroy()
end

return Tracer
