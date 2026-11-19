--[[
	Phasma/Modules/Highlight.luau

	Engine Highlight on the character, the chams-style element. Presets shape
	the fill and outline, a team colour can replace both, and the module keeps
	the engine's 31-instance ceiling from being exceeded. With security enabled
	the instance gets a random name and is parented to the camera instead of the
	character, so a script scanning the character will not find it.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Alpha = require("../Utils/Alpha")
local Occlusion = require("../Utils/Occlusion")
local Random = require("../Utils/Random")

local Highlight = {}
Highlight.__index = Highlight

-- Shared across every entry: the engine only keeps 31 Highlight instances.
local activeCount = 0

local PRESETS = {
	Solid = { FillTransparency = 0.55, OutlineTransparency = 0.1 },
	Outline = { FillTransparency = 1, OutlineTransparency = 0.1 },
	Glow = { FillTransparency = 0.92, OutlineTransparency = 0 },
	Soft = { FillTransparency = 0.78, OutlineTransparency = 0.45 },
}

function Highlight.New(ctx)
	local self = setmetatable({}, Highlight)
	self.Settings = ctx.Settings
	self.Global = ctx.Global
	self.Cached = {}
	self.Registered = false

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
		self:Hide()
		return
	end

	local preset = PRESETS[settings.Preset]
	local fillTransparency = preset and preset.FillTransparency or settings.FillTransparency
	local outlineTransparency = preset and preset.OutlineTransparency or settings.OutlineTransparency

	local fillColor = settings.Fill
	local outlineColor = settings.Outline
	if settings.UseTeamColor and state.TeamColor then
		fillColor = state.TeamColor
		outlineColor = state.TeamColor:Lerp(Color3.new(1, 1, 1), 0.55)
	end

	fillTransparency = Occlusion.transparency(Alpha.apply(fillTransparency, state.Alpha), state, self.Global)
	outlineTransparency = Occlusion.transparency(Alpha.apply(outlineTransparency, state.Alpha), state, self.Global)

	-- The first 31 live highlights win; later targets keep the other elements.
	if not self.Registered then
		local limit = settings.MaxInstances or 31
		if activeCount >= limit then
			self:Hide()
			return
		end
		activeCount = activeCount + 1
		self.Registered = true
	end

	if instance.Adornee ~= state.Character then
		instance.Adornee = state.Character
	end
	if cached.Fill ~= fillColor then
		instance.FillColor = fillColor
		cached.Fill = fillColor
	end
	if cached.Outline ~= outlineColor then
		instance.OutlineColor = outlineColor
		cached.Outline = outlineColor
	end
	if cached.FillTransparency ~= fillTransparency then
		instance.FillTransparency = fillTransparency
		cached.FillTransparency = fillTransparency
	end
	if cached.OutlineTransparency ~= outlineTransparency then
		instance.OutlineTransparency = outlineTransparency
		cached.OutlineTransparency = outlineTransparency
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
	if self.Registered then
		activeCount = math.max(0, activeCount - 1)
		self.Registered = false
	end
	if self.Cached.Enabled ~= false then
		self.Instance.Enabled = false
		self.Cached.Enabled = false
	end
end

function Highlight:Destroy()
	self:Hide()
	self.Instance:Destroy()
end

return Highlight
