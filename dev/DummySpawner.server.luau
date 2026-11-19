--[[
	Phasma/dev/DummySpawner.server.luau

	Builds the test range: R15 rigs at fixed distances from the origin, each
	with a different health value, plus one wall so the visibility check has
	something to hide behind.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local FOLDER_NAME = "PhasmaDummies"

-- Angles are degrees off the -Z axis, the direction the default spawn faces.
local LAYOUT = {
	{ Distance = 10, Angle = -18, Health = 100 },
	{ Distance = 25, Angle = 18, Health = 80 },
	{ Distance = 50, Angle = -12, Health = 60 },
	{ Distance = 100, Angle = 12, Health = 40 },
	{ Distance = 200, Angle = -8, Health = 100 },
	{ Distance = 350, Angle = 8, Health = 75 },
	{ Distance = 500, Angle = 0, Health = 50 },
	{ Distance = 75, Angle = 180, Health = 100 },
}

local function positionFor(distance, angle)
	local radians = math.rad(angle)
	return Vector3.new(math.sin(radians) * distance, 3, -math.cos(radians) * distance)
end

local function dress(index, health)
	local hue = (index * 0.13) % 1
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = Color3.fromHSV(hue, 0.5, 0.95)
	description.TorsoColor = Color3.fromHSV(hue, 0.45, 0.8)
	description.LeftArmColor = Color3.fromHSV(hue, 0.45, 0.75)
	description.RightArmColor = Color3.fromHSV(hue, 0.45, 0.75)
	description.LeftLegColor = Color3.fromHSV(hue, 0.45, 0.7)
	description.RightLegColor = Color3.fromHSV(hue, 0.45, 0.7)
	description.HeightScale = 0.9 + (index % 5) * 0.02
	description.WidthScale = 0.92 + (index % 3) * 0.02

	local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	description:Destroy()

	local rig = model:FindFirstChildOfClass("Humanoid")
	if rig then
		rig.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		rig.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		rig.BreakJointsOnDeath = false
		rig.MaxHealth = 100
		rig.Health = health
	end

	return model
end

local function buildDummy(entry, index)
	local model = dress(index, entry.Health)
	model.Name = string.format("Dummy %03d", entry.Distance)

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	model:PivotTo(CFrame.new(positionFor(entry.Distance, entry.Angle)))

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = string.format("Dummy %dm", entry.Distance)
		-- A few dummies expose an armour pool so the secondary health bar is
		-- visible when it is enabled in the panel.
		humanoid:SetAttribute("Armor", 30 + (index % 4) * 20)
		humanoid:SetAttribute("MaxArmor", 100)
	end

	return model
end

local previous = Workspace:FindFirstChild(FOLDER_NAME)
if previous then
	previous:Destroy()
end

local folder = Instance.new("Folder")
folder.Name = FOLDER_NAME
folder.Parent = Workspace

for index, entry in ipairs(LAYOUT) do
	local model = buildDummy(entry, index)
	model.Parent = folder
end

local wall = Instance.new("Part")
wall.Name = "Cover"
wall.Anchored = true
wall.Size = Vector3.new(70, 14, 2)
wall.Position = Vector3.new(0, 7, -70)
wall.Color = Color3.fromRGB(70, 74, 86)
wall.Material = Enum.Material.Concrete
wall.Parent = folder

-- Tagged loot models for object ESP. They are Models with a single neon part
-- so the object bounding box is easy to see against the dummy boxes.
local LOOT = {
	{ Name = "Chest", Distance = 18, Angle = -34, Color = Color3.fromRGB(255, 196, 92) },
	{ Name = "Ammo", Distance = 45, Angle = 26, Color = Color3.fromRGB(132, 226, 160) },
	{ Name = "Medkit", Distance = 90, Angle = -24, Color = Color3.fromRGB(255, 128, 148) },
	{ Name = "Relic", Distance = 220, Angle = 30, Color = Color3.fromRGB(186, 152, 255) },
}

for _, entry in ipairs(LOOT) do
	local model = Instance.new("Model")
	model.Name = entry.Name

	local part = Instance.new("Part")
	part.Name = entry.Name .. "Part"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(3, 2, 2)
	part.Position = positionFor(entry.Distance, entry.Angle)
	part.Color = entry.Color
	part.Material = Enum.Material.Neon
	part.Parent = model

	model.PrimaryPart = part
	model.Parent = folder
	CollectionService:AddTag(model, "PhasmaLoot")
end

print(("[Phasma] %d dummies and %d loot models spawned at 10-500 studs."):format(#LAYOUT, #LOOT))
