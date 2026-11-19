--[[
	Phasma/Core/ESP.luau

	Owns the render loop, the target entries and the shared settings. Every
	frame resolves each target once and hands the result to that target's
	elements. Players and, optionally, humanoid NPCs are both supported.
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

-- NPC models are rescanned this often; a full descendant walk every frame is
-- too expensive on real maps.
local NPC_RESCAN = 0.5

local ESP = {}
ESP.__index = ESP

function ESP.new(settings)
	local self = setmetatable({}, ESP)
	self.Settings = Config.resolve(settings)
	self.Canvas = Canvas.new()
	self._entries = {}
	self._connections = {}
	self._running = false
	self._npcList = nil
	self._npcScan = 0

	self._rayParams = RaycastParams.new()
	self._rayParams.FilterType = Enum.RaycastFilterType.Exclude
	self._rayParams.IgnoreWater = true
	self._rayParams.FilterDescendantsInstances = {}

	return self
end

function ESP:Start()
	if self._running then
		return
	end
	self._running = true

	self._connections[#self._connections + 1] = RunService.RenderStepped:Connect(function()
		self:Render()
	end)

	self._connections[#self._connections + 1] = Players.PlayerRemoving:Connect(function(player)
		self:_drop(player)
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

function ESP:_npcs()
	local now = os.clock()
	if self._npcList and now - self._npcScan < NPC_RESCAN then
		return self._npcList
	end

	local list = {}
	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
			list[#list + 1] = instance
		end
	end

	self._npcList = list
	self._npcScan = now
	return list
end

function ESP:_draw(owner, character, player, camera, origin, settings, localCharacter)
	local entry = self._entries[owner]
	if entry and entry.Character ~= character then
		entry:Destroy()
		entry = nil
	end
	if not entry then
		entry = Entry.new(self, owner, character)
		self._entries[owner] = entry
	end

	local name = player and player.Name or character.Name
	local state = Target.build(character, name, player, camera, origin, settings, self._rayParams, localCharacter)
	if state and state.Visible then
		entry:Draw(state)
	else
		entry:Hide()
	end
end

function ESP:Render()
	local settings = self.Settings
	if not settings.Enabled then
		self:_hideAll()
		return
	end

	local camera = Camera.get()
	local localPlayer = Players.LocalPlayer
	if not camera or not localPlayer then
		return
	end

	local localCharacter = localPlayer.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	local origin = localRoot and localRoot.Position or camera.CFrame.Position
	local localTeam = localPlayer.Team

	local seen = {}
	local characters = {}

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
			self:_draw(player, character, player, camera, origin, settings, localCharacter)
		end
	end

	if settings.IncludeNPCs then
		for _, model in ipairs(self:_npcs()) do
			if
				not characters[model]
				and model ~= localCharacter
				and model.Parent
				and not Players:GetPlayerFromCharacter(model)
			then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid and model:FindFirstChild("HumanoidRootPart") then
					seen[model] = true
					self:_draw(model, model, nil, camera, origin, settings, localCharacter)
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
