# Repository Guidelines

## Project Structure & Module Organization

`xkdpi` is a Swift Package Manager project for a macOS AppKit display-mode utility. The executable entry point lives in `Sources/App`, while reusable application code is in `Sources/xkdpi`.

- `Sources/xkdpi/Domain`: core models such as `Display` and `DisplayMode`.
- `Sources/xkdpi/Application`: services and orchestration (`DisplayManager`, `ModeSwitchService`, `ConfigurationService`).
- `Sources/xkdpi/Infrastructure`: CoreGraphics adapters, persistence, logging, and repository protocols.
- `Sources/xkdpi/GUI`: AppKit window and view code.
- `Tests/DisplayTests`: unit tests and mock helpers, grouped by layer.
- `docs/spec`: product and architecture notes. Check these before changing behavior.
- `scripts`: local packaging and launch-agent helper scripts.

## Build, Test, and Development Commands

- `swift build`: compile the package in debug mode.
- `swift run`: build and launch the `xkdpi` executable locally.
- `swift test`: run the full test suite.
- `swift test --filter DisplayManagerTests`: run one test type.
- `swift test --filter DisplayManagerTests/fetchDisplays_emptyResult_returnsEmpty`: run one specific test.
- `scripts/build_dmg.sh`: create a release app bundle and `xkdpi.dmg`.
- `scripts/setup_launch_agent.sh`: install the local LaunchAgent for auto-start behavior.

## Coding Style & Naming Conventions

Use standard Swift formatting with 4-space indentation. Types use `PascalCase`; functions, properties, and local variables use `camelCase`. Keep layer dependencies directed inward: domain types should stay free of AppKit/CoreGraphics side effects, while infrastructure owns platform API calls. Prefer protocol-based dependency injection, as shown by `DisplayRepository` and `MockDisplayRepository`.

Existing comments and user-facing strings are primarily Japanese; keep that style unless a task explicitly asks otherwise.

## Testing Guidelines

Tests use Swift Testing (`import Testing`) with `@Test` and `#expect`. Name tests with the pattern `method_condition_expectedResult`, for example `fetchDisplays_repositoryThrows_propagatesError`. Place new tests under the matching layer directory in `Tests/DisplayTests`, and add mocks in `Tests/DisplayTests/MockHelpers` when platform APIs need isolation.

Run `swift test` before submitting changes. For behavior changes, add or update focused tests before touching implementation where practical.

## Commit & Pull Request Guidelines

The current history is small and includes both plain initial commits and conventional-style messages such as `feat: initial commit`. Prefer short imperative commits with a type prefix when useful, for example `fix: restore saved display mode`.

Pull requests should describe the behavior change, list verification commands run, and link related issues or spec notes. Include screenshots or screen recordings for GUI changes.
