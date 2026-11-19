# Phasma

Phasma is an ESP library for Roblox executors. It draws boxes, names, distances, health bars, tracers, skeletons and highlights over players, and it runs on the Drawing API when the executor has one, falling back to a ScreenGui overlay everywhere else.

The library is modular: each element is its own module, the rendering backend is interchangeable, and the test place ships with dummies at 10 to 500 studs so you can see every element at once.

## Status

Early. `v0.1.0` covers the render loop, the two backends and eight elements. The roadmap lives in `plan.md`.

## Load it

Executors, single file:

```lua
local Phasma = loadstring(game:HttpGet("https://github.com/Saint0-0/Phasma/releases/latest/download/Phasma.luau"))()
```

In the test place, or from the `.rbxm` model dropped into `ReplicatedStorage`:

```lua
local Phasma = require(game:GetService("ReplicatedStorage").Phasma.Init)
```

## Quick start

```lua
local Phasma = require(game:GetService("ReplicatedStorage").Phasma.Init)

local esp = Phasma:CreateESP({
	MaxDistance = 1000,
	TeamCheck = false,
	VisibilityCheck = false,

	Box = { Enabled = true, Color = Color3.fromRGB(170, 205, 255) },
	Name = { Enabled = true },
	Distance = { Enabled = true },
	Health = { Enabled = true },
	Tracer = { Enabled = true, From = "Bottom" },
	Skeleton = { Enabled = true },
	HeadDot = { Enabled = true },
	Highlight = { Enabled = false },
})
```

`CreateESP` starts the render loop immediately. Everything under `Phasma.Defaults` is optional; the table you pass is merged over it, so `{ Box = { Color = ... } }` keeps the rest of the box defaults.

## The object

| Method | Description |
| --- | --- |
| `esp:SetEnabled(on)` | Shows or hides every element. |
| `esp:Toggle()` | Flips the state and returns the new one. |
| `esp:SetMaxDistance(studs)` | Changes the cutoff. |
| `esp:Stop()` | Disconnects the render loop and hides the overlay. |
| `esp:Destroy()` | Stops, destroys the elements and removes the overlay. |
| `esp.Settings` | The live settings table; edit values in place. |

Element `Enabled` flags and colours are read every frame, so toggling `esp.Settings.Skeleton.Enabled` takes effect immediately.

## Settings

Global:

| Key | Default | Description |
| --- | --- | --- |
| `Enabled` | `true` | Master switch. |
| `MaxDistance` | `1000` | Targets past this many studs are skipped. |
| `TeamCheck` | `false` | Skips players on the local player's team. |
| `VisibilityCheck` | `false` | Raycasts to the head and hides occluded targets. |
| `IgnoreLocal` | `true` | Keeps the local player out of the list. |
| `IncludeNPCs` | `false` | Also draws humanoid models that are not player characters. |

Elements: `Box`, `Name`, `Distance`, `Health`, `Tracer`, `Skeleton`, `HeadDot`, `Highlight`.

| Element | Keys |
| --- | --- |
| `Box` | `Enabled`, `Color`, `Thickness`, `Transparency`, `Filled` |
| `Name` | `Enabled`, `Color`, `TextSize`, `Transparency`, `Outline`, `UseDisplayName`, `Offset` |
| `Distance` | `Enabled`, `Color`, `TextSize`, `Transparency`, `Outline`, `Offset`, `Suffix`, `Scale` |
| `Health` | `Enabled`, `Width`, `Gap`, `Transparency`, `Background`, `BackgroundTransparency`, `ShowText`, `TextSize` |
| `Tracer` | `Enabled`, `Color`, `Thickness`, `Transparency`, `From` (`"Bottom"`, `"Center"`, `"Mouse"`) |
| `Skeleton` | `Enabled`, `Color`, `Thickness`, `Transparency` |
| `HeadDot` | `Enabled`, `Color`, `Radius`, `Filled`, `Transparency` |
| `Highlight` | `Enabled`, `Fill`, `Outline`, `FillTransparency`, `OutlineTransparency`, `DepthMode` (`"AlwaysOnTop"`, `"Occluded"`) |

`Distance.Scale` converts studs into the displayed unit; `Suffix` defaults to `"m"` because that is what the scene expects, not because the math converts anything.

## Backends

`Phasma.Canvas.new()` returns the backend:

- **Drawing** when the executor exposes `Drawing.new`, which is the fast path and the one to prefer.
- **Gui** otherwise, a `ScreenGui` of Frames, TextLabels and UIStrokes. This is what runs in Studio.

Both expose the same object surface (`Line`, `Rect`, `Text`, `Circle`), so element modules never branch on the backend.

## The test place

`Phasma.rbxl` opens with:

- A baseplate and a spawn at the origin.
- Eight R15 dummies at 10, 25, 50, 100, 200, 350 and 500 studs, plus one behind spawn, each with a different health value.
- A cover wall at 70 studs so `VisibilityCheck` has something to hide behind.
- The demo script in `StarterPlayerScripts`, with `IncludeNPCs = true` because the dummies are models rather than players.

Controls: **RightShift** toggles the ESP, **RightControl** toggles the visibility check. The output prints which backend was picked.

Rebuild the place with:

```powershell
tools\rojo.exe build default.project.json -o Phasma.rbxl
```

## Development

Tools live in `tools/` and are gitignored: Rojo 7.7, Selene 0.31, StyLua 2.5, Lune 0.10, darklua 0.19.

```powershell
# format and lint
tools\stylua.exe src
tools\selene.exe src
tools\selene.exe example
tools\selene.exe dev

# bundle dist/Phasma.luau + dist/Phasma.rbxm
tools\lune.exe run build\init.luau 0.1.0

# live loop: rebuild the bundle on save, and serve the place
tools\darklua.exe process src/Init.luau dist/Phasma.luau -c build/darklua.json -w
tools\rojo.exe serve default.project.json
```

The place reads `dist/Phasma.luau`, so the bundle has to exist before `rojo serve` or `rojo build`. That is deliberate: the source uses darklua path requires (`require("./Core/ESP")`), which Roblox cannot resolve on its own, and the bundle is what both the place and the release ship.

## Structure

```
src/
  Init.luau              entry point, CreateESP
  Constants.luau         version, overlay identity, palette
  Defaults.luau          every default setting
  Core/
    ESP.luau             render loop, entries, settings
    Entry.luau           one player's element set, rebuilt per character
    Target.luau          bounding box, bones, distance, health, visibility
    Camera.luau          projection helpers
    Config.luau          deep merge over Defaults
    Canvas.luau          backend selection
    Canvas/
      DrawingCanvas.luau Drawing-API backend
      GuiCanvas.luau     ScreenGui backend
  Modules/
    Box.luau  Name.luau  Distance.luau  Health.luau
    Tracer.luau  Skeleton.luau  HeadDot.luau  Highlight.luau
  Utils/
    Math.luau  Color.luau
example/Phasma_Test.client.luau
dev/DummySpawner.server.luau
build/                   darklua config, header, model project, build script
```

## License

MPL-2.0 - see [LICENSE](LICENSE) or <https://mozilla.org/MPL/2.0/>.

Copyright (c) 2026 Saint0-0
