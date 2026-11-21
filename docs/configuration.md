# Configuration

Every setting is optional. `Phasma:CreateESP(settings)` deep merges the supplied table over `Phasma.Defaults`, so a partial table keeps every value that is not mentioned. Nested tables are merged recursively.

Settings live in `esp.Settings`. Element flags and colours are read every frame, so editing the table takes effect on the next frame.

## Global

| Key | Default | Description |
| --- | --- | --- |
| `Enabled` | `true` | Master switch for the whole ESP. |
| `MaxDistance` | `1000` | Targets past this many studs are skipped. |
| `TeamCheck` | `false` | Skips players on the local player's team. |
| `VisibilityCheck` | `false` | Raycasts to the head and tints occluded targets. |
| `VisibilityInterval` | `0.12` | Seconds between visibility raycasts for one target. |
| `ShowOccluded` | `true` | Keeps occluded targets on screen with the shared occlusion tint. `false` hides them. |
| `OccludedColor` | `#848C9C` | Colour used for every occluded element. |
| `OccludedTransparency` | `0.45` | Added to an occluded element's own transparency. |
| `IgnoreLocal` | `true` | Keeps the local player out of the list. |
| `IncludeNPCs` | `false` | Also draws humanoid models that are not player characters. |
| `TeamColor` | `true` | Players with a `Team` use its colour for the box, name, tracer, skeleton and head dot. |
| `FadeWithDistance` | `true` | Far targets dim toward `FadeFloor` instead of staying at full brightness. |
| `FadeFloor` | `0.72` | Alpha at `MaxDistance`. A value of `1` disables the effect. |

## Animations

| Key | Default | Description |
| --- | --- | --- |
| `Animations.Enabled` | `true` | Master switch for target transitions. Element toggles stay instant either way. |
| `Animations.Speed` | `1` | Duration multiplier. `2` is twice as fast, `0.5` is half speed and `0` snaps. |
| `Animations.Fade` | `true` | Fades the whole target in and out. |
| `Animations.FadeDuration` | `0.25` | Seconds for one fade direction at `Speed = 1`. |
| `Animations.Pop` | `true` | Settles the box from slightly smaller with a soft overshoot. |
| `Animations.PopAmount` | `0.14` | Fraction the box starts below full size. |
| `Animations.PopDuration` | `0.34` | Seconds for the pop to settle. |
| `Animations.Slide` | `true` | Slides the name, distance and facing marker out from the box. |
| `Animations.SlideDistance` | `14` | Pixels travelled at the start of the slide. |
| `Animations.SlideDuration` | `0.3` | Seconds for the slide to settle. |
| `Animations.Sweep` | `true` | Draws the corner brackets outward from their corners. |
| `Animations.SweepDuration` | `0.36` | Seconds for all four corners to finish. |
| `Animations.Tracer` | `true` | Grows the tracer from its origin to the target. |
| `Animations.TracerDuration` | `0.5` | Seconds for the tracer to reach the target. |
| `Animations.Arrow` | `true` | Slides and grows edge arrows in from outside the viewport. |
| `Animations.ArrowDuration` | `0.32` | Seconds for the arrow to land. |

With animations enabled, new targets fade in, the box pops in with a soft overshoot, the corner brackets sweep outward, the name and distance slide from the box edge, the tracer draws from its origin with a glow and a spark on the tip, and edge arrows slide and grow in. Removed, dead or out-of-range targets fade out before their elements are destroyed.

The tracer and the arrow only animate inward. A retiring target fades out with its other elements instead of reversing the draw. The pop and the slide also stay at full size on retire, so the exit reads as a single fade.

Each channel can be disabled on its own with `Fade`, `Pop`, `Slide`, `Sweep`, `Tracer` or `Arrow`. `Speed` scales every duration at once. Element `Enabled` toggles are not animated, so a control panel remains responsive.

## Filters and level of detail

| Key | Default | Description |
| --- | --- | --- |
| `Filters.Enabled` | `false` | Enables the whitelist, blacklist, name filter and cap below. |
| `Filters.Whitelist` | `{}` | Only these names, UserIds or team names draw. An empty list allows everyone. |
| `Filters.Blacklist` | `{}` | Names, UserIds or team names that never draw. |
| `Filters.NameContains` | `""` | Case-insensitive substring of the display name. |
| `Filters.MaxTargets` | `0` | Maximum drawn targets. `0` keeps every match. |
| `Filters.Priority` | `"Distance"` | Sort key for the cap: `"Distance"`, `"Health"` (lowest first) or `"Name"`. |
| `LOD.Enabled` | `true` | Beyond `DetailDistance`, expensive elements are skipped and rebuilds are throttled. |
| `LOD.DetailDistance` | `600` | Studs before level of detail applies. |
| `LOD.Skeleton` | `false` | Keep skeletons beyond `DetailDistance`. |
| `LOD.Chips` | `false` | Keep name and distance chips beyond `DetailDistance`. |
| `LOD.Tracer` | `false` | Keep tracers beyond `DetailDistance`. |
| `LOD.UpdateInterval` | `0.05` | Seconds between far target rebuilds. |

Filters are off by default. Enabling them allows a whitelist, a blacklist and a case-insensitive name substring, then sorts by `Priority` and keeps the first `MaxTargets`. A cap hides the extra targets instead of retiring them, so a target can return immediately when the ranking changes.

Level of detail is on by default at `600` studs. Beyond that distance the skeleton, chips and tracer are skipped unless their LOD key is set, and each far target rebuilds every `UpdateInterval` seconds instead of every frame. The animation step and the element draw still run at full frame rate.

## Focus

| Key | Default | Description |
| --- | --- | --- |
| `Focus.Target` | `nil` | Draws one chosen `Player`, `Model`, `Humanoid` or `BasePart` and ignores every other candidate. |

Focus is normally changed through `esp:SetTarget(instance)`, `esp:ClearTarget()` and `esp:GetTarget()`. The setting is live, so assigning `esp.Settings.Focus.Target` directly also takes effect on the next frame. A Player or a player character is followed through a respawn. A Humanoid or a body part of a character resolves to that character. Any other Model or BasePart uses the object element set.

Explicit focus is a developer decision, so it bypasses every automatic selection rule for the chosen instance: filters, `TeamCheck`, `IgnoreLocal`, `IncludeNPCs`, `Objects.Enabled`, `MaxDistance`, `Objects.MaxDistance`, the level of detail thresholds and the visibility check. Humanoid targets keep the full element set at any distance. Object targets keep Box, Name, Distance and Arrow, and their edge arrow is forced on.

While focus is active, the normal candidate list is suppressed. Other targets fade out with the usual transition when the target is set or changed, and the normal list returns when `ClearTarget` runs. If the focused instance is destroyed, nothing is drawn until a new target is set.

## Object ESP

| Key | Default | Description |
| --- | --- | --- |
| `Objects.Enabled` | `false` | Draws matching `Model` and `BasePart` instances with Box, Name, Distance and Arrow. |
| `Objects.MaxDistance` | `1000` | Object cutoff, independent of `MaxDistance`. |
| `Objects.ScanInterval` | `0.5` | Seconds between registry scans. |
| `Objects.Names` | `{}` | Instance names to match. A name scan only runs when no tags are set. |
| `Objects.Classes` | `{ "Model" }` | `ClassName` allow-list. A match must satisfy one entry. |
| `Objects.Tags` | `{}` | CollectionService tags to match. Tags take precedence over names. |
| `Objects.Color` | muted grey | Box and name colour for objects. |
| `Objects.ShowArrow` | `true` | Draws the edge arrow while an object is off-screen. |

Objects are matched through `CollectionService` tags or through instance names. A match is only kept when it also satisfies `Classes`, so enabling the feature with no tags and no names cannot box the whole map. Objects reuse the standard Box, Name, Distance and Arrow elements. Box and Name take `Objects.Color`, while the distance and the arrow keep their own colours.

## Elements

The available elements are `Box`, `Name`, `Distance`, `Health`, `Tracer`, `Skeleton`, `HeadDot`, `Highlight`, `Direction` and `Arrow`.

| Element | Keys |
| --- | --- |
| `Box` | `Enabled`, `Style` (`"Corners"`, `"Full"`, `"Both"`), `Color`, `Thickness`, `Transparency`, `Filled`, `FillTransparency`, `CornerScale`, `CornerMin`, `CornerMax`, `Glow`, `GlowThickness`, `GlowTransparency` |
| `Name` | `Enabled`, `Color`, `TextSize`, `Transparency`, `Outline`, `OutlineTransparency`, `UseDisplayName`, `Offset`, `Background`, `BackgroundColor`, `BackgroundTransparency`, `Padding` |
| `Distance` | `Enabled`, `Color`, `TextSize`, `Transparency`, `Outline`, `OutlineTransparency`, `Offset`, `Suffix`, `Scale`, `Background`, `BackgroundColor`, `BackgroundTransparency`, `Padding` |
| `Health` | `Enabled`, `Width`, `Gap`, `Transparency`, `Background`, `BackgroundTransparency`, `ShowText`, `Percent`, `TextSize`, `Style` (`"Vertical"`, `"Horizontal"`), `TextSide` (`"Left"`, `"Right"`, `"Above"`, `"Below"`), `Smoothing`, `Rounded`, `Pulse`, `Secondary` (`Enabled`, `Attribute`, `MaxAttribute`, `Color`, `Transparency`) |
| `Tracer` | `Enabled`, `Color`, `Thickness`, `Transparency`, `From` (`"Bottom"`, `"Top"`, `"Left"`, `"Right"`, `"Center"`, `"Mouse"`), `Glow`, `GlowThickness`, `GlowTransparency`, `Spark` |
| `Skeleton` | `Enabled`, `Color`, `Thickness`, `Transparency`, `Joints`, `JointRadius` |
| `HeadDot` | `Enabled`, `Color`, `Radius`, `Filled`, `Transparency` |
| `Highlight` | `Enabled`, `Preset` (`"Custom"`, `"Solid"`, `"Outline"`, `"Glow"`, `"Soft"`), `UseTeamColor`, `MaxInstances`, `Fill`, `Outline`, `FillTransparency`, `OutlineTransparency`, `DepthMode` (`"AlwaysOnTop"`, `"Occluded"`) |
| `Direction` | `Enabled`, `Color`, `Size`, `Thickness`, `Transparency`, `Offset` |
| `Arrow` | `Enabled`, `Color`, `Size`, `Thickness`, `Transparency`, `Offset`, `Label`, `TextSize`, `TextGap` |

### Element notes

`Distance.Scale` converts studs into the displayed unit. `Suffix` defaults to `"m"` because that is what the scene expects, not because the library converts the value.

`Health.Smoothing` is the convergence speed of the fill. `0` snaps instantly. `Health.Rounded` adds capsule end caps, which are drawn as filled circles rather than UI corners.

`Box.Style = "Corners"` is the default look: four brackets over a very faint fill. `"Full"` is a plain outline, and `"Both"` combines them. `CornerScale` sets the bracket length as a fraction of the shorter box side, clamped by `CornerMin` and `CornerMax`.

`Box.Glow` adds a second, wider outline behind the box. `GlowThickness` and `GlowTransparency` shape it. Keep the transparency high so it reads as light rather than as a second box.

`Name.Background` and `Distance.Background` draw a chip behind the text. The chip is measured from the rendered string through `TextService`, so it hugs the label on the first frame. `Padding` is the inset on each side.

When `TeamColor` is on and a player has a `Team`, the team colour replaces the configured colour on the box, name, tracer, skeleton and head dot. NPCs and players without a team keep the settings colour.

`Health.Percent` shows `0-100%` instead of the raw health value and only applies while `ShowText` is on. `Health.Pulse` breathes the fill below a quarter health.

`Health.Style = "Horizontal"` moves the bar under the box. `TextSide` chooses where the value sits relative to the bar. `Health.Secondary` reads a Humanoid attribute pair, for example `Armor` and `MaxArmor`, and draws a second bar beside the first. Games that expose armour or shields therefore get a readout without a new element.

`Direction` draws a small two line chevron above the box from the screen projected head look vector. A target facing straight at the camera has almost no screen space direction, so the chevron hides instead of flickering.

`Tracer.From` accepts `"Bottom"`, `"Top"`, `"Left"`, `"Right"`, `"Center"` and `"Mouse"`. `"Mouse"` follows the pointer. `Tracer.Glow` draws a wider, fainter line behind the tracer, and `GlowTransparency` is added to the core transparency so the glow stays softer than the line. `Tracer.Spark` rides the tip while the tracer is drawing and fades out once it reaches the target. The draw replays when a target returns to view after being off-screen for at least 0.2 seconds, so a box that wobbles on the edge does not restart the animation every frame.

`Highlight.Preset` replaces the four colour and transparency keys with `"Solid"`, `"Outline"`, `"Glow"` or `"Soft"`. `"Custom"` keeps the supplied values. `UseTeamColor` paints the fill and the outline from the target's team, and `MaxInstances` (default `31`) prevents the engine ceiling from being exceeded.

`Arrow` draws a chevron on the viewport edge for any target outside the viewport, including targets behind the camera. Only the arrow draws while a target is off-screen. `Offset` is the gap from the edge to the arrow tip, and `Label` adds the distance readout just inside it.

The bounding box is built from the rig's body parts rather than `GetBoundingBox()`, so hats, accessories and tools do not widen it. When a corner crosses the near plane, the box falls back to a distance-scaled projection from the root, so it shrinks instead of vanishing at point-blank range.

## Occlusion

With `VisibilityCheck` on, a target whose head is blocked keeps drawing with `OccludedColor` and `OccludedTransparency` added to each element's own transparency. Set `ShowOccluded = false` to hide occluded targets instead.

Every element follows the tint, including text chips, health text, skeleton joints and Highlight. Health keeps its health colour and gains transparency rather than switching colour.

## Security

`Security` is on by default. It reduces casual detection, but it is not invisibility, and no client-side library can hide from a determined anti-cheat.

| Key | Default | Description |
| --- | --- | --- |
| `Security.Enabled` | `true` | Master switch for the measures below. |
| `Security.RandomizeNames` | `true` | Gives the ScreenGui and every overlay child a random tag instead of a `Phasma` name. |
| `Security.ProtectGui` | `true` | Calls `protectgui` (or `syn.protect_gui`) so game scripts cannot reach the overlay. |
| `Security.HideHighlight` | `true` | Parents `Highlight` to the camera with an `Adornee`, so it is not a child of the character. |

The overlay prefers `gethui()` over `PlayerGui` when an executor exposes it, so a game script cannot reach it through the player hierarchy.

Because the overlay name is random by default, a script that counts Instances by name can report `0`. Count the active ESP objects through `Phasma:GetActiveCount()` instead.
