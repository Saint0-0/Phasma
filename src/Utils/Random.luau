--[[
	Phasma/Utils/Random.luau

	Small random tags for instance names. A tag says nothing about the library,
	so a script that walks the DataModel cannot find it by name.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

-- Resolve the global Random before the module table shadows the name.
local rng = Random.new(os.clock() * 1000000 % 4294967296)

local Random = {}

local HEX = "0123456789abcdef"

function Random.hex(length)
	local parts = table.create(length)
	for index = 1, length do
		local pick = rng:NextInteger(1, #HEX)
		parts[index] = HEX:sub(pick, pick)
	end
	return table.concat(parts)
end

function Random.tag(prefix)
	return (prefix or "x") .. "_" .. Random.hex(6)
end

return Random
