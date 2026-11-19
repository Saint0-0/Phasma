# Phasma

Phasma is an ESP library for Roblox executors. It draws boxes, names, distances, health bars, tracers, skeletons and highlights over players, and it can box tagged objects such as loot or chests. It runs on the Drawing API when the executor has one, falling back to a ScreenGui overlay everywhere else.

The library is modular: each element is its own module, the rendering backend is interchangeable, and the test place ships with dummies at 10 to 500 studs so you can see every element at once.

## Status

`v0.5.0` is the motion and scale pass: target fade/pop/slide transitions, tracer draw-on and arrow slide, filters with `MaxTargets` and priority, distance-based LOD throttling, facing chevrons, horizontal and secondary health bars, tagged object ESP, Highlight chams presets and named presets. The roadmap lives in `plan.md`.

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

-- Named looks: "Default", "Minimal", "Clean", "Sniper", "Rage", "Chams",
-- "Performance".
esp:ApplyPreset("Clean")
```

`CreateESP` starts the render loop immediately. Everything under `Phasma.Defaults` is optional; the table you pass is merged over it, so `{ Box = { Color = ... } }` keeps the rest of the box defaults.

## The object

| Method | Description |
| --- | --- |
| `esp:SetEnabled(on)` | Shows or hides every element. |
| `esp:Toggle()` | Flips the state and returns the new one. |
| `esp:SetMaxDistance(studs)` | Changes the cutoff. |
| `esp:ApplyPreset(name)` | Applies a named look and returns `true`, or `false` for an unknown name. |
| `esp:ListPresets()` | Returns the preset names, sorted. |
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
| `VisibilityCheck` | `false` | Raycasts to the head and tints occluded targets. |
| `VisibilityInterval` | `0.12` | Seconds between visibility raycasts for one target. |
| `ShowOccluded` | `true` | Keeps occluded targets on screen with the shared occlusion tint. `false` hides them. |
| `OccludedColor` | `#848C9C` | Colour used for every occluded element. |
| `OccludedTransparency` | `0.45` | Added to an occluded element's transparency. |
| `IgnoreLocal` | `true` | Keeps the local player out of the list. |
| `IncludeNPCs` | `false` | Also draws humanoid models that are not player characters. |
| `TeamColor` | `true` | Players with a `Team` use its colour for the box, name, tracer, skeleton and head dot. |
| `FadeWithDistance` | `true` | Far targets dim toward `FadeFloor` instead of staying at full brightness. |
| `FadeFloor` | `0.72` | Alpha at `MaxDistance`; `1` disables the effect. |

Animations:

| Key | Default | Description |
| --- | --- | --- |
| `Animations.Enabled` | `true` | Master switch for target transitions. Element toggles stay instant either way. |
| `Animations.Speed` | `12` | Convergence rate; higher settles faster, `0` snaps. |
| `Animations.Slide` | `8` | Pixels the name and distance slide while fading in. |
| `Animations.Pop` | `0.06` | Fraction the box shrinks by at the start of a fade-in. |
| `Animations.Tracer` | `true` | Grows the tracer from its origin to the target. |
| `Animations.Arrow` | `true` | Slides edge arrows in from outside the viewport. |

Filters and level of detail:

| Key | Default | Description |
| --- | --- | --- |
| `Filters.Enabled` | `false` | Enables the whitelist, blacklist, name filter and cap below. |
| `Filters.Whitelist` | `{}` | Only these names, UserIds or team names draw. An empty list allows everyone. |
| `Filters.Blacklist` | `{}` | Names, UserIds or team names that never draw. |
| `Filters.NameContains` | `""` | Case-insensitive substring of the display name. |
| `Filters.MaxTargets` | `0` | Maximum drawn targets; `0` keeps every match. |
| `Filters.Priority` | `"Distance"` | Sort key for the cap: `"Distance"`, `"Health"` (lowest first) or `"Name"`. |
| `LOD.Enabled` | `true` | Beyond `DetailDistance`, expensive elements are skipped and rebuilds are throttled. |
| `LOD.DetailDistance` | `600` | Studs before LOD applies. |
| `LOD.Skeleton` | `false` | Keep skeletons beyond `DetailDistance`. |
| `LOD.Chips` | `false` | Keep name and distance chips beyond `DetailDistance`. |
| `LOD.Tracer` | `false` | Keep tracers beyond `DetailDistance`. |
| `LOD.UpdateInterval` | `0.05` | Seconds between far-target rebuilds. |

Object ESP:

| Key | Default | Description |
| --- | --- | --- |
| `Objects.Enabled` | `false` | Draws matching `Model` and `BasePart` instances with Box, Name, Distance and Arrow. |
| `Objects.MaxDistance` | `1000` | Object cutoff, independent of `MaxDistance`. |
| `Objects.ScanInterval` | `0.5` | Seconds between registry scans. |
| `Objects.Names` | `{}` | Instance names to match. A name scan only runs when no tags are set. |
| `Objects.Classes` | `{ "Model" }` | `ClassName` allow-list; a match must satisfy one entry. |
| `Objects.Tags` | `{}` | CollectionService tags to match. Tags take precedence over names. |
| `Objects.Color` | muted grey | Box and name colour for objects. |
| `Objects.ShowArrow` | `true` | Draws the edge arrow while an object is off screen. |

Elements: `Box`, `Name`, `Distance`, `Health`, `Tracer`, `Skeleton`, `HeadDot`, `Highlight`, `Direction`, `Arrow`.

| Element | Keys |
| --- | --- |
| `Box` | `Enabled`, `Style` (`"Corners"`, `"Full"`, `"Both"`), `Color`, `Thickness`, `Transparency`, `Filled`, `FillTransparency`, `CornerScale`, `CornerMin`, `CornerMax`, `Glow`, `GlowThickness`, `GlowTransparency` |
| `Name` | `Enabled`, `Color`, `TextSize`, `Transparency`, `Outline`, `OutlineTransparency`, `UseDisplayName`, `Offset`, `Background`, `BackgroundColor`, `BackgroundTransparency`, `Padding` |
| `Distance` | `Enabled`, `Color`, `TextSize`, `Transparency`, `Outline`, `OutlineTransparency`, `Offset`, `Suffix`, `Scale`, `Background`, `BackgroundColor`, `BackgroundTransparency`, `Padding` |
| `Health` | `Enabled`, `Width`, `Gap`, `Transparency`, `Background`, `BackgroundTransparency`, `ShowText`, `Percent`, `TextSize`, `Style` (`"Vertical"`, `"Horizontal"`), `TextSide` (`"Left"`, `"Right"`, `"Above"`, `"Below"`), `Smoothing`, `Rounded`, `Pulse`, `Secondary` (`Enabled`, `Attribute`, `MaxAttribute`, `Color`, `Transparency`) |
| `Tracer` | `Enabled`, `Color`, `Thickness`, `Transparency`, `From` (`"Bottom"`, `"Top"`, `"Left"`, `"Right"`, `"Center"`, `"Mouse"`) |
| `Skeleton` | `Enabled`, `Color`, `Thickness`, `Transparency`, `Joints`, `JointRadius` |
| `HeadDot` | `Enabled`, `Color`, `Radius`, `Filled`, `Transparency` |
| `Highlight` | `Enabled`, `Preset` (`"Custom"`, `"Solid"`, `"Outline"`, `"Glow"`, `"Soft"`), `UseTeamColor`, `MaxInstances`, `Fill`, `Outline`, `FillTransparency`, `OutlineTransparency`, `DepthMode` (`"AlwaysOnTop"`, `"Occluded"`) |
| `Direction` | `Enabled`, `Color`, `Size`, `Thickness`, `Transparency`, `Offset` |
| `Arrow` | `Enabled`, `Color`, `Size`, `Thickness`, `Transparency`, `Offset`, `Label`, `TextSize`, `TextGap` |

`Distance.Scale` converts studs into the displayed unit; `Suffix` defaults to `"m"` because that is what the scene expects, not because the math converts anything.

`Health.Smoothing` is the convergence speed of the fill; `0` snaps instantly. `Health.Rounded` adds capsule end caps, which work identically on both backends because they are drawn as filled circles rather than UI corners.

`Box.Style = "Corners"` is the default look: four brackets over a very faint fill. `"Full"` is a plain outline, and `"Both"` combines them. `CornerScale` sets the bracket length as a fraction of the shorter box side, clamped by `CornerMin` and `CornerMax`.

`Box.Glow` adds a second, wider outline behind the box. `GlowThickness` and `GlowTransparency` shape it; keep the transparency high so it reads as light rather than a second box.

`Name.Background` and `Distance.Background` draw a chip behind the text. The chip is measured from the rendered string through `TextService` on the Gui backend and `TextBounds` on the Drawing backend, so it hugs the label on both. `Padding` is the inset on each side.

When `TeamColor` is on and a player has a `Team`, the team colour replaces the configured colour on the box, name, tracer, skeleton and head dot. NPCs and teamless players keep the settings colour.

`Health.Percent` shows `0-100%` instead of the raw health value, and only applies while `ShowText` is on. `Health.Pulse` breathes the fill below a quarter health.

`Health.Style = "Horizontal"` moves the bar under the box; `TextSide` chooses where the value sits relative to the bar. `Health.Secondary` reads a Humanoid attribute pair (for example `Armor` / `MaxArmor`) and draws a second bar beside the first, so games that expose armour or shields get a readout without a new element.

`Direction` draws a small two-line chevron above the box from the screen-projected head look vector. A target facing straight at the camera has almost no screen-space direction, so the chevron hides instead of flickering.

`Tracer.From` accepts `"Bottom"`, `"Top"`, `"Left"`, `"Right"`, `"Center"` and `"Mouse"`. `"Mouse"` follows the pointer.

`Highlight.Preset` replaces the four colour/transparency keys with `"Solid"`, `"Outline"`, `"Glow"` or `"Soft"`; `"Custom"` keeps them. `UseTeamColor` paints the fill and outline from the target's team, and `MaxInstances` (default `31`) stops the engine's Highlight ceiling from being exceeded.

With `Animations.Enabled` on, new targets fade in, the box settles from `Animations.Pop`, name and distance slide from the box edge, the tracer draws from its origin, and edge arrows slide in. Removed, dead or out-of-range targets fade out before their elements are destroyed. Element `Enabled` toggles are not animated, so the panel stays responsive.

`Filters` is off by default. Enabling it allows a whitelist, blacklist and case-insensitive name substring, then sorts by `Priority` and keeps the first `MaxTargets`. A cap hides the extras rather than retiring them, so a target can return immediately when the ranking changes.

`LOD` is on by default at `600` studs. Beyond that distance the skeleton, chips and tracer are skipped unless their LOD key is set, and each far target rebuilds every `UpdateInterval` seconds instead of every frame; the animation step and element draw still run every frame.

`Objects` draws tagged or named instances as boxes with a name and distance. Tags are read through `CollectionService`; names fall back to a workspace scan. A match is only kept when it also satisfies `Classes`, so enabling the feature with no tags and no names cannot box the whole map. Objects reuse the standard Box, Name, Distance and Arrow elements; Box and Name take `Objects.Color`, while the distance and arrow keep their own colours. `Objects.ShowArrow = false` hides the edge arrow when an object leaves the viewport.

`esp:ApplyPreset(name)` switches between `Default`, `Minimal`, `Clean`, `Sniper`, `Rage`, `Chams` and `Performance`. A preset only replaces the appearance blocks (`Box`, `Name`, `Distance`, `Health`, `Tracer`, `Skeleton`, `HeadDot`, `Highlight`, `Direction`, `Arrow` and `Animations`), so filters, LOD thresholds, object matching and security keep their current values. `esp:ListPresets()` returns the names in sorted order.

With `VisibilityCheck` on, a target whose head is blocked keeps drawing with `OccludedColor` and `OccludedTransparency` added to each element's own transparency. Set `ShowOccluded = false` for the old hide-on-sight behaviour. Every element follows the tint, including text chips, health text, skeleton joints and Highlight; health keeps its health colour and gains transparency instead of switching colour.

`Arrow` draws a chevron on the viewport edge for any target outside the viewport, including behind the camera. Only the arrow draws while a target is off screen. `Offset` is the gap from the edge to the arrow tip; `Label` adds the distance readout just inside it.

The bounding box is built from the rig's body parts rather than `GetBoundingBox()`, so hats, accessories and tools do not widen it. When a corner crosses the near plane the box falls back to a distance-scaled projection from the root, so it shrinks instead of vanishing at point-blank range.

## Security

`Security` is on by default. It reduces casual detection; it is not invisibility, and no client-side library can hide from a determined anti-cheat.

| Key | Default | Description |
| --- | --- | --- |
| `Security.Enabled` | `true` | Master switch for the measures below. |
| `Security.RandomizeNames` | `true` | Gives the ScreenGui and every overlay child a random tag instead of a `Phasma*` name. |
| `Security.ProtectGui` | `true` | Calls `protectgui` (or `syn.protect_gui`) so game scripts cannot reach the overlay. |
| `Security.HideHighlight` | `true` | Parents `Highlight` to the camera with an `Adornee`, so it is not a child of the character. |

The GUI backend already prefers `gethui()` over `PlayerGui` when an executor exposes it. The Drawing backend creates no Instances at all, so it has no names to randomize.

Because the overlay name is random by default, the dev panel's `overlay` counter can read `0`; its `esp` count is the authoritative one.

## Backends

`Phasma.Canvas.new(security)` returns the backend:

- **Drawing** when the executor exposes `Drawing.new`, which is the fast path and the one to prefer.
- **Gui** otherwise, a `ScreenGui` of Frames, TextLabels and UIStrokes. This is what runs in Studio.

Both expose the same object surface (`Line`, `Rect`, `Text`, `Circle`), so element modules never branch on the backend.

Projection goes through `Camera:WorldToViewportPoint`, the inset-free space. That is the same space the Drawing API draws in and the same space a ScreenGui gets with `IgnoreGuiInset`, so both backends land on the same pixels. `WorldToScreenPoint` would push everything down by the top bar.

## Performance

The render path is built to stay flat as the target count grows:

- Each `Entry` owns one reusable state table. Box, bones and joint points are written in place, so a frame allocates no per-target tables.
- Candidate records are pooled and reused. Sorting and `MaxTargets` only run while `Filters.Enabled` is on.
- Animations are an exponential approach in `Utils/Anim`, not `TweenService`: Drawing objects are not Instances, and there are no tween objects to allocate.
- Beyond `LOD.DetailDistance`, a target rebuilds only every `LOD.UpdateInterval` seconds. The animation step and element draw still run at full frame rate.
- Canvas proxies compare the new value with the old one and skip the write. Constant properties like colour and thickness cost nothing after the first frame.
- The bounding box projects only the rig's body parts, and falls back to a scaled root-centred box at the near plane.
- `VisibilityCheck` raycasts at most once per `VisibilityInterval` per target and reuses the result in between.
- Off-screen targets skip the visibility raycast and draw only the arrow, so nothing outside the viewport pays for the rest of the element set.
- NPCs are tracked by `DescendantAdded` / `DescendantRemoving` events. A full `workspace:GetDescendants()` walk only runs as an 8-second safety net.
- Object ESP reads tags through `CollectionService` on an interval; a workspace scan only runs when names are configured and no tags are set.
- Skeleton joint dots are created on first use, so the default settings do not allocate 20 extra objects per target.
- `Distance` and health text only rebuild their strings when the value changes.
- Text chips only re-measure when the string or text size changes, so the common frame does no text measurement at all.

## The test place

`Phasma.rbxl` opens with:

- A baseplate and a spawn at the origin.
- Eight R15 dummies at 10, 25, 50, 100, 200, 350 and 500 studs, plus one behind spawn, each with a different health value.
- Four tagged loot models (`PhasmaLoot`: Chest, Ammo, Medkit, Relic) so object ESP has something to box.
- A cover wall at 70 studs so `VisibilityCheck` has something to hide behind.
- A dev control panel in `StarterPlayerScripts` (`dev/PhasmaDebug.client.luau`) that owns the ESP and toggles each element live, with `IncludeNPCs = true` because the dummies are models rather than players. It is one window with `ESP`, `STYLE`, `ELEMENTS` and `COLOURS` tabs; each tab scrolls independently, so the panel stays a fixed size.
- The `ESP` tab also carries the preset buttons, filters (`MaxTargets`, priority), LOD detail distance and object ESP controls. The `STYLE` tab carries animation toggles, tracer origin and the horizontal-health switch.
- The `COLOURS` tab: pick an element chip, then drag the R, G and B sliders. Edits write straight into `esp.Settings`, so every element recolours on the next frame. Highlight fill and outline, the health bar background, the direction chevron and the arrow are included.

Controls: **RightAlt** hides or shows the window, the title bar drags it, and the tab bar switches pages. Every row toggles the matching setting on the next frame. The footer shows the active backend, the target count and the live engine count.

The panel is dev-only: nothing under `src/` requires it, so it is absent from `dist/Phasma.luau` and `dist/Phasma.rbxm`. `example/Phasma_Test.client.luau` is the standalone demo for releases and is no longer mapped into the place, since two ESP instances would draw everything twice.

The panel builds its own ScreenGui before it touches the library, so it is visible even when `ReplicatedStorage.Phasma.Init` is missing; in that case it says `library missing - see Output` and prints the reason.

The place is served, not rebuilt:

```powershell
powershell -File dev.ps1
```

`dev.ps1` runs darklua in watch mode (for `dist/Phasma.luau`) and `rojo serve` side by side. Connect the Rojo plugin, then stop and press Play so `StarterPlayerScripts` is cloned with the current scripts. Only build `Phasma.rbxl` when a self-contained place file is needed:

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
tools\lune.exe run build\init.luau 0.5.0

# live loop: rebuild the bundle on save, and serve the place
tools\darklua.exe process src/Init.luau dist/Phasma.luau -c build/darklua.json -w
tools\rojo.exe serve default.project.json
```

`dev.ps1` starts both halves of that loop in one command: darklua in watch mode and `rojo serve`. The place is never rebuilt during development; Rojo owns every script in it.

Two things to know about the live loop:

- `StarterPlayerScripts` is cloned into `PlayerScripts` when a play session starts. Scripts synced through Rojo only appear after you stop and press Play again.
- The place reads `dist/Phasma.luau`, so darklua must be watching (or the bundle must be rebuilt) before a library change reaches the client. The dev panel and the dummy spawner are served straight from `dev/`, so they update on the next play with no bundle step.

That split is deliberate: the source uses darklua path requires (`require("./Core/ESP")`), which Roblox cannot resolve on its own, and the bundle is what both the place and the release ship.

## Structure

```
src/
  Init.luau              entry point, CreateESP
  Constants.luau         version, overlay identity, palette
  Defaults.luau          every default setting
  Presets.luau           named looks for ApplyPreset
  Core/
    ESP.luau             render loop, candidates, filters, objects, entries
    Entry.luau           one target's element set and transition state
    Target.luau          bounding box, bones, distance, health, facing
    Camera.luau          projection helpers
    Config.luau          deep merge and in-place apply
    Canvas.luau          backend selection
    Canvas/
      DrawingCanvas.luau Drawing-API backend
      GuiCanvas.luau     ScreenGui backend
  Modules/
    Box.luau  Name.luau  Distance.luau  Health.luau
    Tracer.luau  Skeleton.luau  HeadDot.luau  Direction.luau
    Highlight.luau  Arrow.luau
  Utils/
    Color.luau            health gradient
    Alpha.luau            distance fade helper
    Occlusion.luau        shared occluded colour and transparency
    Anim.luau             exponential easing for transitions
    Random.luau           random instance tags for security
example/Phasma_Test.client.luau
dev/DummySpawner.server.luau
dev/PhasmaDebug.client.luau
build/                   darklua config, header, model project, build script
```

## License

MPL-2.0 - see [LICENSE](LICENSE) or <https://mozilla.org/MPL/2.0/>.

Copyright (c) 2026 Saint0-0
