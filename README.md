# xkdpi

macOS HiDPI display mode controller.

`xkdpi` is a resident AppKit application for listing connected displays,
detecting HiDPI modes, switching display modes, and restoring saved settings at
login.

## Requirements

- macOS 13 or later
- Xcode or Xcode Command Line Tools
- Swift 6 compatible toolchain

## Install from Source

This project does not currently provide a Homebrew package. Build and install it
from this repository:

```bash
git clone https://github.com/Masa-Ryu/xkdpi.git
cd xkdpi
./scripts/install.sh
```

The installer performs a release build, creates `xkdpi.app` and `xkdpi.dmg`,
copies `xkdpi.app` to `/Applications/xkdpi.app`, and registers the LaunchAgent
for login startup.

If `/Applications/xkdpi.app` already exists, the installer asks before
overwriting it. If copying to `/Applications` requires administrator
permissions, it retries with `sudo`.

## Manual Build

```bash
swift build -c release
./scripts/build_dmg.sh
```

After running the DMG script, copy `xkdpi.app` to `/Applications` manually if
you do not want to use `scripts/install.sh`.

## Development

```bash
swift build
swift run
swift test
swift test --filter DisplayManagerTests
```

## Login Startup

`scripts/install.sh` registers login startup automatically. To register it
again manually:

```bash
./scripts/setup_launch_agent.sh
```

The LaunchAgent is written to:

```text
~/Library/LaunchAgents/com.xkdpi.displaycontroller.plist
```

## Uninstall

```bash
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.xkdpi.displaycontroller.plist 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.xkdpi.displaycontroller.plist
rm -rf /Applications/xkdpi.app
```
