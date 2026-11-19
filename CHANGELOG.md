# Changelog

All notable changes to Phasma are recorded here. The format follows the conventions of Keep a Changelog, and the project uses semantic versioning.

## 0.6.0 (2026-11-19)

### Added

- Time-based animation tracks with ease-out cubic and back curves.
- Separate channels for fade, box pop, chip slide, corner sweep, tracer draw and arrow slide.
- Tracer glow line and a spark that rides the drawing tip.
- Edge arrow that slides in and grows from 65 percent as it lands.
- Tracer replay when a target returns to view after being off-screen for at least 0.2 seconds.

### Changed

- `Animations.Speed` is now a duration multiplier. `2` is twice as fast and `0` snaps.
- Default animation values are larger and more visible.
- Pop, slide, sweep, tracer and arrow animate inward only, so a retiring target fades out as a single motion.
- `Tracer.GlowTransparency` defaults to `0.35` and is added to the core transparency.

### Removed

- The exponential `Anim.expo` curve. The time-based tracks replace it.

## 0.5.0 (2026-11-19)

### Added

- Occlusion on every element, including text chips, health text, skeleton joints and Highlight.
- Target entrance animations, tracer draw-on and arrow slide.
- Tracer origins: Bottom, Top, Left, Right, Center and Mouse.
- Filters with whitelist, blacklist, name substring, `MaxTargets` and priority sorting.
- Distance-based level of detail with far target element skips and update throttling.
- Facing chevron, horizontal health, health text side and an optional attribute-driven secondary bar.
- Object ESP for tagged or named Models and BaseParts.
- Highlight chams presets, team colour support and a 31 instance cap.
- Named presets through `esp:ApplyPreset(name)`.

### Changed

- The arrow distance label sits further from the chevron, toward the viewport centre.

## 0.4.0 (2026-11-19)

### Added

- Off-screen arrows at the viewport edge, with a distance label and a behind-camera fallback.
- Occluded targets keep drawing with a shared tint instead of vanishing, with a `ShowOccluded` switch.

### Fixed

- Boxes clamp at the near plane instead of disappearing at point-blank range.
- Bounding boxes use body parts only, so hats, accessories and tools no longer widen them.

## 0.3.0 (2026-11-19)

### Added

- Team colours on the box, name, tracer, skeleton and head dot.
- Soft box glow behind the bracket outline.
- Measured text chips behind the name and distance, cached per string.
- Health percentage text and a below quarter pulse.
- Live RGB colour panel in the development harness.

## 0.2.0 (2026-11-19)

### Added

- Corner-bracket box style with a faint fill.
- Smoothed capsule health bar with end caps.
- Refined palette, outline transparency and distance fade.
- Optional skeleton joint dots, created lazily.
- Allocation-free state tables, dirty-checked canvas writes, throttled raycasts and a behind-camera cull.
- Event-driven NPC registry with an eight-second safety rescan.
- Security defaults: random names, `protectgui`, `gethui` and camera parented Highlight.

## 0.1.0 (2026-11-19)

### Added

- Initial library with Box, Name, Distance, Health, Tracer, Skeleton, HeadDot and Highlight elements.
- Drawing and ScreenGui backends behind one object surface.
- `Phasma:CreateESP(settings)` with live settings and basic lifecycle methods.
