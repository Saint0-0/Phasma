--[[
	Phasma/Core/Target.luau

	Resolves one target into everything the elements draw for a frame: the
	oriented bounding box in screen space, skeleton segments, distance and
	health. Results are written into a reusable state table owned by the entry,
	so a frame allocates no per-target tables.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local Camera = require("./Camera")

local Target = {}

local MAX_BONES = 16
local MAX_POINTS = 20

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
	{ "Neck", "LeftShoulder" },
	{ "LeftShoulder", "LeftElbow" },
	{ "LeftElbow", "LeftWrist" },
	{ "Neck", "RightShoulder" },
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

-- Fallback for rigs whose joints are missing or named differently: part
-- centres still produce a usable stick figure.
local R15_PART_SEGMENTS = {
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

local R6_PART_SEGMENTS = {
	{ "Head", "Torso" },
	{ "Torso", "Left Arm" },
	{ "Torso", "Right Arm" },
	{ "Torso", "Left Leg" },
	{ "Torso", "Right Leg" },
}

-- Joint instances never change for the lifetime of a character, so the
-- recursive lookups happen once. Weak keys let dead characters drop out.
local jointCache = setmetatable({}, { __mode = "k" })
local partCache = setmetatable({}, { __mode = "k" })

-- A reusable state table per entry. Every table is created once and filled in
-- place on each frame.
function Target.newState()
	local bones = table.create(MAX_BONES)
	for index = 1, MAX_BONES do
		bones[index] = { From = Vector2.zero, To = Vector2.zero }
	end

	return {
		Name = "",
		Player = nil,
		Character = nil,
		Humanoid = nil,
		Root = nil,
		Head = nil,
		Rig = "R6",
		Distance = 0,
		Health = 0,
		MaxHealth = 0,
		Box = { Position = Vector2.zero, Size = Vector2.zero, Center = Vector2.zero },
		Bones = bones,
		BoneCount = 0,
		Points = table.create(MAX_POINTS, Vector2.zero),
		PointCount = 0,
		PointMap = {},
		Screen = Vector2.zero,
		Alpha = 1,
		Delta = 0,
		Visible = true,
		-- Resolved once per frame; nil means "use the element colour".
		TeamColor = nil,
	}
end

local function partFor(character, name)
	local map = partCache[character]
	if not map then
		map = {}
		partCache[character] = map
	end

	local part = map[name]
	if part == nil then
		local found = character:FindFirstChild(name)
		part = found and found:IsA("BasePart") and found or false
		map[name] = part
	end
	if part == false or not part.Parent then
		return nil
	end
	return part
end

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
	local part = partFor(character, partName)
	if not part then
		return nil
	end
	local world = part.CFrame * Vector3.new(0, part.Size.Y * offsetY, 0)
	return Camera.project(camera, world)
end

local function collectPartBones(state, character, camera, pairs)
	local points = state.PointMap
	table.clear(points)

	for _, pair in ipairs(pairs) do
		for _, name in ipairs(pair) do
			if not points[name] then
				local part = partFor(character, name)
				if part then
					points[name] = Camera.project(camera, part.Position)
				end
			end
		end
	end

	local bones = state.Bones
	local count = 0
	for _, pair in ipairs(pairs) do
		local from = points[pair[1]]
		local to = points[pair[2]]
		if from and to and count < MAX_BONES then
			count = count + 1
			local bone = bones[count]
			bone.From = from
			bone.To = to
		end
	end

	return count
end

local function collectBones(state, character, camera, rig)
	local points = state.PointMap
	table.clear(points)

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
	local bones = state.Bones
	local count = 0
	for _, pair in ipairs(segments) do
		local from = points[pair[1]]
		local to = points[pair[2]]
		if from and to and count < MAX_BONES then
			count = count + 1
			local bone = bones[count]
			bone.From = from
			bone.To = to
		end
	end

	if count == 0 then
		local fallback = rig == "R15" and R15_PART_SEGMENTS or R6_PART_SEGMENTS
		count = collectPartBones(state, character, camera, fallback)
	end

	-- Unique joint positions for the optional joint dots.
	local pointCount = 0
	for _, point in pairs(points) do
		if point and pointCount < MAX_POINTS then
			pointCount = pointCount + 1
			state.Points[pointCount] = point
		end
	end

	return count, pointCount
end

-- Projects the eight corners of the character's oriented box into `box`.
local function projectBox(box, character, camera)
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
					return false
				end
				minX = minX and math.min(minX, screen.X) or screen.X
				maxX = maxX and math.max(maxX, screen.X) or screen.X
				minY = minY and math.min(minY, screen.Y) or screen.Y
				maxY = maxY and math.max(maxY, screen.Y) or screen.Y
			end
		end
	end

	if not minX then
		return false
	end

	box.Position = Vector2.new(minX, minY)
	box.Size = Vector2.new(maxX - minX, maxY - minY)
	box.Center = Vector2.new((minX + maxX) * 0.5, (minY + maxY) * 0.5)
	return true
end

-- Fills `entry.State` for this frame. Returns false when the target should not
-- be drawn at all, in which case the entry is hidden.
function Target.build(entry, name, player, camera, origin, settings)
	local character = entry.Character
	if not character or not character.Parent then
		return false
	end

	local humanoid = entry.Humanoid
	local root = entry.Root
	local head = entry.Head
	if not humanoid or not root or not head or not root.Parent or not head.Parent then
		return false
	end
	if humanoid.Health <= 0 then
		return false
	end

	-- One projection is enough to reject anything behind the camera before
	-- the bounding box does eight of them.
	if not Camera.project(camera, root.Position) then
		return false
	end

	local distance = (root.Position - origin).Magnitude
	if distance > settings.MaxDistance then
		return false
	end

	local state = entry.State
	if not projectBox(state.Box, character, camera) then
		return false
	end

	local headScreen = Camera.project(camera, head.Position)

	state.Name = name
	state.Player = player
	state.Character = character
	state.Humanoid = humanoid
	state.Root = root
	state.Head = head
	state.Rig = entry.Rig
	state.Distance = distance
	state.Health = humanoid.Health
	state.MaxHealth = humanoid.MaxHealth
	state.Screen = headScreen or state.Box.Center

	-- A team colour overrides the element colours for the box, name, tracer,
	-- skeleton and head dot. NPCs and teamless players keep the settings colour.
	if settings.TeamColor and player and player.Team then
		state.TeamColor = player.Team.TeamColor.Color
	else
		state.TeamColor = nil
	end

	if settings.Skeleton and settings.Skeleton.Enabled then
		state.BoneCount, state.PointCount = collectBones(state, character, camera, entry.Rig)
	else
		state.BoneCount = 0
		state.PointCount = 0
	end

	local alpha = 1
	if settings.FadeWithDistance and settings.MaxDistance > 0 then
		local floor = settings.FadeFloor or 0.72
		local ratio = math.clamp(distance / settings.MaxDistance, 0, 1)
		alpha = 1 + (floor - 1) * ratio
	end
	state.Alpha = alpha

	return true
end

return Target
