# Development

## Prerequisites

The project is developed with the following tools. They are not committed to the repository and live in `tools/` during local work.

| Tool | Version used by this project | Purpose |
| --- | --- | --- |
| Rojo | 7.7 | Serves and builds the place tree. |
| Selene | 0.31 | Lints the Luau source. |
| StyLua | 2.5 | Formats the Luau source. |
| Lune | 0.10 | Runs the bundle build script. |
| darklua | 0.19 | Bundles and minifies the source. |

Place the executables in `tools/` before running any command below. The folder is ignored by Git.

## Formatting and linting

```powershell
tools\stylua.exe src
tools\selene.exe src
tools\stylua.exe example
tools\selene.exe example
```

The style configuration lives in `stylua.toml`, and the lint configuration lives in `selene.toml`. Both tools must report zero errors before a change is committed.

## Building

The build script bundles `src/Init.luau` into `dist/Phasma.luau` and builds `dist/Phasma.rbxm` from the same bundle. The version argument is required and must match `Constants.Version` in `src/Constants.luau`.

```powershell
tools\lune.exe run build\init.luau 0.7.1
```

The output is ignored by Git. Release workflows attach the two files to a GitHub release instead of committing them.

## Serving the place

`default.project.json` maps the built module and the demonstration script. Build the module first, then serve the project.

```powershell
tools\rojo.exe serve default.project.json
```

`dev.ps1` starts darklua in watch mode and Rojo at the same time, so a source change reaches the client on the next play session without a manual rebuild.

```powershell
powershell -File dev.ps1
```

The script accepts an optional project path.

```powershell
powershell -File dev.ps1 -Project dev.project.json
```

Rojo clones `StarterPlayerScripts` into `PlayerScripts` when a play session starts. A script that was synced while the session was running therefore appears only after the session is stopped and started again.

## Private test harness

The maintainer uses a test place with eight R15 dummies, tagged loot models, a cover wall and a control panel. These files are kept outside the published tree in `archive/dev-suite/`, and `dev.project.json` maps them for local use. Both paths are ignored by Git.

The harness is not part of the library and is not required to build or verify a release. A public clone can use `example/Phasma_Test.client.luau` as a starting point, or the configuration examples in [configuration.md](configuration.md).

## Release process

1. Update `Constants.Version` in `src/Constants.luau`.
2. Run StyLua and Selene over `src` and `example`.
3. Build both artifacts with the new version.
4. Update `CHANGELOG.md`.
5. Commit the change and create an annotated tag.
6. Push the commit and the tag.
7. Create a GitHub release and attach `dist/Phasma.luau` and `dist/Phasma.rbxm`.

```powershell
tools\stylua.exe src
tools\selene.exe src
tools\lune.exe run build\init.luau 0.7.1

git add -A
git commit -m "prepare v0.7.1"
git tag -a v0.7.1 -m "v0.7.1"
git push origin main
git push origin v0.7.1
```

The `loadstring` URL in the README points at the latest release, so the two assets must use the exact file names `Phasma.luau` and `Phasma.rbxm`.

## Conventions

- Every source file starts with the project header, the license line and the copyright line.
- Luau only. The source uses darklua path requires in the form `require("./Core/ESP")`.
- Tabs for indentation, double quotes for strings and a column width of 120, as configured by StyLua.
- No `TweenService` in the render path. Animation is handled by scalar tracks in `Utils/Anim`.
- Settings are plain tables. There is no setter layer; modules read `esp.Settings` directly.
- New elements belong in `src/Modules`, must expose `New(ctx)`, `Update(state)` and `Hide()`, and are registered in the element order in `src/Core/Entry.luau`.
- The bundle and the model must be rebuilt before a release is tagged.
