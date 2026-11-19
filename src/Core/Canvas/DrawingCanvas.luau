--[[
	Phasma/Core/Canvas/DrawingCanvas.luau

	Drawing-API backend. Objects are thin proxies over Drawing instances so the
	elements never touch the executor API directly.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Constants = require("../../Constants")

-- Executor globals live in the script environment; getfenv reaches them.
local Drawing = getfenv().Drawing

local DrawingCanvas = {}
DrawingCanvas.__index = DrawingCanvas

local function apply(raw, key, value)
	if key == "Visible" then
		raw.Visible = value
	elseif key == "Color" then
		raw.Color = value
	elseif key == "Transparency" then
		raw.Transparency = value
	elseif key == "Thickness" then
		raw.Thickness = value
	elseif key == "Filled" then
		raw.Filled = value
	elseif key == "From" then
		raw.From = value
	elseif key == "To" then
		raw.To = value
	elseif key == "Position" then
		raw.Position = value
	elseif key == "Size" or key == "TextSize" then
		raw.Size = value
	elseif key == "Radius" then
		raw.Radius = value
	elseif key == "Text" then
		raw.Text = value
	elseif key == "Centered" then
		raw.Center = value
	elseif key == "Outline" then
		raw.Outline = value
	elseif key == "OutlineColor" then
		raw.OutlineColor = value
	elseif key == "ZIndex" then
		raw.ZIndex = value
	end
end

local Object = {}
Object.__index = function(self, key)
	local method = Object[key]
	if method ~= nil then
		return method
	end
	return rawget(self, "_props")[key]
end
Object.__newindex = function(self, key, value)
	local props = rawget(self, "_props")
	-- Drawing property writes cross into the executor's renderer, so only push
	-- values that actually changed.
	if props[key] == value then
		return
	end
	props[key] = value
	local raw = rawget(self, "_raw")
	if raw then
		apply(raw, key, value)
	end
end

-- Removes the Drawing object and drops it from the owner's list.
function Object:Destroy()
	local raw = rawget(self, "_raw")
	if not raw then
		return
	end
	rawset(self, "_raw", nil)
	rawset(rawget(self, "_props"), "Visible", false)

	local owner = rawget(self, "_owner")
	if owner then
		owner._objects[raw] = nil
	end
	pcall(function()
		raw:Remove()
	end)
end

-- TextBounds follows Text/TextSize on the Drawing object. A build that has not
-- refreshed it yet falls back to an estimate, which is close enough for a chip.
function Object:Measure()
	local raw = rawget(self, "_raw")
	if raw then
		local ok, bounds = pcall(function()
			return raw.TextBounds
		end)
		if ok and typeof(bounds) == "Vector2" and bounds.X > 0 then
			return bounds, true
		end
	end
	local props = rawget(self, "_props")
	local text = props.Text or ""
	local textSize = props.TextSize or 13
	return Vector2.new(#text * textSize * 0.5, textSize), false
end

function DrawingCanvas.available()
	return Drawing ~= nil and type(Drawing.new) == "function"
end

function DrawingCanvas.new()
	return setmetatable({ Kind = "Drawing", _objects = {} }, DrawingCanvas)
end

-- Always returns a proxy; a failed Drawing.new leaves it inert.
function DrawingCanvas:_create(kind, zIndex)
	local object = setmetatable({}, Object)
	rawset(object, "_props", { Visible = false, ZIndex = zIndex or 1 })
	rawset(object, "_owner", self)

	if Drawing ~= nil and type(Drawing.new) == "function" then
		local ok, raw = pcall(Drawing.new, kind)
		if ok and raw then
			raw.Visible = false
			raw.ZIndex = zIndex or 1
			rawset(object, "_raw", raw)
			self._objects[raw] = true
		end
	end
	return object
end

function DrawingCanvas:Line(zIndex)
	local object = self:_create("Line", zIndex)
	object.Color = Color3.new(1, 1, 1)
	object.Thickness = 1
	object.Transparency = 0
	object.From = Vector2.zero
	object.To = Vector2.zero
	return object
end

function DrawingCanvas:Rect(zIndex)
	local object = self:_create("Square", zIndex)
	object.Color = Color3.new(1, 1, 1)
	object.Thickness = 1
	object.Transparency = 0
	object.Filled = false
	object.Position = Vector2.zero
	object.Size = Vector2.zero
	return object
end

function DrawingCanvas:Text(zIndex)
	local object = self:_create("Text", zIndex)
	local raw = rawget(object, "_raw")
	if raw then
		raw.Font = Constants.DrawingFont
	end
	object.Color = Color3.new(1, 1, 1)
	object.Transparency = 0
	object.Text = ""
	object.TextSize = 13
	object.Centered = true
	object.Outline = true
	object.OutlineColor = Constants.OutlineColor
	object.Position = Vector2.zero
	return object
end

function DrawingCanvas:Circle(zIndex)
	local object = self:_create("Circle", zIndex)
	object.Color = Color3.new(1, 1, 1)
	object.Thickness = 1
	object.Transparency = 0
	object.Filled = false
	object.Position = Vector2.zero
	object.Radius = 4
	return object
end

function DrawingCanvas:Destroy()
	for raw in pairs(self._objects) do
		pcall(function()
			raw:Remove()
		end)
	end
	table.clear(self._objects)
end

return DrawingCanvas
