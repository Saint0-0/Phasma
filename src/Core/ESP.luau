--[[
	Phasma/Core/ESP.luau

	Owns the render loop, the target entries and the shared settings. Every
	frame resolves each target once and hands the result to that target's
	elements. Players and, optionally, humanoid NPCs are both supported.

	Efficiency notes:
	  * entries own their frame state, so rendering allocates no tables
	  * NPCs are tracked by events with a slow safety rescan
	  * visibility raycasts are throttled per target
	  * off-screen targets skip raycasts and projection beyond the arrow

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Canvas = require("./Canvas")
local Camera = require("./Camera")
local Config = require("./Config")
local Entry = require("./Entry")
local Target = require("./Target")

-- Safety net for models that appear without a Humanoid descendant event. The
-- event registry does the real work, so this walk stays rare.
local NPC_RESCAN = 8

local ESP = {}
ESP.__index = ESP

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

	-- Reused every frame; clearing is cheaper than allocating.
	self._seen = {}
	self._characters = {}
	self._filter = {}

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

local function isVisible(esp, camera, character, head, localCharacter)
	local filter = esp._filter
	filter[1] = character
	filter[2] = localCharacter
	esp._rayParams.FilterDescendantsInstances = filter

	local origin = camera.CFrame.Position
	local result = workspace:Raycast(origin, head.Position - origin, esp._rayParams)
	return result == nil
end

function ESP:_draw(owner, character, player, camera, origin, settings, localCharacter, delta)
	local entry = self._entries[owner]
	if entry and (entry.Character ~= character or not entry:Valid()) then
		entry:Destroy()
		self._entries[owner] = nil
		entry = nil
	end

	if not entry then
		entry = Entry.new(self, owner, character)
		if not entry then
			return
		end
		self._entries[owner] = entry
	end

	entry.State.Delta = delta
	local name = player and player.Name or character.Name
	if not Target.build(entry, name, player, camera, origin, settings) then
		entry:Hide()
		return
	end

	local state = entry.State
	-- Off-screen targets draw only the arrow; raycasting them is wasted work.
	if state.Offscreen then
		state.Visible = true
		state.Occluded = false
		entry:Draw(state)
		return
	end

	state.Occluded = false
	if settings.VisibilityCheck then
		local now = os.clock()
		local interval = settings.VisibilityInterval or 0.12
		if now - entry.VisibleAt >= interval then
			entry.Visible = isVisible(self, camera, character, entry.Head, localCharacter)
			entry.VisibleAt = now
		end
		state.Visible = entry.Visible
		state.Occluded = not entry.Visible
	else
		entry.Visible = true
		state.Visible = true
	end

	if state.Visible or settings.ShowOccluded then
		entry:Draw(state)
	else
		entry:Hide()
	end
end

function ESP:Render(delta)
	local settings = self.Settings
	if not settings.Enabled then
		self:_hideAll()
		return
	end

	local camera = Camera.get()
	local localPlayer = Players.LocalPlayer
	if not camera or not localPlayer then
		self:_hideAll()
		return
	end

	local localCharacter = localPlayer.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	local origin = localRoot and localRoot.Position or camera.CFrame.Position
	local localTeam = localPlayer.Team

	local seen = self._seen
	local characters = self._characters
	table.clear(seen)
	table.clear(characters)

	for _, player in ipairs(Players:GetPlayers()) do
		seen[player] = true
		local character = player.Character
		if character then
			characters[character] = true
		end

		local skip = settings.IgnoreLocal and player == localPlayer
		if not skip and settings.TeamCheck and localTeam and player.Team == localTeam then
			skip = true
		end

		if skip or not character or not character.Parent then
			self:_hide(player)
		else
			self:_draw(player, character, player, camera, origin, settings, localCharacter, delta)
		end
	end

	if settings.IncludeNPCs then
		local now = os.clock()
		if not self._npcReady or now - self._npcScan >= NPC_RESCAN then
			self:_scanNPCs()
		end

		for model in pairs(self._npcSet) do
			if not model.Parent then
				self._npcSet[model] = nil
			elseif not characters[model] and model ~= localCharacter and not Players:GetPlayerFromCharacter(model) then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid and model:FindFirstChild("HumanoidRootPart") then
					seen[model] = true
					self:_draw(model, model, nil, camera, origin, settings, localCharacter, delta)
				end
			end
		end
	end

	-- Model entries vanish with their model; player entries stay for a respawn.
	for owner, entry in pairs(self._entries) do
		if not seen[owner] then
			entry:Destroy()
			self._entries[owner] = nil
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

function ESP:Stop()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self._npcSet)
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
