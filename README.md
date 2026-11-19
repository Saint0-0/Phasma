# Phasma

Phasma is a modular ESP library for Roblox executors. It draws boxes, names, distances, health bars, tracers, skeletons, facing markers and highlights over players, and it can draw tagged objects such as loot or chests. The library uses the Drawing API when the executor provides one and falls back to a ScreenGui overlay on every other client.

The name comes from the Greek word *phasma*, which means apparition or phantom. The project is written in Luau and released under the Mozilla Public License 2.0.

## Features

- Ten independent elements: Box, Name, Distance, Health, Tracer, Skeleton, HeadDot, Highlight, Direction and Arrow.
- Two rendering backends behind one object surface: Drawing and ScreenGui.
- Filters by name, UserId or team, a case-insensitive name substring, a target cap and priority sorting.
- Distance-based level of detail, with throttled rebuilds for far targets.
- Object ESP for tagged or named Models and BaseParts.
- Seven named presets that change appearance without touching filters or security.
- Time-based entrance and exit animations with per-channel switches.
- Security defaults that randomise overlay names, protect the GUI and keep Highlight outside the character.
- No per-frame allocations on the render path.

## Requirements

- A Roblox executor for runtime use. The Drawing API is preferred, and the ScreenGui backend covers clients that do not expose it.
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
tools\lune.exe run build\init.luau 0.6.0
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

## Documentation

| Document | Contents |
| --- | --- |
| [API reference](docs/api.md) | Library object, module functions, presets and live settings. |
| [Configuration](docs/configuration.md) | Every setting, element key and behaviour note. |
| [Architecture](docs/architecture.md) | Render flow, backends, projection, performance and security model. |
| [Development](docs/development.md) | Tooling, build commands, release process and conventions. |
| [Changelog](CHANGELOG.md) | Version history. |
| [Contributing](CONTRIBUTING.md) | Bug reports, change proposals and code style. |

## Version

The current version is `v0.6.0`, the animation pass. It adds time-based target fades, an overshooting box pop, sliding name and distance chips, a corner-bracket sweep, a tracer that draws from its origin with a glow and a travelling spark, and an edge arrow that slides and grows in. Every animation channel has its own switch and shares one speed multiplier.

## Security notice

Phasma is a client-side library. Its security options reduce casual detection, but no client-side measure can hide from a determined anti-cheat. The Drawing backend creates no Instances, while the ScreenGui backend relies on `gethui`, `protectgui` and randomised names. Use the library in environments where client modification is permitted.

## License

Mozilla Public License 2.0. See [LICENSE](LICENSE) or <https://mozilla.org/MPL/2.0/>.

Copyright (c) 2026 Saint0-0
