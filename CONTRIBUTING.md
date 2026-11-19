# Contributing

## Scope

Phasma is a client-side ESP library for Roblox executors. Contributions that improve correctness, performance, documentation or the modular structure are welcome. Changes that add unrelated features or dependencies should be discussed in an issue first.

## Reporting a bug

Open a GitHub issue and include the following information:

- The Phasma version, available through `Phasma.Version`.
- The active backend, available through `esp.Canvas.Kind`.
- The executor name and version, when the bug only occurs outside Studio.
- A short description of the expected behaviour and the observed behaviour.
- The smallest configuration that reproduces the problem.
- Any relevant output from the Roblox developer console.

Do not include account credentials, private keys or personal information in an issue.

## Proposing a change

Open an issue before starting a large change. Describe the problem, the proposed approach and any effect on the public API or the settings table. Small fixes, documentation corrections and formatting changes can be submitted directly as a pull request.

## Development workflow

1. Fork the repository and create a branch from `main`.
2. Follow the setup and build instructions in [docs/development.md](docs/development.md).
3. Make the change and verify it in Studio or on a supported executor.
4. Run StyLua and Selene over the source.
5. Update the documentation and the changelog when the public behaviour changes.
6. Open a pull request against `main`.

## Code style

- Luau only. The library targets Roblox clients and executors.
- Tabs for indentation, double quotes for strings and a column width of 120. StyLua enforces these rules.
- Every source file starts with the project header, the license line and the copyright line.
- Keep the render path free of per-frame allocations. Reuse tables and write into existing state where possible.
- Do not introduce `TweenService` into the render path. Animation is handled by the scalar tracks in `Utils/Anim`.
- New elements belong in `src/Modules`, must expose `New(ctx)`, `Update(state)` and `Hide()`, and must be registered in the element order in `src/Core/Entry.luau`.
- Public settings are plain values in `src/Defaults.luau`. Document every new key in [docs/configuration.md](docs/configuration.md).

## Commit messages

Use a short imperative subject line in lower case, for example `fix arrow label offset` or `add object esp`. Keep the subject under 72 characters and explain the reason for a non-trivial change in the body.

## License

By submitting a contribution, you agree that it is licensed under the Mozilla Public License 2.0, the same license as the rest of the project.
