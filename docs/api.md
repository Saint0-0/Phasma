# API reference

## Loading

The library can be loaded in three ways. The README provides a combined loader that tries `ReplicatedStorage.Phasma.Init` with a five second timeout and falls back to the release file. The forms below cover each source on its own.

From a release, as a single file:

```lua
local Phasma = loadstring(game:HttpGet("https://github.com/Saint0-0/Phasma/releases/latest/download/Phasma.luau"))()
```

From the `Phasma.rbxm` model placed in `ReplicatedStorage`:

```lua
local Phasma = require(game:GetService("ReplicatedStorage").Phasma.Init)
```

From a Rojo project that maps `dist/Phasma.luau`:

```lua
local Phasma = require(game:GetService("ReplicatedStorage"):WaitForChild("Phasma"):WaitForChild("Init"))
```

## Module

| Member | Description |
| --- | --- |
| `Phasma.Version` | The current version string. |
| `Phasma.Defaults` | The default settings table. Treat it as read-only. |
| `Phasma.Presets` | The preset definitions and lookup helpers. |
| `Phasma.Canvas` | The backend selector. `Phasma.Canvas.new(security)` returns a canvas. |
| `Phasma:CreateESP(settings)` | Creates, starts and returns an ESP object. |
| `Phasma:GetActiveCount()` | Returns the number of ESP objects that are still alive. |
| `Phasma:StopAll()` | Destroys every ESP object created through the module. |

The module keeps weak references to every ESP it creates. A script that creates an ESP on startup can therefore call `Phasma:StopAll()` before creating another one, which guarantees that only one engine is drawing.

## ESP object

| Method | Description |
| --- | --- |
| `esp:Start()` | Starts the render loop. `CreateESP` calls it automatically. |
| `esp:SetEnabled(on)` | Shows or hides every element. |
| `esp:Toggle()` | Flips the enabled state and returns the new one. |
| `esp:SetMaxDistance(studs)` | Changes the target cutoff. |
| `esp:SetTarget(instance)` | Draws one chosen Player, Model, Humanoid or BasePart and ignores every other candidate. |
| `esp:ClearTarget()` | Returns to the normal target list. |
| `esp:GetTarget()` | Returns the current focus target, or `nil`. |
| `esp:ApplyPreset(name)` | Applies a named look and returns `true`, or `false` for an unknown name. |
| `esp:ListPresets()` | Returns the preset names in sorted order. |
| `esp:Stop()` | Disconnects the render loop and hides the overlay. |
| `esp:Destroy()` | Stops the render loop, destroys the elements and removes the overlay. |
| `esp.Settings` | The live settings table. Edit values in place. |
| `esp.Canvas.Kind` | The active backend, either `"Drawing"` or `"Gui"`. |

`CreateESP` starts the render loop immediately. `Stop` disconnects the loop and hides the overlay while the object remains valid, and `Start` can be called again on the same object. `Destroy` releases the canvas objects and should be used when the ESP is no longer needed.

## Settings

`esp.Settings` is the resolved table returned by the deep merge. Every element module keeps a reference to the same table, so a change is visible on the next frame.

```lua
esp.Settings.Box.Color = Color3.fromRGB(124, 196, 255)
esp.Settings.Skeleton.Enabled = true
esp.Settings.Animations.Speed = 1.5
```

The complete list of keys is documented in [configuration.md](configuration.md).

## Focus

Focus limits the ESP to one target. It is intended for autofarm and pathing scripts, where the destination is the only target that matters.

```lua
esp:SetTarget(player)              -- follows the character through a respawn
esp:SetTarget(workspace.Bandit)    -- a humanoid NPC
esp:SetTarget(workspace.Chest)     -- a tagged or plain Model
esp:SetTarget(workspace.Marker)    -- a BasePart

esp:SetTarget(workspace.NextChest) -- change the destination at runtime
esp:ClearTarget()                  -- return to the normal target list
```

`SetTarget` accepts a `Player`, `Model`, `Humanoid` or `BasePart`. A Player or a player character is stored as a Player, so the entry follows a respawn. A Humanoid or a body part that belongs to a character resolves to that character. Any other Model or BasePart is drawn with the object element set.

The method returns `true` when the target is accepted and `false` for an unsupported value, in which case the current target is unchanged. Passing `nil` clears the focus.

While focus is active, every automatic selection rule is bypassed for the chosen instance:

- `Filters`, `TeamCheck`, `IgnoreLocal`, `IncludeNPCs` and `Objects.Enabled` do not exclude it.
- `MaxDistance`, `Objects.MaxDistance` and the level of detail thresholds do not remove or reduce it.
- The visibility check does not hide it behind cover.
- Humanoid targets keep the full element set. Object targets force the edge arrow on.

Other targets retire through the normal animation path, so changing the target fades the old one out and the new one in. Focus is also exposed as `esp.Settings.Focus.Target`, and direct assignment to that key is picked up on the next frame.

## Presets

`esp:ApplyPreset(name)` switches between the following looks:

- `Default`
- `Minimal`
- `Clean`
- `Sniper`
- `Rage`
- `Chams`
- `Performance`

A preset only replaces the appearance blocks: `Animations`, `Box`, `Name`, `Distance`, `Health`, `Tracer`, `Skeleton`, `HeadDot`, `Highlight`, `Direction` and `Arrow`. Filters, focus, level of detail thresholds, object matching and security keep their current values.

`esp:ListPresets()` returns the names in sorted order. `Phasma.Presets.get(name)` returns the raw definition, and `Phasma.Presets.names()` returns the same sorted list.

## Examples

### Minimal configuration

```lua
local esp = Phasma:CreateESP({
	Box = { Enabled = true },
	Name = { Enabled = true },
})
```

Every other element keeps its default. The default configuration already enables the full element set, so explicit `Enabled` flags are only needed when a caller wants to reduce it.

### Team colours and filters

```lua
local esp = Phasma:CreateESP({
	TeamCheck = true,
	TeamColor = true,
	MaxDistance = 800,
	Filters = {
		Enabled = true,
		MaxTargets = 12,
		Priority = "Distance",
		Blacklist = { "SomeName", 1234567, "Spectators" },
	},
})
```

### Object ESP

```lua
local esp = Phasma:CreateESP({
	Objects = {
		Enabled = true,
		Tags = { "Loot", "Chest" },
		Classes = { "Model", "BasePart" },
		MaxDistance = 600,
		Color = Color3.fromRGB(255, 206, 132),
	},
})
```

### Focus an autofarm destination

```lua
local esp = Phasma:CreateESP({
	MaxDistance = 1000,
	Box = { Enabled = true },
	Name = { Enabled = true },
	Distance = { Enabled = true },
})

-- The farm loop chooses the next destination. Only that destination draws.
local function moveTo(destination)
	esp:SetTarget(destination)
	-- Walk toward destination here.
end

moveTo(workspace:WaitForChild("Bandit"))
moveTo(workspace:WaitForChild("Chest"))

esp:ClearTarget()
```

A focused target ignores `MaxDistance` and the filters, so an autofarm destination is never dropped when it sits further away than the normal cutoff.

### Animation tuning

```lua
local esp = Phasma:CreateESP({
	Animations = {
		Enabled = true,
		Speed = 1.5,
		Fade = true,
		Pop = true,
		Slide = true,
		Sweep = true,
		Tracer = true,
		Arrow = true,
	},
})
```

Set `Animations.Speed = 0` to make every channel instantaneous while keeping the individual switches available. A single channel can be disabled without affecting the rest.

### Cleanup

```lua
esp:Destroy()
```

After the call, the object should not be used again.
