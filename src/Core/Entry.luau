--[[
	Phasma/Core/Entry.luau

	One target's set of elements. Rebuilt whenever the character changes, so
	element objects never outlive the rig they were made for. The entry also
	owns the reusable frame state, which is why a frame allocates nothing.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Target = require("./Target")
local Highlight = require("../Modules/Highlight")
local Tracer = require("../Modules/Tracer")
local Skeleton = require("../Modules/Skeleton")
local Box = require("../Modules/Box")
local Health = require("../Modules/Health")
local HeadDot = require("../Modules/HeadDot")
local Name = require("../Modules/Name")
local Distance = require("../Modules/Distance")
local Arrow = require("../Modules/Arrow")

local Entry = {}
Entry.__index = Entry

-- Order is also the z-order, back to front.
local ORDER = {
	{ Name = "Highlight", Module = Highlight },
	{ Name = "Tracer", Module = Tracer },
	{ Name = "Skeleton", Module = Skeleton },
	{ Name = "Box", Module = Box },
	{ Name = "Health", Module = Health },
	{ Name = "HeadDot", Module = HeadDot },
	{ Name = "Name", Module = Name },
	{ Name = "Distance", Module = Distance },
	{ Name = "Arrow", Module = Arrow },
}

function Entry.new(esp, owner, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not humanoid or not root or not head then
		return nil
	end

	local self = setmetatable({}, Entry)
	self.Owner = owner
	self.Character = character
	self.Humanoid = humanoid
	self.Root = root
	self.Head = head
	self.Rig = character:FindFirstChild("UpperTorso") and "R15" or "R6"
	self.State = Target.newState()
	self.Visible = true
	self.VisibleAt = 0
	self.Elements = {}

	for index, entry in ipairs(ORDER) do
		local settings = esp.Settings[entry.Name]
		if settings then
			self.Elements[#self.Elements + 1] = entry.Module.New({
				Canvas = esp.Canvas,
				Settings = settings,
				Global = esp.Settings,
				ZIndex = index,
				Character = character,
			})
		end
	end

	return self
end

function Entry:Valid()
	return self.Humanoid.Parent ~= nil and self.Root.Parent ~= nil and self.Head.Parent ~= nil
end

function Entry:Draw(state)
	for _, element in ipairs(self.Elements) do
		-- The arrow is the only element that draws while the target is off
		-- screen; everything else would be using a stale box.
		if state.Offscreen and not element.OffscreenOnly then
			element:Hide()
		else
			element:Update(state)
		end
	end
end

function Entry:Hide()
	for _, element in ipairs(self.Elements) do
		element:Hide()
	end
end

function Entry:Destroy()
	for _, element in ipairs(self.Elements) do
		element:Destroy()
	end
	table.clear(self.Elements)
end

return Entry
