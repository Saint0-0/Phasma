# Architecture

## Overview

Phasma separates three concerns: a rendering canvas, a set of element modules, and a small core that turns the game state into draw calls.

```
RenderStepped
  -> ESP:Render
       -> focus target? one candidate, otherwise collect humanoid and object candidates
       -> apply filters, sorting and the target cap (skipped while focused)
       -> resolve each candidate into the entry state
       -> Entry:StepAnim
       -> Entry:Draw
            -> element modules
                 -> canvas proxies
```

`ESP` owns the render loop, the settings table, the candidate pools and the entries. Each entry represents one target and owns every canvas object for that target. Resolving a target writes into a reusable state table, so the common frame performs no per-target allocations.

## Rendering

`Phasma.Canvas.new(security)` returns the ScreenGui canvas. It is the renderer that is verified in Studio, and every client uses it, so the Drawing API that an executor may expose never changes the output.

The canvas exposes `Line`, `Rect`, `Text` and `Circle`. Each element module receives a canvas object with plain property names, so no module branches on a renderer. Canvas proxies compare the new value with the previous one and skip the write when they match. Constant properties therefore cost nothing after the first frame.

## Projection

Projection uses `Camera:WorldToViewportPoint`, which is the inset free space a ScreenGui occupies when `IgnoreGuiInset` is set. `WorldToScreenPoint` would shift every element down by the top bar.

The bounding box is built from the rig's body parts instead of `GetBoundingBox()`, so accessories, hats and tools do not widen it. If a corner crosses the near plane, the entry falls back to a distance-scaled projection from the root. The box shrinks at point-blank range instead of disappearing.

## Entries and animation

An entry is created for a humanoid rig or a tagged object and is rebuilt when the rig changes. It holds:

- The canvas objects for every element.
- A reusable `State` table for the current frame.
- A set of scalar animation tracks.

The animation model is deliberately small. `Utils/Anim` exposes four functions:

- `Anim.step(current, target, duration, delta)` moves a track toward its target without overshooting. A non-positive duration snaps.
- `Anim.cubic(value)` is an ease-out cubic curve.
- `Anim.back(value, overshoot)` is an ease-out back curve that overshoots before it settles.
- `Anim.approach(current, target, speed, delta)` is a legacy exponential helper that remains for callers that prefer a convergence rate.

`Entry:StepAnim` advances the raw tracks and derives the display values once per-frame. The element modules read the display values and never apply easing themselves. This keeps the cost at one number per-channel per-target per-frame and avoids allocating tween objects.

The channels are `Fade`, `Pop`, `Slide`, `Sweep`, `Tracer` and `Arrow`. Pop, slide, sweep, tracer and arrow animate inward only. A retiring entry fades out with its other elements rather than reversing the entrance. The tracer also replays when a target returns to view after at least 0.2 seconds off-screen, which prevents a target that moves along the viewport edge from restarting the draw every frame.

## Focus

`Focus.Target` is stored as a normalized descriptor rather than resolved again on every frame. A `Player` is stored directly. A character `Model` resolves to its Player when it belongs to one, so a respawn keeps working, and stays a Model otherwise. A `Humanoid` resolves to its parent model, and any other `Model` or `BasePart` resolves to itself. `ESP:_syncFocus` compares the raw target from the live settings table with the cached value, so both `esp:SetTarget` and a direct assignment are handled.

When the descriptor is set, `Render` skips the player, NPC and object collection passes and pushes a single candidate. That candidate carries a `Focus` flag which tells `Target.build` and `Target.buildObject` to bypass distance checks, level of detail and the visibility check. The normal seen and retire loops still run, so the previous target fades out and the new one fades in through the same animation path as any other entry.

## Performance

The render path is designed to stay flat as the target count grows.

- Each entry owns one reusable state table. Box, bone and joint data are written in place.
- Candidate records are pooled and reused. Sorting and the target cap only run while `Filters.Enabled` is on.
- Focus resolves one candidate and skips the collection pass, the filter sort and the LOD rebuild interval.
- Animations are scalar tracks, not tweens. There are no tween objects to allocate.
- Beyond `LOD.DetailDistance`, a target rebuilds only every `LOD.UpdateInterval` seconds. The animation step and the element draw still run at full frame rate.
- Canvas writes are dirty-checked.
- The bounding box projects only the rig's body parts.
- Visibility raycasts are throttled per-target by `VisibilityInterval`.
- Off-screen targets skip the visibility raycast and draw only the arrow.
- NPCs are tracked through `DescendantAdded` and `DescendantRemoving`. A full `workspace:GetDescendants()` walk only runs as an eight-second safety net.
- Object ESP reads tags through `CollectionService` on an interval. A workspace scan only runs when names are configured and no tags are set.
- Skeleton joint dots are created on first use, so the default settings do not allocate twenty extra objects per-target.
- Distance and health text rebuild their strings only when the value changes.
- Text chips re-measure only when the string or the text size changes.

## Security model

Security is a set of noise reduction measures, not a guarantee.

- The overlay prefers `gethui()` when the executor exposes it, calls `protectgui` (or `syn.protect_gui`) when available, and can randomise the ScreenGui name and the name of every child.
- `Highlight` can be parented to the camera with an `Adornee`, which keeps it out of the character hierarchy.
- The guard rails are client-side. A game that inspects the overlay hierarchy or process memory can still identify it.

## Repository layout

```
src/
  Init.luau              entry point, CreateESP
  Constants.luau         version, overlay identity, palette
  Defaults.luau          every default setting
  Presets.luau           named looks for ApplyPreset
  Core/
    ESP.luau             render loop, candidates, focus, filters, objects, entries
    Entry.luau           one target's element set and transition state
    Target.luau          bounding box, bones, distance, health, facing
    Camera.luau          projection helpers
    Config.luau          deep merge and in-place apply
    Canvas.luau          canvas factory
    Canvas/
      GuiCanvas.luau     ScreenGui canvas
  Modules/
    Box.luau  Name.luau  Distance.luau  Health.luau
    Tracer.luau  Skeleton.luau  HeadDot.luau  Direction.luau
    Highlight.luau  Arrow.luau
  Utils/
    Color.luau            health gradient
    Alpha.luau            distance fade helper
    Occlusion.luau        shared occluded colour and transparency
    Anim.luau             time-based tracks and easing curves
    Random.luau           random instance tags for security
example/Phasma_Test.client.luau
build/                   darklua config, header, model project, build script
docs/                    user and developer documentation
```

## Design notes

- **Elements are per-target objects.** A shared element set would require per player state inside every module. Rebuilding on respawn is simpler and bounded.
- **Settings are live tables.** There is no setter layer to maintain. Mutating `esp.Settings` is the supported path, and the next frame observes the change.
- **Chips are measured, not guessed.** `TextService` is accurate enough for the first frame. Re-measuring only when the string changes keeps the common frame free of text measurement.
- **Team colour is a state override.** `Target` writes `state.TeamColor`, and each element falls back to its configured colour. The colour settings therefore still apply to NPCs and players without a team.
- **The bundle is the shipping unit.** The source uses darklua path requires, which Roblox cannot resolve directly. The build step produces the single file and the model from the same source.
