# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Key Documents

- `docs/spec/spec.md` — 要件仕様書（機能仕様・アーキテクチャ・データモデル・テスト戦略など）

## Project Overview

**xkdpi** is a macOS resident GUI application for managing and switching HiDPI display modes. It detects connected displays, lists available modes, identifies HiDPI modes, and allows users to switch between them. Settings persist across reboots via auto-launch and automatic restoration.

## Tech Stack

- **Language:** Swift
- **Build system:** Swift Package Manager
- **GUI framework:** AppKit
- **Display API:** CoreGraphics / Quartz Display Services
- **Testing:** XCTest
- **Development methodology:** TDD (write test first, verify failure, minimal implementation, pass, refactor)

## Build & Run Commands

```bash
swift build        # Build the project
swift run          # Run the application
swift test         # Run all tests
swift test --filter <TestClassName>  # Run a single test class
swift test --filter <TestClassName>/<testMethodName>  # Run a single test method
```

## Architecture (Layered)

```
App Layer           → GUI (MainWindow.swift), App Controller (main.swift)
Application Layer   → DisplayManager, ModeSwitchService, ConfigurationService
Domain Layer        → Display, DisplayMode (data models)
Infrastructure      → CoreGraphicsAdapter, SettingsStore (UserDefaults), Logger
```

Dependencies flow top-down only. The Domain layer has no external dependencies.

## Directory Structure (Target Layout)

```
Sources/
  App/           → main.swift (entry point)
  GUI/           → MainWindow.swift (AppKit window)
  Display/       → DisplayManager.swift
  Mode/          → ModeSwitchService.swift
  Config/        → SettingsStore.swift (UserDefaults persistence)
  Infrastructure/ → CoreGraphicsAdapter.swift
Tests/
  DisplayTests/  → XCTest test suites
scripts/
  build_dmg.sh   → .dmg distribution packaging
```

## Key Data Models

- **Display:** id, name, builtin (bool), currentMode
- **DisplayMode:** id, width, height, pixelWidth, pixelHeight, refreshRate, isHiDPI

HiDPI is determined by comparing pixel dimensions to logical dimensions (pixel > logical = HiDPI).

## Testing Strategy

- Use protocol-based dependency injection: `DisplayRepository` protocol with `MacDisplayRepository` (real) and `MockDisplayRepository` (test) implementations
- Unit tests cover: HiDPI detection, display mode formatting, settings save/restore
- Integration tests cover: Display API calls, mode switching, display detection

## Distribution

```bash
hdiutil create xkdpi.dmg -srcfolder xkdpi.app
```

Auto-launch via LaunchAgent plist at `~/Library/LaunchAgents/com.xkdpi.displaycontroller.plist`.

## Language

The spec and comments are in Japanese. Maintain Japanese for user-facing strings and documentation unless instructed otherwise.
