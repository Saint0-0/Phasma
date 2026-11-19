--[[
	Phasma/Modules/Highlight.luau

	Engine Highlight on the character, the chams-style element. With security
	enabled the instance gets a random name and is parented to the camera instead
	of the character, so a script scanning the character will not find it.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Random = require("../Utils/Random")

local Highlight = {}
Highlight.__index = Highlight

function Highlight.New(ctx)
	local self = setmetatable({}, Highlight)
	self.Settings = ctx.Settings
	self.Cached = {}

	local security = ctx.Global.Security
	if type(security) ~= "table" then
		security = { Enabled = false }
	end
	local active = security.Enabled ~= false
	local randomize = active and security.RandomizeNames ~= false
	local hidden = active and security.HideHighlight ~= false

	local instance = Instance.new("Highlight")
	instance.Name = randomize and Random.tag("fx") or "PhasmaHighlight"
	instance.Enabled = false
	instance.FillTransparency = 1
	instance.OutlineTransparency = 1

	local parent = ctx.Character
	if hidden then
		parent = workspace.CurrentCamera or ctx.Character
	end
	instance.Parent = parent

	self.Instance = instance
	return self
end

function Highlight:Update(state)
	local settings = self.Settings
	local instance = self.Instance
	local cached = self.Cached

	if not settings.Enabled then
		if cached.Enabled ~= false then
			instance.Enabled = false
			cached.Enabled = false
		end
		return
	end

	if instance.Adornee ~= state.Character then
		instance.Adornee = state.Character
	end
	if cached.Fill ~= settings.Fill then
		instance.FillColor = settings.Fill
		cached.Fill = settings.Fill
	end
	if cached.Outline ~= settings.Outline then
		instance.OutlineColor = settings.Outline
		cached.Outline = settings.Outline
	end
	if cached.FillTransparency ~= settings.FillTransparency then
		instance.FillTransparency = settings.FillTransparency
		cached.FillTransparency = settings.FillTransparency
	end
	if cached.OutlineTransparency ~= settings.OutlineTransparency then
		instance.OutlineTransparency = settings.OutlineTransparency
		cached.OutlineTransparency = settings.OutlineTransparency
	end
	if cached.DepthMode ~= settings.DepthMode then
		instance.DepthMode = Enum.HighlightDepthMode[settings.DepthMode] or Enum.HighlightDepthMode.AlwaysOnTop
		cached.DepthMode = settings.DepthMode
	end
	if cached.Enabled ~= true then
		instance.Enabled = true
		cached.Enabled = true
	end
end

function Highlight:Hide()
	if self.Cached.Enabled ~= false then
		self.Instance.Enabled = false
		self.Cached.Enabled = false
	end
end

function Highlight:Destroy()
	self.Instance:Destroy()
end

return Highlight
