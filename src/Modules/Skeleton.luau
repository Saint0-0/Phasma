--[[
	Phasma/Modules/Skeleton.luau

	Bone segments for R6 and R15 rigs, drawn from a fixed line pool. Optional
	joint dots sit on the same projected points.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Alpha = require("../Utils/Alpha")

local POOL = 16
local DOTS = 20

local Skeleton = {}
Skeleton.__index = Skeleton

function Skeleton.New(ctx)
	local self = setmetatable({}, Skeleton)
	self.Settings = ctx.Settings
	self.Canvas = ctx.Canvas
	self.ZIndex = ctx.ZIndex
	self.Lines = table.create(POOL)
	for index = 1, POOL do
		self.Lines[index] = ctx.Canvas:Line(ctx.ZIndex)
	end
	-- Joint dots are created on first use, so the default settings do not pay
	-- for 20 extra canvas objects per target.
	self.Dots = nil
	return self
end

function Skeleton:Update(state)
	local settings = self.Settings
	if not settings.Enabled then
		self:Hide()
		return
	end

	local transparency = Alpha.apply(settings.Transparency, state.Alpha)
	local color = settings.Color
	local thickness = settings.Thickness
	local count = state.BoneCount

	for index = 1, POOL do
		local line = self.Lines[index]
		if index <= count then
			local bone = state.Bones[index]
			line.From = bone.From
			line.To = bone.To
			line.Color = color
			line.Thickness = thickness
			line.Transparency = transparency
			line.Visible = true
		else
			line.Visible = false
		end
	end

	if settings.Joints then
		if not self.Dots then
			self.Dots = table.create(DOTS)
			for index = 1, DOTS do
				self.Dots[index] = self.Canvas:Circle(self.ZIndex)
			end
		end

		local radius = settings.JointRadius or 2
		local pointCount = state.PointCount
		for index = 1, DOTS do
			local dot = self.Dots[index]
			if index <= pointCount then
				dot.Position = state.Points[index]
				dot.Radius = radius
				dot.Color = color
				dot.Filled = true
				dot.Thickness = 1
				dot.Transparency = transparency
				dot.Visible = true
			else
				dot.Visible = false
			end
		end
	elseif self.Dots then
		for _, dot in ipairs(self.Dots) do
			dot.Visible = false
		end
	end
end

function Skeleton:Hide()
	for _, line in ipairs(self.Lines) do
		line.Visible = false
	end
	if self.Dots then
		for _, dot in ipairs(self.Dots) do
			dot.Visible = false
		end
	end
end

function Skeleton:Destroy()
	for _, line in ipairs(self.Lines) do
		line:Destroy()
	end
	if self.Dots then
		for _, dot in ipairs(self.Dots) do
			dot:Destroy()
		end
		table.clear(self.Dots)
	end
	table.clear(self.Lines)
end

return Skeleton
