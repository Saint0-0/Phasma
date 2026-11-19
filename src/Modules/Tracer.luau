--[[
	Phasma/Modules/Tracer.luau

	Line from the screen edge to the target's feet.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local UserInputService = game:GetService("UserInputService")

local Tracer = {}
Tracer.__index = Tracer

function Tracer.New(ctx)
	local self = setmetatable({}, Tracer)
	self.Settings = ctx.Settings
	self.Line = ctx.Canvas:Line(ctx.ZIndex)
	return self
end

local function originFor(mode, viewport)
	if mode == "Center" then
		return Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
	elseif mode == "Mouse" then
		return UserInputService:GetMouseLocation()
	end
	return Vector2.new(viewport.X * 0.5, viewport.Y)
end

function Tracer:Update(state)
	local settings = self.Settings
	local camera = workspace.CurrentCamera
	if not settings.Enabled or not camera then
		self.Line.Visible = false
		return
	end

	self.Line.From = originFor(settings.From, camera.ViewportSize)
	self.Line.To = Vector2.new(state.Box.Center.X, state.Box.Position.Y + state.Box.Size.Y)
	self.Line.Color = settings.Color
	self.Line.Thickness = settings.Thickness
	self.Line.Transparency = settings.Transparency
	self.Line.Visible = true
end

function Tracer:Hide()
	self.Line.Visible = false
end

function Tracer:Destroy()
	self.Line:Destroy()
end

return Tracer
