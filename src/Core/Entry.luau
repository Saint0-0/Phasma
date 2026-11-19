--[[
	Phasma/Core/Entry.luau

	One target's set of elements. Rebuilt whenever the character changes, so
	element objects never outlive the rig they were made for. The entry also
	owns the reusable frame state, which is why a frame allocates nothing.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Anim = require("../Utils/Anim")
local Target = require("./Target")
local Highlight = require("../Modules/Highlight")
local Tracer = require("../Modules/Tracer")
local Skeleton = require("../Modules/Skeleton")
local Box = require("../Modules/Box")
local Health = require("../Modules/Health")
local HeadDot = require("../Modules/HeadDot")
local Direction = require("../Modules/Direction")
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
	{ Name = "Direction", Module = Direction },
	{ Name = "Name", Module = Name },
	{ Name = "Distance", Module = Distance },
	{ Name = "Arrow", Module = Arrow },
}

-- Objects have no rig, so they only get the elements that make sense for a
-- Model or BasePart.
local OBJECT_ORDER = {
	{ Name = "Box", Module = Box },
	{ Name = "Name", Module = Name },
	{ Name = "Distance", Module = Distance },
	{ Name = "Arrow", Module = Arrow },
}

local function newEntry(esp, owner, character, order)
	local self = setmetatable({}, Entry)
	self.Owner = owner
	self.Character = character
	self.IsObject = false
	self.Retiring = false
	self.NextUpdate = 0
	self.Visible = true
	self.VisibleAt = 0
	self.WasOffscreen = false

	local animConfig = esp.Settings.Animations
	local pop = 0
	if animConfig and animConfig.Enabled then
		pop = animConfig.Pop or 0.06
	end

	self.Anim = {
		Alpha = 0,
		Slide = 0,
		-- Start slightly shrunk so the entry settles into place.
		Scale = 1 - pop,
		Tracer = 0,
		Arrow = 0,
		SlideOffset = animConfig and animConfig.Enabled and (animConfig.Slide or 8) or 0,
	}

	self.State = Target.newState()
	self.State.Anim = self.Anim
	self.Elements = {}

	for index, entry in ipairs(order) do
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

function Entry.new(esp, owner, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not humanoid or not root or not head then
		return nil
	end

	local self = newEntry(esp, owner, character, ORDER)
	self.Humanoid = humanoid
	self.Root = root
	self.Head = head
	self.Rig = character:FindFirstChild("UpperTorso") and "R15" or "R6"
	return self
end

function Entry.newObject(esp, owner, object)
	local self = newEntry(esp, owner, object, OBJECT_ORDER)
	self.IsObject = true
	self.Object = object
	self.Rig = "Object"
	return self
end

function Entry:Valid()
	if self.IsObject then
		return self.Object ~= nil and self.Object.Parent ~= nil
	end
	return self.Humanoid.Parent ~= nil and self.Root.Parent ~= nil and self.Head.Parent ~= nil
end

-- Steps the target-level transition. Returns false once a retiring entry has
-- faded out, which tells the caller to hide it for the rest of the frame.
function Entry:StepAnim(delta, settings)
	local anim = self.Anim
	local config = settings.Animations
	local target = self.Retiring and 0 or 1

	if config and config.Enabled then
		local speed = config.Speed or 12
		anim.Alpha = Anim.approach(anim.Alpha, target, speed, delta)
		anim.Slide = Anim.approach(anim.Slide, 1, speed, delta)
		anim.Scale = Anim.approach(anim.Scale, 1, speed, delta)
		anim.Tracer = Anim.approach(anim.Tracer, config.Tracer ~= false and target or 1, speed, delta)
		anim.Arrow = Anim.approach(anim.Arrow, config.Arrow ~= false and target or 1, speed, delta)
		anim.SlideOffset = (1 - anim.Slide) * (config.Slide or 8)
	else
		anim.Alpha = target
		anim.Slide = 1
		anim.Scale = 1
		anim.Tracer = 1
		anim.Arrow = 1
		anim.SlideOffset = 0
	end

	local base = self.State.BaseAlpha or 1
	self.State.Alpha = base * anim.Alpha

	-- Only a retiring entry can finish. A fading-in entry is always kept.
	return not self.Retiring or anim.Alpha > 0.01
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
