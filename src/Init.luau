--[[
	Phasma/Init.luau

	Single entry point. Require this once and reach the library through it.
	CreateESP takes the settings table from Defaults and returns a running ESP.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("./Constants")
local Defaults = require("./Defaults")
local Presets = require("./Presets")
local Canvas = require("./Core/Canvas")
local ESP = require("./Core/ESP")

local Phasma = {}

Phasma.Version = Constants.Version
Phasma.Defaults = Defaults
Phasma.Presets = Presets
Phasma.Canvas = Canvas

-- Every ESP created through this module. Weak keys let destroyed instances
-- drop out; the dev panel uses the registry to guarantee a single engine.
local active = setmetatable({}, { __mode = "k" })

function Phasma:CreateESP(Settings)
	local esp = ESP.new(Settings)
	esp:Start()
	active[esp] = true
	return esp
end

function Phasma:GetActiveCount()
	local count = 0
	for _ in pairs(active) do
		count = count + 1
	end
	return count
end

-- Stops every ESP made through this module, so a stale script cannot leave a
-- second engine drawing behind the live one.
function Phasma:StopAll()
	for esp in pairs(active) do
		esp:Destroy()
	end
	table.clear(active)
end

return Phasma
