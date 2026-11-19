local fs = require("@lune/fs")
local process = require("@lune/process")

local SrcEntry = "src/Init.luau"
local DistScript = "dist/Phasma.luau"
local DistModel = "dist/Phasma.rbxm"
local HeaderFile = "build/header.luau"
local Darklua = "tools/darklua.exe"
local DarkluaConfig = "build/darklua.json"
local Rojo = "tools/rojo.exe"
local ModelProject = "build/model.project.json"

-- The version is REQUIRED as the first argument so it can be stamped into the
-- header banner. Usage:
--   tools/lune.exe run build/init.luau 0.1.0
-- A leading "v" is optional and stripped, so both "0.1.0" and "v0.1.0" work.
local rawVersion = process.args[1]
if rawVersion == nil or rawVersion == "" then
	error("No version supplied.\nUsage: tools/lune.exe run build/init.luau <version>\nExample: tools/lune.exe run build/init.luau 0.1.0")
end
local version = tostring(rawVersion):gsub("^v", "")

-- The banner and Constants.Version must agree.
local constantsVersion = fs.readFile("src/Constants.luau"):match('Constants%.Version%s*=%s*"([^"]+)"')
if constantsVersion ~= version then
	error(
		"Version mismatch: the build argument is "
			.. version
			.. " but Constants.Version is "
			.. tostring(constantsVersion)
	)
end

local function ensureDir(path)
	if not fs.isDir(path) then
		fs.writeDir(path)
	end
end

local function run(label, cmd, args)
	local result = process.exec(cmd, args)
	if not result.ok then
		print(label .. " stdout: " .. tostring(result.stdout))
		print(label .. " stderr: " .. tostring(result.stderr))
		error(label .. " failed with exit code " .. tostring(result.code))
	end
end

local function build()
	ensureDir("dist")

	-- 1. Bundle + minify the source into a single loadstring script.
	run("darklua", Darklua, {
		"process",
		SrcEntry,
		DistScript,
		"--config",
		DarkluaConfig,
	})

	-- 2. Prepend the header banner, substituting the required version into the
	--    {{VERSION}} placeholder so the shipped file is self-describing.
	local header = fs.readFile(HeaderFile)
	header = header:gsub("{{" .. "VERSION" .. "}}", version)
	local body = fs.readFile(DistScript)
	fs.writeFile(DistScript, header .. "\n" .. body)

	-- 3. Build the Roblox model (.rbxm) from the bundled script. The model is a
	--    Folder named Phasma containing a single ModuleScript 'Init', so it can
	--    be dropped into ReplicatedStorage and required as Phasma.Init.
	run("rojo", Rojo, {
		"build",
		ModelProject,
		"-o",
		DistModel,
	})

	print("Built " .. DistScript .. " (v" .. version .. ")")
	print("Built " .. DistModel .. " (v" .. version .. ")")
end

build()
