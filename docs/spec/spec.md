# xkdpi Specification

# 1. Overview

**xkdpi** is a resident macOS GUI application that manages and switches HiDPI
display modes for connected displays.

Users can inspect each display's current mode and available modes from the GUI,
then switch to any available mode.

Settings are saved and, after macOS restarts:

1. The app starts automatically.
2. Saved settings are loaded.
3. Display settings are applied automatically.

# 2. Goals

xkdpi aims to:

- Make macOS HiDPI mode management easy.
- Restore resolution settings per display automatically.
- Provide intuitive display-mode changes from the GUI.
- Apply saved settings automatically after macOS restarts.

# 3. Development Policy

## 3.1 Development Environment

| Item | Value |
| --- | --- |
| Language | Swift |
| Editor | VSCode |
| Build | Swift Package Manager |
| UI | AppKit |
| Test | Swift Testing |
| Method | TDD |

## 3.2 TDD Rules

All features should be implemented with TDD.

Development cycle:

1. Write a test.
2. Confirm the test fails.
3. Write the minimum implementation.
4. Make the test pass.
5. Refactor.

Targets:

- Display mode identification.
- Display mode switching logic.
- Settings persistence.
- Display management.

# 4. Scope

## 4.1 In Scope

xkdpi provides:

- Connected display detection.
- Available display mode listing.
- HiDPI mode identification.
- Display mode switching.
- GUI operation.
- Settings persistence.
- Automatic startup.
- Settings restoration at launch.

## 4.2 Out of Scope

The initial version does not include:

- EDID operations.
- Virtual display generation.
- New HiDPI mode generation.
- HDR control.
- Brightness control.
- Color profile management.
- Mirroring control.
- Advanced display settings.

# 5. Use Cases

## 5.1 Confirm Display Modes

When users open the GUI, they can confirm:

- Connected displays.
- Current display mode.
- Available display modes.

## 5.2 Change Display Mode

User flow:

1. Select a display.
2. View available display modes.
3. Click a mode.
4. Switch the display mode.

## 5.3 Save Settings

The mode selected by the user is saved.

## 5.4 Restore at Launch

After macOS restarts:

1. xkdpi starts automatically.
2. Saved settings are loaded.
3. Display settings are applied.

# 6. UI Specification

## 6.1 UI Type

xkdpi is a standard GUI application.

Characteristics:

- Dock visibility.
- Resident process.
- GUI operation.

## 6.2 Screen Structure

The main window shows one column per display.

Each display column includes:

- Display name.
- Built-in or external display badge.
- Current mode.
- HiDPI-only filter.
- Refresh-rate filters.
- Recommended mode.
- Other available modes.

Mode rows show the resolution and available refresh-rate badges.

# 7. Automatic Startup

xkdpi can start automatically at macOS login.

Implementation:

- Use ServiceManagement through the app's status bar menu.
- Keep `scripts/setup_launch_agent.sh` only as a compatibility helper.

Startup process:

1. Load settings.
2. Fetch display state.
3. Apply saved modes.

# 8. Architecture

The project is layered as follows:

- `Domain`: Core models such as `Display` and `DisplayMode`.
- `Application`: Services and orchestration such as `DisplayManager`,
  `ModeSwitchService`, and `ConfigurationService`.
- `Infrastructure`: CoreGraphics adapters, persistence, logging, and repository
  protocols.
- `GUI`: AppKit windows, views, and status bar controllers.
- `App`: Executable entry point and dependency graph construction.

Dependencies should point inward. Domain types must not depend on AppKit or
CoreGraphics side effects. Infrastructure owns platform API calls.

# 9. Data Model

## Display

- `id`: CoreGraphics display ID.
- `name`: Display name.
- `builtin`: Whether the display is built in.
- `currentMode`: Current display mode.
- `availableModes`: Available display modes.
- `physicalWidthMM`: Physical width in millimeters.
- `physicalHeightMM`: Physical height in millimeters.

## DisplayMode

- `id`: CoreGraphics mode ID.
- `width`: Logical width.
- `height`: Logical height.
- `pixelWidth`: Pixel width.
- `pixelHeight`: Pixel height.
- `refreshRate`: Refresh rate.
- `isHiDPI`: Whether the mode is HiDPI.

## DisplaySetting

- `displayID`: Display ID.
- `modeID`: Mode ID.
- `timestamp`: Save timestamp.

# 10. Settings Persistence

Saved values:

- Display ID.
- Mode ID.
- Timestamp.

Storage:

- UserDefaults key: `xkdpi.settings`.
- Value format: JSON-encoded `[DisplaySetting]`.

# 11. Logging

Log targets:

- Startup.
- Display detection.
- Mode fetches.
- Mode switching.
- Errors.

# 12. Test Strategy

## Unit Tests

Targets:

- HiDPI detection.
- Display mode formatting.
- Settings persistence.
- Settings restoration.
- Recommendation logic.

## Integration-Oriented Tests

Targets:

- Display API boundaries.
- Display mode switching orchestration.
- Display detection orchestration.

## Mocks

Tests should isolate platform APIs with mocks such as `MockDisplayRepository`.

# 13. Directory Structure

```text
Sources/
  App/
    main.swift
    AppDelegate.swift
  xkdpi/
    Domain/
    Application/
    Infrastructure/
    GUI/
Tests/
  DisplayTests/
docs/
  spec/
scripts/
```

# 14. Build

Run:

```bash
swift build
swift run
swift test
```

# 15. Distribution

Distribution format:

- Source-based installation.
- Locally built `.app`.
- Optional `.dmg` generated by `scripts/build_dmg.sh`.

Create:

```bash
./scripts/install.sh
```

# 16. Development Phases

Phase 1:

- GUI creation.
- Display fetch.
- Mode fetch.
- HiDPI identification.

Phase 2:

- Mode switching.
- Settings persistence.

Phase 3:

- Automatic startup.
- Settings restoration.
- DMG generation.

# 17. Acceptance Criteria

xkdpi must satisfy:

- Display list shown in the GUI.
- Display mode list retrieval.
- HiDPI mode identification.
- Display mode switching.
- Settings persistence.
- Automatic restoration after restart.
- Logging.
- DMG generation.

# 18. Conclusion

**xkdpi** is developed as a lightweight, practical, resident GUI application for
managing macOS HiDPI display modes.
