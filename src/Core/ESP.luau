--[[
	Phasma/Core/ESP.luau

	Owns the render loop, the target entries and the shared settings. Every
	frame collects the candidates, optionally sorts and caps them, resolves
	each one once and hands the result to that target's elements.

	Efficiency notes:
	  * entries own their frame state, so rendering allocates no tables
	  * candidate records are pooled and reused every frame
	  * NPCs are tracked by events with a slow safety rescan
	  * visibility raycasts are throttled per target
	  * far targets rebuild at LOD.UpdateInterval and animate in between
	  * off-screen targets skip raycasts and projection beyond the arrow

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Canvas = require("./Canvas")
local Camera = require("./Camera")
local Config = require("./Config")
local Entry = require("./Entry")
local Target = require("./Target")
local Presets = require("../Presets")

-- Safety net for models that appear without a Humanoid descendant event. The
-- event registry does the real work, so this walk stays rare.
local NPC_RESCAN = 8

local ESP = {}
ESP.__index = ESP

local function isEmpty(list)
	return list == nil or #list == 0
end

-- Lists accept names as well as UserIds, so a config can be shared without
-- knowing which account a name belongs to at the time.
local function listMatches(list, player, name)
	if isEmpty(list) then
		return false
	end
	for _, value in ipairs(list) do
		if value == name then
			return true
		end
		if player then
			if value == player.UserId or value == player.Name or value == player.DisplayName then
				return true
			end
			if player.Team and value == player.Team.Name then
				return true
			end
		end
	end
	return false
end

local function passesFilters(settings, player, name)
	local filters = settings.Filters
	if not filters or not filters.Enabled then
		return true
	end

	if not isEmpty(filters.Whitelist) and not listMatches(filters.Whitelist, player, name) then
		return false
	end
	if listMatches(filters.Blacklist, player, name) then
		return false
	end

	local contains = filters.NameContains
	if contains and contains ~= "" then
		if not string.find(string.lower(name), string.lower(contains), 1, true) then
			return false
		end
	end

	return true
end

local function bySort(a, b)
	return a.Sort < b.Sort
end

local function isBox(object)
	return object:IsA("Model") or object:IsA("BasePart")
end

local function matchesClasses(object, classes)
	if isEmpty(classes) then
		return true
	end
	for _, className in ipairs(classes) do
		if object:IsA(className) then
			return true
		end
	end
	return false
end

local function matchesName(object, names)
	if isEmpty(names) then
		return false
	end
	for _, name in ipairs(names) do
		if object.Name == name then
			return true
		end
	end
	return false
end

function ESP.new(settings)
	local self = setmetatable({}, ESP)
	self.Settings = Config.resolve(settings)
	self.Canvas = Canvas.new(self.Settings.Security)
	self._entries = {}
	self._connections = {}
	self._running = false

	self._npcSet = {}
	self._npcReady = false
	self._npcScan = 0

	self._objectSet = {}
	self._objectScan = 0

	-- Reused every frame; clearing is cheaper than allocating.
	self._seen = {}
	self._characters = {}
	self._filter = {}
	self._candidates = {}
	self._candidatePool = {}
	self._candidateCount = 0

	self._rayParams = RaycastParams.new()
	self._rayParams.FilterType = Enum.RaycastFilterType.Exclude
	self._rayParams.IgnoreWater = true
	self._rayParams.FilterDescendantsInstances = self._filter

	return self
end

function ESP:Start()
	if self._running then
		return
	end
	self._running = true

	self._connections[#self._connections + 1] = RunService.RenderStepped:Connect(function(delta)
		self:Render(delta)
	end)

	self._connections[#self._connections + 1] = Players.PlayerRemoving:Connect(function(player)
		self:_drop(player)
	end)

	-- Event-driven NPC registry. A model is registered when its Humanoid
	-- appears, which covers streamed-in characters without polling the tree.
	self._connections[#self._connections + 1] = workspace.DescendantAdded:Connect(function(instance)
		if instance:IsA("Humanoid") then
			local model = instance.Parent
			if model and model:IsA("Model") then
				self._npcSet[model] = true
			end
		end
	end)

	self._connections[#self._connections + 1] = workspace.DescendantRemoving:Connect(function(instance)
		if instance:IsA("Humanoid") then
			local model = instance.Parent
			if model then
				self._npcSet[model] = nil
			end
		end
	end)
end

function ESP:_drop(owner)
	local entry = self._entries[owner]
	if entry then
		entry:Destroy()
		self._entries[owner] = nil
	end
end

function ESP:_hide(owner)
	local entry = self._entries[owner]
	if entry then
		entry:Hide()
	end
end

function ESP:_hideAll()
	for _, entry in pairs(self._entries) do
		entry:Hide()
	end
end

function ESP:_scanNPCs()
	local set = self._npcSet
	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("Humanoid") then
			local model = instance.Parent
			if model and model:IsA("Model") then
				set[model] = true
			end
		end
	end
	self._npcReady = true
	self._npcScan = os.clock()
end

-- Rebuilds the object registry from tags, or by name when no tags are set.
-- Classes narrow the matches; with no names and no tags nothing matches, so
-- enabling the feature cannot accidentally box the entire workspace.
function ESP:_scanObjects()
	local objects = self.Settings.Objects
	local set = self._objectSet
	table.clear(set)
	self._objectScan = os.clock()

	if not objects or not objects.Enabled then
		return
	end

	local names = objects.Names
	local tags = objects.Tags
	local classes = objects.Classes

	if not isEmpty(tags) then
		for _, tag in ipairs(tags) do
			for _, instance in ipairs(CollectionService:GetTagged(tag)) do
				if isBox(instance) and matchesClasses(instance, classes) then
					set[instance] = true
				end
			end
		end
	elseif not isEmpty(names) then
		for _, instance in ipairs(workspace:GetDescendants()) do
			if isBox(instance) and matchesName(instance, names) and matchesClasses(instance, classes) then
				set[instance] = true
			end
		end
	end
end

local function isVisible(esp, camera, character, head, localCharacter)
	local filter = esp._filter
	filter[1] = character
	filter[2] = localCharacter
	esp._rayParams.FilterDescendantsInstances = filter

	local origin = camera.CFrame.Position
	local result = workspace:Raycast(origin, head.Position - origin, esp._rayParams)
	return result == nil
end

-- Candidate records are pooled, so a frame with an unchanged target count
-- allocates nothing. `Sort` is the active priority key.
function ESP:_nextCandidate()
	local index = self._candidateCount + 1
	self._candidateCount = index

	local record = self._candidatePool[index]
	if not record then
		record = {}
		self._candidatePool[index] = record
	end
	self._candidates[index] = record
	return record
end

function ESP:_sortKey(settings, distance, health, name)
	local filters = settings.Filters
	if filters and filters.Enabled then
		if filters.Priority == "Health" then
			return health
		elseif filters.Priority == "Name" then
			return string.lower(name)
		end
	end
	return distance
end

function ESP:_addCandidate(owner, character, player, origin, settings)
	local name = player and player.Name or character.Name
	if not passesFilters(settings, player, name) then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	local distance = (root.Position - origin).Magnitude
	if distance > settings.MaxDistance then
		return
	end

	local record = self:_nextCandidate()
	record.Owner = owner
	record.Character = character
	record.Object = nil
	record.Player = player
	record.Kind = "Humanoid"
	record.Name = name
	record.Distance = distance
	record.Health = humanoid.Health
	record.Sort = self:_sortKey(settings, distance, humanoid.Health, name)
end

function ESP:_addObjectCandidate(object, origin, settings)
	local objects = settings.Objects
	local position
	if object:IsA("BasePart") then
		position = object.Position
	else
		position = object:GetPivot().Position
	end

	local distance = (position - origin).Magnitude
	if distance > (objects.MaxDistance or settings.MaxDistance) then
		return
	end

	local record = self:_nextCandidate()
	record.Owner = object
	record.Character = object
	record.Object = object
	record.Player = nil
	record.Kind = "Object"
	record.Name = object.Name
	record.Distance = distance
	record.Health = math.huge
	record.Sort = self:_sortKey(settings, distance, math.huge, object.Name)
end

function ESP:_ensureEntry(owner, character, isObject)
	local entry = self._entries[owner]
	if entry and (entry.Character ~= character or not entry:Valid()) then
		entry:Destroy()
		self._entries[owner] = nil
		entry = nil
	end

	if not entry then
		if isObject then
			entry = Entry.newObject(self, owner, character)
		else
			entry = Entry.new(self, owner, character)
		end
		if not entry then
			return nil
		end
		self._entries[owner] = entry
	end

	return entry
end

function ESP:_drawHumanoid(owner, character, player, camera, origin, settings, localCharacter, delta, now)
	local entry = self:_ensureEntry(owner, character, false)
	if not entry then
		return false
	end

	local state = entry.State
	state.Delta = delta

	local lod = settings.LOD
	local interval = lod and lod.Enabled and (lod.UpdateInterval or 0.05) or 0
	local detailDistance = lod and lod.DetailDistance or 600
	local near = state.Distance <= detailDistance
	local shouldBuild = interval <= 0 or near or entry.NextUpdate <= now

	if shouldBuild then
		local name = player and player.Name or character.Name
		if not Target.build(entry, name, player, camera, origin, settings) then
			return false
		end
		entry.NextUpdate = state.Distance > detailDistance and (now + interval) or 0

		-- Entering the off-screen state is when the arrow should slide in;
		-- otherwise it would already be at full progress from its on-screen
		-- lifetime and would snap into place.
		local animations = settings.Animations
		if
			animations
			and animations.Enabled
			and animations.Arrow ~= false
			and state.Offscreen
			and not entry.WasOffscreen
		then
			entry.Anim.Arrow = 0
		end
		entry.WasOffscreen = state.Offscreen
	end

	entry.Retiring = false

	if state.Offscreen then
		state.Visible = true
		state.Occluded = false
	else
		state.Occluded = false
		if settings.VisibilityCheck then
			local visibleInterval = settings.VisibilityInterval or 0.12
			if now - entry.VisibleAt >= visibleInterval then
				entry.Visible = isVisible(self, camera, character, entry.Head, localCharacter)
				entry.VisibleAt = now
			end
			state.Visible = entry.Visible
			state.Occluded = not entry.Visible
			if not state.Visible and not settings.ShowOccluded then
				entry:Hide()
				return true
			end
		else
			entry.Visible = true
			state.Visible = true
		end
	end

	entry:StepAnim(delta, settings)
	entry:Draw(state)
	return true
end

function ESP:_drawObject(owner, object, camera, origin, settings, delta)
	local entry = self:_ensureEntry(owner, object, true)
	if not entry then
		return false
	end

	local state = entry.State
	state.Delta = delta

	if not Target.buildObject(entry, object.Name, object, camera, origin, settings) then
		return false
	end

	entry.Retiring = false
	state.Visible = true
	state.Occluded = false

	entry:StepAnim(delta, settings)
	entry:Draw(state)
	return true
end

function ESP:Render(delta)
	local settings = self.Settings
	if not settings.Enabled then
		self:_hideAll()
		self._candidateCount = 0
		return
	end

	local camera = Camera.get()
	local localPlayer = Players.LocalPlayer
	if not camera or not localPlayer then
		self:_hideAll()
		self._candidateCount = 0
		return
	end

	local now = os.clock()
	local localCharacter = localPlayer.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	local origin = localRoot and localRoot.Position or camera.CFrame.Position
	local localTeam = localPlayer.Team

	local characters = self._characters
	table.clear(characters)
	table.clear(self._candidates)
	self._candidateCount = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			characters[character] = true
		end

		local skip = settings.IgnoreLocal and player == localPlayer
		if not skip and settings.TeamCheck and localTeam and player.Team == localTeam then
			skip = true
		end

		if not skip and character and character.Parent then
			self:_addCandidate(player, character, player, origin, settings)
		end
	end

	if settings.IncludeNPCs then
		if not self._npcReady or now - self._npcScan >= NPC_RESCAN then
			self:_scanNPCs()
		end

		for model in pairs(self._npcSet) do
			if not model.Parent then
				self._npcSet[model] = nil
			elseif not characters[model] and model ~= localCharacter and not Players:GetPlayerFromCharacter(model) then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid and model:FindFirstChild("HumanoidRootPart") then
					self:_addCandidate(model, model, nil, origin, settings)
				end
			end
		end
	end

	local objects = settings.Objects
	if objects and objects.Enabled then
		if now - self._objectScan >= (objects.ScanInterval or 0.5) then
			self:_scanObjects()
		end
		for object in pairs(self._objectSet) do
			if not object.Parent then
				self._objectSet[object] = nil
			else
				self:_addObjectCandidate(object, origin, settings)
			end
		end
	elseif next(self._objectSet) ~= nil then
		table.clear(self._objectSet)
	end

	local filters = settings.Filters
	local maxTargets = 0
	if filters and filters.Enabled then
		maxTargets = filters.MaxTargets or 0
		table.sort(self._candidates, bySort)
	end

	local seen = self._seen
	table.clear(seen)

	for index = 1, self._candidateCount do
		local record = self._candidates[index]
		local owner = record.Owner
		local selected = maxTargets <= 0 or index <= maxTargets
		seen[owner] = true

		if selected then
			local ok
			if record.Kind == "Object" then
				ok = self:_drawObject(owner, record.Object, camera, origin, settings, delta)
			else
				ok = self:_drawHumanoid(
					owner,
					record.Character,
					record.Player,
					camera,
					origin,
					settings,
					localCharacter,
					delta,
					now
				)
			end
			if not ok then
				seen[owner] = nil
			end
		else
			-- Over the cap: hide without retiring, so the entry can return
			-- instantly if the cap ranking changes next frame.
			local entry = self._entries[owner]
			if entry then
				if entry:Valid() then
					entry:Hide()
				else
					entry:Destroy()
					self._entries[owner] = nil
				end
			end
		end
	end

	-- Anything not seen this frame fades out, then is destroyed. A rig that
	-- has already disappeared is destroyed immediately.
	for owner, entry in pairs(self._entries) do
		if not seen[owner] then
			if not entry:Valid() then
				entry:Destroy()
				self._entries[owner] = nil
			else
				if not entry.Retiring then
					entry.Retiring = true
					entry.NextUpdate = 0
				end
				entry.State.Delta = delta
				if not entry:StepAnim(delta, settings) then
					entry:Destroy()
					self._entries[owner] = nil
				else
					entry:Draw(entry.State)
				end
			end
		end
	end
end

function ESP:SetEnabled(enabled)
	self.Settings.Enabled = enabled == true
	if not self.Settings.Enabled then
		self:_hideAll()
	end
end

function ESP:Toggle()
	self:SetEnabled(not self.Settings.Enabled)
	return self.Settings.Enabled
end

function ESP:SetMaxDistance(distance)
	self.Settings.MaxDistance = distance
end

-- Applies a named preset from Presets. Only the keys the preset declares are
-- touched, so filters, security and distances keep their current values.
function ESP:ApplyPreset(name)
	return Presets.apply(self.Settings, name)
end

function ESP:ListPresets()
	return Presets.names()
end

function ESP:Stop()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self._npcSet)
	table.clear(self._objectSet)
	table.clear(self._candidates)
	self._candidateCount = 0
	self._npcReady = false
	self._running = false
	self:_hideAll()
end

function ESP:Destroy()
	self:Stop()
	for _, entry in pairs(self._entries) do
		entry:Destroy()
	end
	table.clear(self._entries)
	self.Canvas:Destroy()
end

return ESP
