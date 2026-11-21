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

-- The engine bounding box includes hats and accessories, which can double the
-- height of the box. These lists are the rig itself.
local R15_BODY = {
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

local R6_BODY = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

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
		BaseAlpha = 1,
		Delta = 0,
		Visible = true,
		Occluded = false,
		Offscreen = false,
		ArrowDirection = Vector2.zero,
		-- Facing direction in screen space, used by the Direction element.
		Facing = Vector2.zero,
		FacingValid = false,
		-- LOD flags; true keeps the element at every distance.
		Detail = true,
		ShowSkeleton = true,
		ShowChips = true,
		ShowTracer = true,
		ShowArrow = true,
		-- Injected by Entry so elements can read the transition progress.
		Anim = nil,
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

-- When the camera is inside the rig, a corner sits behind the near plane and
-- its projection flips. Fall back to a distance-scaled screen box centred on
-- `position` so the box shrinks from huge to normal instead of vanishing.
local function projectNearBox(box, camera, position, size)
	local screen = Camera.project(camera, position)
	if not screen then
		return false
	end

	local distance = (position - camera.CFrame.Position).Magnitude
	local viewport = camera.ViewportSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		return false
	end
	local pixelsPerStud = (viewport.Y * 0.5) / math.tan(math.rad(camera.FieldOfView * 0.5))
	local scale = pixelsPerStud / math.max(distance, 0.5)
	-- `math.clamp` errors when the max is below the min, which happens while
	-- the camera viewport is still settling. Keep the upper bound sane.
	local width = math.clamp(size.X * scale, 24, math.max(viewport.X * 1.5, 24))
	local height = math.clamp(size.Y * scale, 32, math.max(viewport.Y * 1.5, 32))
	-- The root sits around mid-body, so lift the box a little.
	local center = screen - Vector2.new(0, height * 0.12)

	box.Position = center - Vector2.new(width * 0.5, height * 0.5)
	box.Size = Vector2.new(width, height)
	box.Center = center
	return true
end

-- Projects the eight corners of an oriented box. Shared by humanoids and
-- objects, which only differ in how their CFrame and size are found.
local function projectCorners(box, boxCFrame, size, camera, fallbackPosition)
	local half = size * 0.5

	local minX, minY, maxX, maxY
	for xi = 0, 1 do
		local x = xi == 0 and -half.X or half.X
		for yi = 0, 1 do
			local y = yi == 0 and -half.Y or half.Y
			for zi = 0, 1 do
				local z = zi == 0 and -half.Z or half.Z
				local screen = Camera.project(camera, boxCFrame * Vector3.new(x, y, z))
				if not screen then
					return projectNearBox(box, camera, fallbackPosition, size)
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

-- Projects the eight corners of the rig's body box into `box`. The box is
-- built in root space from the body parts only, so hats and accessories do
-- not widen it.
local function projectBox(box, entry, camera)
	local character = entry.Character
	local root = entry.Root
	local names = entry.Rig == "R15" and R15_BODY or R6_BODY
	local inverse = root.CFrame:Inverse()

	local min, max
	for _, name in ipairs(names) do
		local part = partFor(character, name)
		if part then
			local half = part.Size * 0.5
			local cf = inverse * part.CFrame
			local rx, ry, rz = cf.RightVector, cf.UpVector, cf.LookVector
			local extent = Vector3.new(
				math.abs(rx.X) * half.X + math.abs(ry.X) * half.Y + math.abs(rz.X) * half.Z,
				math.abs(rx.Y) * half.X + math.abs(ry.Y) * half.Y + math.abs(rz.Y) * half.Z,
				math.abs(rx.Z) * half.X + math.abs(ry.Z) * half.Y + math.abs(rz.Z) * half.Z
			)
			local center = cf.Position
			if min then
				min = Vector3.new(
					math.min(min.X, center.X - extent.X),
					math.min(min.Y, center.Y - extent.Y),
					math.min(min.Z, center.Z - extent.Z)
				)
				max = Vector3.new(
					math.max(max.X, center.X + extent.X),
					math.max(max.Y, center.Y + extent.Y),
					math.max(max.Z, center.Z + extent.Z)
				)
			else
				min = center - extent
				max = center + extent
			end
		end
	end

	if not min then
		return false
	end

	local center = (min + max) * 0.5
	local size = max - min
	return projectCorners(box, root.CFrame * CFrame.new(center), size, camera, root.Position)
end

-- Distance fade shared by characters and objects.
local function distanceAlpha(settings, distance, maxDistance)
	local alpha = 1
	local limit = maxDistance or settings.MaxDistance
	if settings.FadeWithDistance and limit and limit > 0 then
		local floor = settings.FadeFloor or 0.72
		local ratio = math.clamp(distance / limit, 0, 1)
		alpha = 1 + (floor - 1) * ratio
	end
	return alpha
end

-- Detail flags for the current distance. `Detail` gates the expensive
-- elements; each LOD key can opt back in at range.
local function applyLOD(state, settings, distance)
	local lod = settings.LOD
	if not lod or not lod.Enabled then
		state.Detail = true
		state.ShowSkeleton = true
		state.ShowChips = true
		state.ShowTracer = true
		return
	end

	local detail = distance <= (lod.DetailDistance or 600)
	state.Detail = detail
	state.ShowSkeleton = detail or lod.Skeleton == true
	state.ShowChips = detail or lod.Chips == true
	state.ShowTracer = detail or lod.Tracer == true
end

-- Decides whether the target is inside the viewport and, when it is not,
-- stores the direction the edge arrow should point.
local function resolveScreen(state, camera, position, positionScreen, boxOk)
	local viewport = camera.ViewportSize
	local centre = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
	local onScreen
	if boxOk then
		local box = state.Box
		onScreen = box.Position.X <= viewport.X
			and box.Position.X + box.Size.X >= 0
			and box.Position.Y <= viewport.Y
			and box.Position.Y + box.Size.Y >= 0
	elseif positionScreen then
		onScreen = positionScreen.X >= 0
			and positionScreen.X <= viewport.X
			and positionScreen.Y >= 0
			and positionScreen.Y <= viewport.Y
	else
		onScreen = false
	end

	state.Offscreen = not onScreen
	if not state.Offscreen then
		return
	end

	if positionScreen then
		local delta = positionScreen - centre
		if delta.Magnitude < 1 then
			state.ArrowDirection = Vector2.new(0, 1)
		else
			state.ArrowDirection = delta.Unit
		end
	else
		-- Behind the camera: bias the arrow to the side that needs turning.
		local localPos = camera.CFrame:PointToObjectSpace(position)
		if math.abs(localPos.X) < 0.5 then
			state.ArrowDirection = Vector2.new(0, 1)
		else
			state.ArrowDirection = Vector2.new(localPos.X * 0.35, 1).Unit
		end
	end
end

-- Projects the facing vector into screen space. A target looking straight at
-- the camera has almost no screen-space direction, so the marker hides.
local function resolveFacing(state, camera, cframe, cframeScreen)
	state.FacingValid = false
	if not cframeScreen then
		return
	end

	local front = Camera.project(camera, cframe.Position + cframe.LookVector * 3)
	if not front then
		return
	end

	local delta = front - cframeScreen
	if delta.Magnitude < 0.5 then
		return
	end

	state.Facing = delta.Unit
	state.FacingValid = true
end

-- Fills `entry.State` for this frame. Returns false when the target should not
-- be drawn at all, in which case the entry is hidden. `focused` bypasses the
-- distance cutoff and level of detail, because a chosen target is the only one
-- on screen and should stay complete at any range.
function Target.build(entry, name, player, camera, origin, settings, focused)
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

	local distance = (root.Position - origin).Magnitude
	if not focused and distance > settings.MaxDistance then
		return false
	end

	local state = entry.State
	local rootScreen = Camera.project(camera, root.Position)
	local boxOk = rootScreen ~= nil and projectBox(state.Box, entry, camera)

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
	state.Screen = headScreen or rootScreen or Vector2.zero
	state.BaseAlpha = distanceAlpha(settings, distance)
	state.Alpha = state.BaseAlpha
	-- Humanoids always get the off-screen arrow; objects can opt out in
	-- Target.buildObject through Objects.ShowArrow.
	state.ShowArrow = true

	-- A team colour overrides the element colours for the box, name, tracer,
	-- skeleton and head dot. NPCs and teamless players keep the settings colour.
	if settings.TeamColor and player and player.Team then
		state.TeamColor = player.Team.TeamColor.Color
	else
		state.TeamColor = nil
	end

	if focused then
		state.Detail = true
		state.ShowSkeleton = true
		state.ShowChips = true
		state.ShowTracer = true
	else
		applyLOD(state, settings, distance)
	end
	resolveScreen(state, camera, root.Position, rootScreen, boxOk)
	resolveFacing(state, camera, head.CFrame, headScreen)

	if not state.Offscreen and state.ShowSkeleton and settings.Skeleton and settings.Skeleton.Enabled then
		state.BoneCount, state.PointCount = collectBones(state, character, camera, entry.Rig)
	else
		state.BoneCount = 0
		state.PointCount = 0
	end

	return true
end

-- Fills the state for a non-humanoid Model or BasePart. Objects share the
-- Box, Name, Distance and Arrow elements but never get a skeleton or health.
-- `focused` bypasses the object distance cutoff and forces the edge arrow, so
-- a chosen target stays reachable when it leaves the viewport.
function Target.buildObject(entry, name, object, camera, origin, settings, focused)
	if not object or not object.Parent then
		return false
	end

	local boxCFrame, boxSize
	if object:IsA("BasePart") then
		boxCFrame = object.CFrame
		boxSize = object.Size
	elseif object:IsA("Model") then
		boxCFrame, boxSize = object:GetBoundingBox()
	else
		return false
	end

	local objectSettings = settings.Objects
	local maxDistance = objectSettings and objectSettings.MaxDistance or settings.MaxDistance
	local distance = (boxCFrame.Position - origin).Magnitude
	if not focused and distance > maxDistance then
		return false
	end

	local state = entry.State
	local screen = Camera.project(camera, boxCFrame.Position)
	local boxOk = screen ~= nil and projectCorners(state.Box, boxCFrame, boxSize, camera, boxCFrame.Position)

	state.Name = name
	state.Player = nil
	state.Character = object
	state.Humanoid = nil
	state.Root = object
	state.Head = nil
	state.Rig = "Object"
	state.Distance = distance
	state.Health = 0
	state.MaxHealth = 0
	state.Screen = boxOk and state.Box.Center or screen or Vector2.zero
	state.TeamColor = objectSettings and objectSettings.Color or nil
	state.BaseAlpha = distanceAlpha(settings, distance, maxDistance)
	state.Alpha = state.BaseAlpha
	state.ShowArrow = focused or objectSettings == nil or objectSettings.ShowArrow ~= false
	state.Detail = true
	state.ShowSkeleton = false
	state.ShowChips = true
	state.ShowTracer = false
	state.BoneCount = 0
	state.PointCount = 0

	resolveScreen(state, camera, boxCFrame.Position, screen, boxOk)
	resolveFacing(state, camera, boxCFrame, screen)
	return true
end

return Target
