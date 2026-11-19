--[[
	Phasma/Presets.luau

	Named looks applied through esp:ApplyPreset(name). Each definition starts
	from the visual defaults and only overrides what the preset needs, so a
	preset never resets filters, security or distances the caller configured.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Defaults = require("./Defaults")
local Config = require("./Core/Config")

local Presets = {}

-- Only the appearance blocks are owned by a preset. Globals, filters, LOD
-- thresholds and object matching stay where the caller put them.
local SECTIONS = {
	"Animations",
	"Box",
	"Name",
	"Distance",
	"Health",
	"Tracer",
	"Skeleton",
	"HeadDot",
	"Highlight",
	"Direction",
	"Arrow",
}

local function isPlainTable(value)
	return type(value) == "table" and getmetatable(value) == nil
end

local function merge(base, override)
	local out = {}
	for key, value in pairs(base) do
		local replacement = override[key]
		if isPlainTable(value) and isPlainTable(replacement) then
			out[key] = merge(value, replacement)
		elseif replacement ~= nil then
			out[key] = replacement
		elseif isPlainTable(value) then
			out[key] = merge(value, {})
		else
			out[key] = value
		end
	end
	for key, value in pairs(override) do
		if out[key] == nil then
			out[key] = value
		end
	end
	return out
end

local function preset(overrides)
	local out = {}
	for _, name in ipairs(SECTIONS) do
		out[name] = merge(Defaults[name], {})
	end
	return merge(out, overrides or {})
end

local Definitions = {}

Definitions.Default = preset({})

Definitions.Minimal = preset({
	Box = { Enabled = true },
	Name = { Enabled = true, Background = false },
	Distance = { Enabled = false },
	Health = { Enabled = false },
	Tracer = { Enabled = false },
	Skeleton = { Enabled = false },
	HeadDot = { Enabled = false },
	Highlight = { Enabled = false },
	Direction = { Enabled = false },
	Arrow = { Enabled = false },
})

Definitions.Clean = preset({
	Box = { Enabled = true },
	Name = { Enabled = true },
	Distance = { Enabled = true },
	Health = { Enabled = true },
	Tracer = { Enabled = false },
	Skeleton = { Enabled = false },
	HeadDot = { Enabled = false },
	Highlight = { Enabled = false },
	Direction = { Enabled = false },
	Arrow = { Enabled = false },
})

Definitions.Sniper = preset({
	Box = { Enabled = true, Style = "Corners" },
	Name = { Enabled = true },
	Distance = { Enabled = true },
	Health = { Enabled = true },
	Tracer = { Enabled = false },
	Skeleton = { Enabled = false },
	HeadDot = { Enabled = false },
	Highlight = { Enabled = false },
	Direction = { Enabled = true },
	Arrow = { Enabled = true },
})

Definitions.Rage = preset({
	Box = { Enabled = true, Style = "Both", Thickness = 2, Glow = true },
	Name = { Enabled = true, Background = true },
	Distance = { Enabled = true },
	Health = { Enabled = true, ShowText = true, Percent = true },
	Tracer = { Enabled = true, Thickness = 2 },
	Skeleton = { Enabled = true, Joints = true },
	HeadDot = { Enabled = true, Radius = 3 },
	Highlight = { Enabled = true, Preset = "Solid" },
	Direction = { Enabled = true, Thickness = 2 },
	Arrow = { Enabled = true, Label = true },
})

Definitions.Chams = preset({
	Box = { Enabled = false },
	Name = { Enabled = false },
	Distance = { Enabled = false },
	Health = { Enabled = false },
	Tracer = { Enabled = false },
	Skeleton = { Enabled = false },
	HeadDot = { Enabled = false },
	Highlight = { Enabled = true, Preset = "Solid", UseTeamColor = true },
	Direction = { Enabled = false },
	Arrow = { Enabled = false },
})

Definitions.Performance = preset({
	Animations = { Enabled = false },
	Box = { Enabled = true, Glow = false, Filled = false },
	Name = { Enabled = true, Background = false },
	Distance = { Enabled = true, Background = false },
	Health = { Enabled = false },
	Tracer = { Enabled = false },
	Skeleton = { Enabled = false },
	HeadDot = { Enabled = false },
	Highlight = { Enabled = false },
	Direction = { Enabled = false },
	Arrow = { Enabled = true, Label = false },
})

Presets.Definitions = Definitions

function Presets.get(name)
	return Definitions[name]
end

function Presets.names()
	local list = {}
	for name in pairs(Definitions) do
		list[#list + 1] = name
	end
	table.sort(list)
	return list
end

-- Applies only the preset's keys, in place, so element modules keep their
-- settings references.
function Presets.apply(settings, name)
	local definition = Definitions[name]
	if not definition then
		return false
	end
	Config.apply(settings, definition)
	return true
end

return Presets
