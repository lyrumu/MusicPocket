import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    let launchBackground = isDark
      ? NSColor(srgbRed: 23 / 255, green: 22 / 255, blue: 20 / 255, alpha: 1)
      : NSColor(srgbRed: 238 / 255, green: 236 / 255, blue: 230 / 255, alpha: 1)
    backgroundColor = launchBackground
    flutterViewController.backgroundColor = launchBackground
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
