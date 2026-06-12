import AppKit

// Manually start the NSApplication main loop.
// @NSApplicationMain is not available for SPM executable targets.
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

app.activate(ignoringOtherApps: true)
app.run()
