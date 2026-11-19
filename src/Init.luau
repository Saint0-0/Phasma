--[[
	Phasma/Init.luau

	Single entry point. Require this once and reach the library through it.
	CreateESP takes the settings table from Defaults and returns a running ESP.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("./Constants")
local Defaults = require("./Defaults")
local Canvas = require("./Core/Canvas")
local ESP = require("./Core/ESP")

local Phasma = {}

Phasma.Version = Constants.Version
Phasma.Defaults = Defaults
Phasma.Canvas = Canvas

function Phasma:CreateESP(Settings)
	local esp = ESP.new(Settings)
	esp:Start()
	return esp
end

return Phasma
