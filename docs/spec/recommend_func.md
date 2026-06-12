# xkdpi Recommendation Feature Specification

## 1. Overview

**xkdpi** is a macOS GUI application that optimizes and applies HiDPI display
modes for connected displays.

The tool especially targets common external display environments:

- 27-inch 4K displays.
- 32-inch 4K displays.
- WQHD displays.

It considers the balance between readability and workspace, then recommends and
applies an optimal HiDPI UI resolution based on PPI.

Settings are saved, and the app can start automatically after macOS restarts to
reapply saved settings.

# 2. Target Displays

The tool mainly targets these resolutions:

| Resolution | Description |
| --- | --- |
| 2560×1440 | WQHD monitor |
| 3840×2160 | 4K monitor |

Reasons:

- Many macOS users use these external monitor types.
- HiDPI scaling issues are common in this range.

# 3. How macOS HiDPI Works

macOS implements HiDPI using this flow:

```text
UI resolution
  -> 2x rendering
  -> downscale to display resolution
```

Example:

```text
2560×1440 UI
  -> 5120×2880 rendering
  -> display output
```

# 4. PPI-Aware Optimization

xkdpi considers PPI instead of only resolution.

PPI formula:

```text
sqrt(pixelWidth^2 + pixelHeight^2) / diagonalInches
```

Apple's Retina design target is approximately:

```text
220 PPI
```

xkdpi performs:

```text
display resolution
  -> PPI calculation
  -> optimal UI size calculation
  -> HiDPI mode recommendation
```

# 5. Recommended UI Resolutions

## 27-Inch 4K

PPI:

```text
approximately 163
```

Recommendation:

```text
2560×1440 HiDPI
```

Reason:

- Good balance between workspace and readability.

## 32-Inch 4K

Recommendation:

```text
3008×1692 HiDPI
```

Reason:

- Appropriate text size and UI density.

# 6. Features

## Display Detection

Fetch:

- Resolution.
- Refresh rate.
- Built-in or external display type.

## Display Mode Fetching

Fetch:

- UI resolution.
- HiDPI flag.
- Refresh rate.

## HiDPI Mode Identification

Display example:

```text
2560×1440 (HiDPI) 60Hz
```

## Recommended Mode Display

GUI display:

```text
Recommended
  2560×1440
```

## Display Mode Switching

Users can select and apply a mode from the GUI.

## Settings Persistence

Saved values:

- Display ID.
- Mode ID.
- Timestamp.

## Restore at Launch

After macOS restarts:

1. The app starts automatically.
2. Settings are loaded.
3. Display modes are reapplied.

# 7. UI

Application type:

- Standard GUI app.
- Dock-visible.
- Resident.

Display example:

```text
Display Name
Current: 2560×1440 (HiDPI) 60Hz

[x] Show HiDPI modes only

Refresh Rate
[x] 60Hz
[x] 120Hz

Recommended
(*) 2560×1440  [60Hz] [120Hz]

Other Modes
( ) 1920×1080  [60Hz]
```

# 8. Automatic Startup

xkdpi starts at macOS login when enabled.

Method:

- ServiceManagement login item.
- Compatibility LaunchAgent helper script.

Location:

```text
~/Library/LaunchAgents/com.xkdpi.displaycontroller.plist
```

# 9. Development Environment

| Item | Value |
| --- | --- |
| Language | Swift |
| Editor | VSCode |
| Build | Swift Package Manager |
| Test | Swift Testing |
| Method | TDD |

# 10. TDD Targets

Test targets:

- PPI calculation.
- Recommended UI resolution calculation.
- HiDPI detection.
- Settings persistence and restoration.

Test command:

```bash
swift test
```

# 11. Distribution

Distribution format:

- Source-based installation.
- Locally built app.
- Optional DMG.

Create:

```bash
./scripts/build_dmg.sh
```

# 12. Summary

xkdpi is designed as a PPI-aware HiDPI optimization tool, not just a resolution
switching tool.
