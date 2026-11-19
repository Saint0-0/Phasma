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

-- Skeleton points come from Motor6D joints, not part centres: a joint sits
-- where the limb actually pivots, so the sticks meet at the shoulders, elbows,
-- hips and knees instead of floating inside each part.
local R15_JOINTS = {
	"Neck",
	"Waist",
	"LeftShoulder",
	"LeftElbow",
	"LeftWrist",
	"RightShoulder",
	"RightElbow",
	"RightWrist",
	"LeftHip",
	"LeftKnee",
	"LeftAnkle",
	"RightHip",
	"RightKnee",
	"RightAnkle",
}

local R15_SEGMENTS = {
	{ "Neck", "Waist" },
	{ "Neck", "HeadTop" },
	{ "Waist", "LeftShoulder" },
	{ "LeftShoulder", "LeftElbow" },
	{ "LeftElbow", "LeftWrist" },
	{ "Waist", "RightShoulder" },
	{ "RightShoulder", "RightElbow" },
	{ "RightElbow", "RightWrist" },
	{ "Waist", "LeftHip" },
	{ "LeftHip", "LeftKnee" },
	{ "LeftKnee", "LeftAnkle" },
	{ "Waist", "RightHip" },
	{ "RightHip", "RightKnee" },
	{ "RightKnee", "RightAnkle" },
}

-- R6 has one part per limb, so the hands and feet are part ends rather than
-- joints.
local R6_JOINTS = { "Neck", "RootJoint", "Left Shoulder", "Right Shoulder", "Left Hip", "Right Hip" }

local R6_ENDS = {
	{ Name = "LeftHand", Part = "Left Arm" },
	{ Name = "RightHand", Part = "Right Arm" },
	{ Name = "LeftFoot", Part = "Left Leg" },
	{ Name = "RightFoot", Part = "Right Leg" },
}

local R6_SEGMENTS = {
	{ "Neck", "RootJoint" },
	{ "Neck", "HeadTop" },
	{ "Neck", "Left Shoulder" },
	{ "Neck", "Right Shoulder" },
	{ "Left Shoulder", "LeftHand" },
	{ "Right Shoulder", "RightHand" },
	{ "RootJoint", "Left Hip" },
	{ "RootJoint", "Right Hip" },
	{ "Left Hip", "LeftFoot" },
	{ "Right Hip", "RightFoot" },
}

-- Joint instances never change for the lifetime of a character, so the
-- recursive lookups happen once. Weak keys let dead characters drop out.
local jointCache = setmetatable({}, { __mode = "k" })

local function jointsFor(character, names)
	local map = jointCache[character]
	if not map then
		map = {}
		jointCache[character] = map
	end

	for _, name in ipairs(names) do
		local joint = map[name]
		if not joint or not joint.Parent or not joint.Part0 then
			joint = character:FindFirstChild(name, true)
			if joint and joint:IsA("Motor6D") then
				map[name] = joint
			else
				map[name] = nil
			end
		end
	end

	return map
end

-- World position of a joint: the Motor6D sits at Part0.CFrame * C0.
local function projectJoint(camera, joint)
	local part = joint.Part0
	if not part then
		return nil
	end
	return Camera.project(camera, (part.CFrame * joint.C0).Position)
end

local function projectPartPoint(camera, character, partName, offsetY)
	local part = character:FindFirstChild(partName)
	if not part or not part:IsA("BasePart") then
		return nil
	end
	local world = part.CFrame * Vector3.new(0, part.Size.Y * offsetY, 0)
	return Camera.project(camera, world)
end

local function collectBones(character, camera, rig)
	local points = {}

	if rig == "R15" then
		for name, joint in pairs(jointsFor(character, R15_JOINTS)) do
			points[name] = projectJoint(camera, joint)
		end
	else
		for name, joint in pairs(jointsFor(character, R6_JOINTS)) do
			points[name] = projectJoint(camera, joint)
		end
		for _, spec in ipairs(R6_ENDS) do
			points[spec.Name] = projectPartPoint(camera, character, spec.Part, -0.5)
		end
	end

	points.HeadTop = projectPartPoint(camera, character, "Head", 0.5)

	local segments = rig == "R15" and R15_SEGMENTS or R6_SEGMENTS
	local bones = {}
	for _, pair in ipairs(segments) do
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
		bones = collectBones(character, camera, rig)
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
