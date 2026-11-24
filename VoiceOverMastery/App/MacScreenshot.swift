import SwiftUI

#if os(macOS)
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Sets the window to an App Store screenshot size and writes a PNG, then quits.
/// Used only when `-VoiceOverMasteryScreenshotPath` is passed on the command line.
enum MacScreenshot {
    static func captureIfRequested() {
        guard let path = ScreenshotLaunch.outputPath else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            capture(to: path)
        }
    }

    private static func capture(to path: String) {
        guard let window = NSApplication.shared.windows.first(where: { $0.isVisible && $0.canBecomeKey })
                ?? NSApplication.shared.windows.first else {
            NSApp.terminate(nil)
            return
        }
        let width: CGFloat = 1280
        let height: CGFloat = 800
        if let screen = window.screen ?? NSScreen.main {
            let originY = screen.frame.maxY - height
            window.setFrame(NSRect(x: screen.frame.minX, y: originY, width: width, height: height), display: true, animate: false)
        } else {
            window.setFrame(NSRect(x: 0, y: 0, width: width, height: height), display: true, animate: false)
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let url = URL(fileURLWithPath: path)
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !writeViewSnapshot(of: window, to: url) {
                _ = writeWindowListImage(of: window, to: url)
            }
            NSApp.terminate(nil)
        }
    }

    /// Captures the window's own views, including the title bar, without a screen-recording permission.
    @discardableResult
    private static func writeViewSnapshot(of window: NSWindow, to url: URL) -> Bool {
        guard let view = window.contentView?.superview ?? window.contentView else { return false }
        let bounds = view.bounds
        guard let rep = view.bitmapImageRepForCachingDisplay(in: bounds) else { return false }
        view.cacheDisplay(in: bounds, to: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else { return false }
        do {
            try data.write(to: url)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    private static func writeWindowListImage(of window: NSWindow, to url: URL) -> Bool {
        let windowID = CGWindowID(window.windowNumber)
        guard let image = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else { return false }
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            return false
        }
        CGImageDestinationAddImage(dest, image, nil)
        return CGImageDestinationFinalize(dest)
    }
}
#endif
