--[[
	Phasma/Core/Target.luau

	Resolves one player into everything the elements draw for a frame: the
	oriented bounding box in screen space, skeleton segments, distance and
	health. Returns nil when the target should not be drawn.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Camera = require("./Camera")

local Target = {}

local R15_BONES = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },
}

local R6_BONES = {
	{ "Head", "Torso" },
	{ "Torso", "Left Arm" },
	{ "Torso", "Right Arm" },
	{ "Torso", "Left Leg" },
	{ "Torso", "Right Leg" },
}

-- Every part a skeleton can touch, in one list per rig.
local R15_PARTS = {
	"Head",
	"UpperTorso",
	"LowerTorso",
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
}

local R6_PARTS = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

local function collectBones(character, camera, parts, pairs)
	local points = {}
	for _, name in ipairs(parts) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			local screen = Camera.project(camera, part.Position)
			if screen then
				points[name] = screen
			end
		end
	end

	local bones = {}
	for _, pair in ipairs(pairs) do
		local from = points[pair[1]]
		local to = points[pair[2]]
		if from and to then
			bones[#bones + 1] = { From = from, To = to }
		end
	end
	return bones
end

-- Projects the eight corners of the character's oriented box.
local function projectBox(character, camera)
	local boxCFrame, boxSize = character:GetBoundingBox()
	local half = boxSize * 0.5

	local minX, minY, maxX, maxY
	for xi = 0, 1 do
		local x = xi == 0 and -half.X or half.X
		for yi = 0, 1 do
			local y = yi == 0 and -half.Y or half.Y
			for zi = 0, 1 do
				local z = zi == 0 and -half.Z or half.Z
				local corner = boxCFrame * Vector3.new(x, y, z)
				local screen = Camera.project(camera, corner)
				if not screen then
					return nil
				end
				minX = minX and math.min(minX, screen.X) or screen.X
				maxX = maxX and math.max(maxX, screen.X) or screen.X
				minY = minY and math.min(minY, screen.Y) or screen.Y
				maxY = maxY and math.max(maxY, screen.Y) or screen.Y
			end
		end
	end

	if not minX then
		return nil
	end
	return {
		Position = Vector2.new(minX, minY),
		Size = Vector2.new(maxX - minX, maxY - minY),
		Center = Vector2.new((minX + maxX) * 0.5, (minY + maxY) * 0.5),
	}
end

local function isVisible(character, camera, head, rayParams, localCharacter)
	local origin = camera.CFrame.Position
	local filter = { character }
	if localCharacter then
		filter[2] = localCharacter
	end
	rayParams.FilterDescendantsInstances = filter
	local result = workspace:Raycast(origin, head.Position - origin, rayParams)
	return result == nil
end

function Target.build(character, name, player, camera, origin, settings, rayParams, localCharacter)
	if not character or not character.Parent then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not humanoid or not root or not head or humanoid.Health <= 0 then
		return nil
	end

	local distance = (root.Position - origin).Magnitude
	if distance > settings.MaxDistance then
		return nil
	end

	local box = projectBox(character, camera)
	if not box then
		return nil
	end

	local rig = character:FindFirstChild("UpperTorso") and "R15" or "R6"
	local bones = {}
	if settings.Skeleton and settings.Skeleton.Enabled then
		if rig == "R15" then
			bones = collectBones(character, camera, R15_PARTS, R15_BONES)
		else
			bones = collectBones(character, camera, R6_PARTS, R6_BONES)
		end
	end

	local headScreen = Camera.project(camera, head.Position)

	local visible = true
	if settings.VisibilityCheck then
		visible = isVisible(character, camera, head, rayParams, localCharacter)
	end

	return {
		Name = name,
		Player = player,
		Character = character,
		Humanoid = humanoid,
		Root = root,
		Head = head,
		Rig = rig,
		Distance = distance,
		Health = humanoid.Health,
		MaxHealth = humanoid.MaxHealth,
		Box = box,
		Bones = bones,
		Screen = headScreen or box.Center,
		Visible = visible,
	}
end

return Target
