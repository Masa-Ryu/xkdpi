import AppKit

// NSApplication のメインループを手動起動
// @NSApplicationMain は SPM executable target では使用不可のため手動起動
let app = NSApplication.shared
app.setActivationPolicy(.regular)

let delegate = AppDelegate()
app.delegate = delegate

app.activate(ignoringOtherApps: true)
app.run()
