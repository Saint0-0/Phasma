--[[
	Phasma/Modules/Skeleton.luau

	Bone segments for R6 and R15 rigs, drawn from a fixed line pool.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local POOL = 16

local Skeleton = {}
Skeleton.__index = Skeleton

function Skeleton.New(ctx)
	local self = setmetatable({}, Skeleton)
	self.Settings = ctx.Settings
	self.Lines = table.create(POOL)
	for index = 1, POOL do
		self.Lines[index] = ctx.Canvas:Line(ctx.ZIndex)
	end
	return self
end

function Skeleton:Update(state)
	local settings = self.Settings
	if not settings.Enabled then
		self:Hide()
		return
	end

	local bones = state.Bones
	for index = 1, POOL do
		local line = self.Lines[index]
		local bone = bones[index]
		if bone then
			line.From = bone.From
			line.To = bone.To
			line.Color = settings.Color
			line.Thickness = settings.Thickness
			line.Transparency = settings.Transparency
			line.Visible = true
		else
			line.Visible = false
		end
	end
end

function Skeleton:Hide()
	for _, line in ipairs(self.Lines) do
		line.Visible = false
	end
end

function Skeleton:Destroy()
	for _, line in ipairs(self.Lines) do
		line:Destroy()
	end
	table.clear(self.Lines)
end

return Skeleton
