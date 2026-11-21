# Phasma

Phasma is a modular ESP library for Roblox executors. It draws boxes, names, distances, health bars, tracers, skeletons, facing markers and highlights over players, and it can draw tagged objects such as loot or chests. Rendering uses a ScreenGui overlay, the same path that is verified in Studio, so every box style and element looks identical on an executor.

The name comes from the Greek word *phasma*, which means apparition or phantom. The project is written in Luau and released under the Mozilla Public License 2.0.

## Features

- Ten independent elements: Box, Name, Distance, Health, Tracer, Skeleton, HeadDot, Highlight, Direction and Arrow.
- One ScreenGui rendering path, verified in Studio and used unchanged on executors.
- Filters by name, UserId or team, a case-insensitive name substring, a target cap and priority sorting.
- Distance-based level of detail, with throttled rebuilds for far targets.
- Object ESP for tagged or named Models and BaseParts.
- Single-target focus through `esp:SetTarget`, which draws one Player, Model, Humanoid or BasePart and ignores every other candidate.
- Seven named presets that change appearance without touching filters or security.
- Time-based entrance and exit animations with per-channel switches.
- Security defaults that randomise overlay names, protect the GUI and keep Highlight outside the character.
- No per-frame allocations on the render path.

## Requirements

- A Roblox executor for runtime use. Rendering uses a ScreenGui overlay, which works on every client and matches Studio.
- Roblox Studio, Rojo, Selene, StyLua, Lune and darklua for development from source. The versions used by this project are listed in [docs/development.md](docs/development.md).

## Installation

### Executors and Studio

The loader below first looks for `ReplicatedStorage.Phasma.Init`. It waits up to five seconds for the folder and the module, which covers the test place and Studio, and then falls back to the latest release bundle when the module is not present. The timeout prevents a client without the module from waiting indefinitely.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RELEASE_URL = "https://github.com/Saint0-0/Phasma/releases/latest/download/Phasma.luau"
local LOAD_TIMEOUT = 5

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
```

### Model

Download `Phasma.rbxm` from the latest release, place the `Phasma` folder in `ReplicatedStorage`, and require `Phasma.Init`.

```lua
local Phasma = require(game:GetService("ReplicatedStorage").Phasma.Init)
```

### Rojo

The repository ships a `default.project.json` that maps the built module and a demonstration script. Build the module first, then serve the project.

```powershell
tools\lune.exe run build\init.luau 0.7.1
tools\rojo.exe serve default.project.json
```

## Quick start

With `Phasma` loaded as shown above:

```lua
local esp = Phasma:CreateESP({
	MaxDistance = 1000,
	TeamCheck = false,
	VisibilityCheck = false,

	Box = { Enabled = true, Style = "Corners", Filled = true },
	Name = { Enabled = true },
	Distance = { Enabled = true },
	Health = { Enabled = true, Style = "Vertical" },
	Tracer = { Enabled = true, From = "Bottom" },
	Skeleton = { Enabled = true },
	HeadDot = { Enabled = true },
	Direction = { Enabled = true },
	Highlight = { Enabled = true, Preset = "Solid" },
	Arrow = { Enabled = true, Label = true },

	Security = { Enabled = true },
})

esp:ApplyPreset("Clean")
```

`CreateESP` starts the render loop immediately. Every key is optional, and the table that is passed is merged over the defaults. A partial table such as `{ Box = { Color = Color3.new(1, 0, 0) } }` keeps the remaining box settings.

## Focus a single target

`esp:SetTarget(instance)` limits the ESP to one target. This is useful for autofarm and pathing scripts, where the only thing worth drawing is the destination the character is moving to. Pass a `Player`, `Model`, `Humanoid` or `BasePart`, then call `SetTarget` again when the destination changes.

```lua
local esp = Phasma:CreateESP({
	MaxDistance = 1000,
	Box = { Enabled = true },
	Name = { Enabled = true },
	Distance = { Enabled = true },
})

-- Track a player. The entry follows the character through a respawn.
esp:SetTarget(game:GetService("Players").SomePlayer)

-- Track an NPC or a loot model.
esp:SetTarget(workspace:WaitForChild("Bandit"))
esp:SetTarget(workspace:WaitForChild("Chest"))

-- Track one part, for example a quest marker.
esp:SetTarget(workspace:WaitForChild("Marker"))

-- Change the destination at runtime.
esp:SetTarget(workspace:WaitForChild("NextChest"))

-- Return to the normal target list.
esp:ClearTarget()
```

While focus is active, filters, `MaxDistance`, `Objects.MaxDistance`, `IncludeNPCs`, `Objects.Enabled`, `IgnoreLocal` and the visibility check do not apply to the focused instance. Humanoid targets keep the full element set, including the skeleton and chips, at any distance. Object targets keep Box, Name, Distance and Arrow, and the edge arrow is forced on so a focused object remains reachable off screen. Other targets fade out through the normal animation path. Focus is also available as `esp.Settings.Focus.Target`, and `esp:GetTarget()` returns the current value.

`SetTarget` returns `false` when the value is not a Player, Model, Humanoid or BasePart, and leaves the current target unchanged. Passing `nil` clears the target. If the instance is destroyed, the ESP draws nothing until a new target is set.

## Documentation

| Document | Contents |
| --- | --- |
| [API reference](docs/api.md) | Library object, module functions, presets and live settings. |
| [Configuration](docs/configuration.md) | Every setting, element key and behaviour note. |
| [Architecture](docs/architecture.md) | Render flow, canvas, projection, performance and security model. |
| [Development](docs/development.md) | Tooling, build commands, release process and conventions. |
| [Changelog](CHANGELOG.md) | Version history. |
| [Contributing](CONTRIBUTING.md) | Bug reports, change proposals and code style. |

## Version

The current version is `v0.7.1`, the renderer alignment patch. It removes the executor Drawing path so every client uses the ScreenGui renderer that is verified in Studio, which restores the box styles and keeps the element output identical across Studio and executors. The focus pass from `v0.7.0` is unchanged.

## Security notice

Phasma is a client-side library. Its security options reduce casual detection, but no client-side measure can hide from a determined anti-cheat. The overlay is a ScreenGui that relies on `gethui`, `protectgui` and randomised names. Use the library in environments where client modification is permitted.

## License

Mozilla Public License 2.0. See [LICENSE](LICENSE) or <https://mozilla.org/MPL/2.0/>.

Copyright (c) 2026 Saint0-0
