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
	self.OffscreenAt = 0

	local animConfig = esp.Settings.Animations
	local animated = animConfig and animConfig.Enabled

	-- Each channel is a raw 0..1 track. The eased display values below it are
	-- recomputed every frame in StepAnim, so the modules never apply easing.
	local start = animated and 0 or 1
	self.Anim = {
		Fade = start,
		Pop = start,
		Slide = start,
		Sweep = animated and 0 or 1,
		Tracer = start,
		Arrow = start,
		-- Display values consumed by the element modules.
		Scale = 1,
		SlideOffset = 0,
		SweepEased = animated and 0 or 1,
		TracerEased = start,
		ArrowEased = start,
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

-- Scales a base duration by the global speed multiplier. A multiplier of 0
-- (or less) collapses every channel to an instant snap.
local function duration(config, base)
	local speed = config.Speed
	if speed == nil then
		speed = 1
	end
	if speed <= 0 then
		return 0
	end
	return base / speed
end

-- Steps the target-level transition. Returns false once a retiring entry has
-- faded out, which tells the caller to hide it for the rest of the frame.
function Entry:StepAnim(delta, settings)
	local anim = self.Anim
	local config = settings.Animations
	local target = self.Retiring and 0 or 1
	local on = config and config.Enabled

	if on then
		local fadeDuration = duration(config, config.FadeDuration or 0.25)
		local popDuration = duration(config, config.PopDuration or 0.34)
		local slideDuration = duration(config, config.SlideDuration or 0.3)
		local sweepDuration = duration(config, config.SweepDuration or 0.36)
		local tracerDuration = duration(config, config.TracerDuration or 0.5)
		local arrowDuration = duration(config, config.ArrowDuration or 0.32)

		if config.Fade ~= false then
			anim.Fade = Anim.step(anim.Fade, target, fadeDuration, delta)
		else
			anim.Fade = target
		end
		-- Pop and slide only animate inward; a retiring target fades out
		-- without also shrinking or pulling its chips away.
		if config.Pop ~= false then
			anim.Pop = Anim.step(anim.Pop, 1, popDuration, delta)
		else
			anim.Pop = 1
		end
		if config.Slide ~= false then
			anim.Slide = Anim.step(anim.Slide, 1, slideDuration, delta)
		else
			anim.Slide = 1
		end
		if config.Sweep ~= false then
			anim.Sweep = Anim.step(anim.Sweep, 1, sweepDuration, delta)
		else
			anim.Sweep = 1
		end
		-- The tracer and arrow only animate inward. A retiring entry fades
		-- out with its other elements instead of un-drawing the line.
		if config.Tracer ~= false then
			anim.Tracer = Anim.step(anim.Tracer, 1, tracerDuration, delta)
		else
			anim.Tracer = 1
		end
		if config.Arrow ~= false then
			anim.Arrow = Anim.step(anim.Arrow, 1, arrowDuration, delta)
		else
			anim.Arrow = 1
		end
	else
		anim.Fade = target
		anim.Pop = target
		anim.Slide = target
		anim.Sweep = 1
		anim.Tracer = 1
		anim.Arrow = 1
	end

	-- Display values, derived once per frame.
	local popAmount = on and config.Pop ~= false and (config.PopAmount or 0.14) or 0
	local slideDistance = on and config.Slide ~= false and (config.SlideDistance or 14) or 0

	anim.Scale = 1 - popAmount * (1 - Anim.back(anim.Pop, 1.4))
	anim.SlideOffset = (1 - Anim.cubic(anim.Slide)) * slideDistance
	anim.SweepEased = Anim.cubic(anim.Sweep)
	anim.TracerEased = Anim.cubic(anim.Tracer)
	anim.ArrowEased = Anim.cubic(anim.Arrow)

	local base = self.State.BaseAlpha or 1
	self.State.Alpha = base * Anim.cubic(anim.Fade)

	-- Only a retiring entry can finish. A fading-in entry is always kept.
	return not self.Retiring or anim.Fade > 0.01
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
