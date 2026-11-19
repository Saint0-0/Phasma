--[[
	Phasma/example/Phasma_Test.client.luau

	Showcase configuration. Copy this file and adjust the settings for your
	own place. The library is loaded from ReplicatedStorage.Phasma.Init when
	it is present, with a fallback to the latest release.
	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RELEASE_URL = "https://github.com/Saint0-0/Phasma/releases/latest/download/Phasma.luau"
local LOAD_TIMEOUT = 5

-- Waits for the place copy of the library within a single time budget. The
-- caller falls back to the release bundle when the module is not present.
local function loadFromPlace(timeout)
	local deadline = os.clock() + timeout
	local folder = ReplicatedStorage:FindFirstChild("Phasma")
	if not folder then
		folder = ReplicatedStorage:WaitForChild("Phasma", timeout)
	end
	if not folder then
		return nil
	end

	local remaining = deadline - os.clock()
	if remaining <= 0 then
		return nil
	end

	local init = folder:FindFirstChild("Init") or folder:WaitForChild("Init", remaining)
	if not init then
		return nil
	end

	local ok, result = pcall(require, init)
	if ok then
		return result
	end
	return nil
end

-- game:HttpGet is supplied by executors and is not part of the Roblox API.
-- selene: allow(incorrect_standard_library_use)
local function loadFromRelease()
	if not game.HttpGet then
		error("[Phasma] ReplicatedStorage.Phasma.Init is missing and game:HttpGet is unavailable")
	end
	local source = game:HttpGet(RELEASE_URL)
	local chunk = loadstring(source)
	if not chunk then
		error("[Phasma] the release bundle could not be compiled")
	end
	return chunk()
end

local Phasma = loadFromPlace(LOAD_TIMEOUT) or loadFromRelease()

local esp = Phasma:CreateESP({
	MaxDistance = 1200,
	TeamCheck = false,
	VisibilityCheck = false,
	IncludeNPCs = true, -- also draw humanoid models that are not player characters

	-- Target transitions: fade, box pop, chip slide, corner sweep, tracer
	-- draw-on and arrow slide. Every channel has its own switch; element
	-- toggles stay instant.
	Animations = {
		Enabled = true,
		Speed = 1,
		Fade = true,
		Pop = true,
		Slide = true,
		Sweep = true,
		Tracer = true,
		Arrow = true,
	},

	-- Far targets get a cheaper element set and rebuild less often.
	LOD = {
		Enabled = true,
		DetailDistance = 600,
		Skeleton = false,
		Chips = false,
		Tracer = false,
		UpdateInterval = 0.05,
	},

	-- Tagged models are boxed in Objects.Color.
	Objects = {
		Enabled = true,
		MaxDistance = 800,
		Tags = { "Loot", "Chest" },
		Classes = { "Model" },
		Color = Color3.fromRGB(255, 206, 132),
		-- Off-screen objects keep the edge arrow by default.
		ShowArrow = true,
	},

	Box = {
		Enabled = true,
		Color = Color3.fromRGB(170, 205, 255),
		Thickness = 1,
		Transparency = 0.05,
	},
	Name = {
		Enabled = true,
		UseDisplayName = true,
	},
	Distance = {
		Enabled = true,
	},
	Health = {
		Enabled = true,
		ShowText = true,
		Percent = true,
		Style = "Vertical",
		TextSide = "Left",
	},
	Tracer = {
		Enabled = true,
		-- Bottom, Top, Left, Right, Center or Mouse.
		From = "Bottom",
	},
	Skeleton = {
		Enabled = true,
	},
	HeadDot = {
		Enabled = true,
	},
	Direction = {
		Enabled = true,
	},
	Highlight = {
		Enabled = true,
		Preset = "Solid",
		UseTeamColor = true,
	},
	Arrow = {
		Enabled = true,
		Label = true,
	},
})

-- Named looks: "Default", "Minimal", "Clean", "Sniper", "Rage", "Chams",
-- "Performance". Applying one only touches the appearance blocks.
-- esp:ApplyPreset("Clean")

print(("[Phasma] v%s running on the %s backend."):format(Phasma.Version, esp.Canvas.Kind))
print(("[Phasma] presets: %s"):format(table.concat(esp:ListPresets(), ", ")))
