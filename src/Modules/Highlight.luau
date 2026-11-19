--[[
	Phasma/Modules/Highlight.luau

	Engine Highlight on the character, the chams-style element.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Highlight = {}
Highlight.__index = Highlight

function Highlight.New(ctx)
	local self = setmetatable({}, Highlight)
	self.Settings = ctx.Settings
	self.Instance = Instance.new("Highlight")
	self.Instance.Name = "PhasmaHighlight"
	self.Instance.Enabled = false
	self.Instance.FillTransparency = 1
	self.Instance.OutlineTransparency = 1
	self.Instance.Parent = ctx.Character
	return self
end

function Highlight:Update(state)
	local settings = self.Settings
	if not settings.Enabled then
		self.Instance.Enabled = false
		return
	end

	local depth = Enum.HighlightDepthMode[settings.DepthMode]
	self.Instance.Adornee = state.Character
	self.Instance.FillColor = settings.Fill
	self.Instance.OutlineColor = settings.Outline
	self.Instance.FillTransparency = settings.FillTransparency
	self.Instance.OutlineTransparency = settings.OutlineTransparency
	self.Instance.DepthMode = depth or Enum.HighlightDepthMode.AlwaysOnTop
	self.Instance.Enabled = true
end

function Highlight:Hide()
	self.Instance.Enabled = false
end

function Highlight:Destroy()
	self.Instance:Destroy()
end

return Highlight
