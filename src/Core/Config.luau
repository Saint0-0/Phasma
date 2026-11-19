--[[
	Phasma/Core/Config.luau

	Merges user settings over Defaults without mutating either table.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Defaults = require("../Defaults")

local Config = {}

local function isPlainTable(value)
	return type(value) == "table" and getmetatable(value) == nil
end

local function merge(base, override)
	local out = {}
	for key, value in pairs(base) do
		if isPlainTable(value) and isPlainTable(override[key]) then
			out[key] = merge(value, override[key])
		elseif override[key] ~= nil then
			out[key] = override[key]
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

-- A copy so callers can mutate esp.Settings live without touching Defaults.
function Config.resolve(settings)
	return merge(Defaults, isPlainTable(settings) and settings or {})
end

return Config
