//
//  ScreenshotFormatStore.swift
//  ScreenshotFormat
//

import Foundation
import Combine
import ServiceManagement

/// Formats accepted by the `type` key of `com.apple.screencapture`.
enum ScreenshotFormat: String, CaseIterable, Identifiable {
    case heic, png, jpg, pdf, tiff, gif, bmp

    var id: String { rawValue }

    /// Short text shown in the menu bar next to the icon.
    var menuTitle: String { rawValue.uppercased() }

    /// Only HEIC can store an HDR screenshot. With `captureHDR` on and any
    /// other format, macOS fails with "Error al escribir los datos de imagen".
    var supportsHDR: Bool { self == .heic }

    var displayName: String {
        switch self {
        case .heic: return "HEIC (solo Apple, más pequeño)"
        case .png:  return "PNG (universal, sin pérdida)"
        case .jpg:  return "JPG (universal, con pérdida)"
        case .pdf:  return "PDF"
        case .tiff: return "TIFF"
        case .gif:  return "GIF"
        case .bmp:  return "BMP"
        }
    }
}

@MainActor
final class ScreenshotFormatStore: ObservableObject {
    @Published private(set) var current: ScreenshotFormat
    @Published private(set) var captureHDR: Bool
    @Published private(set) var launchAtLogin: Bool

    private static let domain = "com.apple.screencapture"
    private static let typeKey = "type"
    private static let hdrKey = "captureHDR"
    /// Our own memory of whether the user wants HDR when the format allows it.
    private static let wantsHDRKey = "wantsHDR"

    private let system = UserDefaults(suiteName: ScreenshotFormatStore.domain)
    private let own = UserDefaults.standard

    init() {
        current = .png
        captureHDR = false
        launchAtLogin = SMAppService.mainApp.status == .enabled
        refresh()
        // First launch: remember the HDR setting the user already had.
        if own.object(forKey: Self.wantsHDRKey) == nil {
            own.set(captureHDR, forKey: Self.wantsHDRKey)
        }
        // Repair an inherited broken state (HDR on with a non-HEIC format).
        if captureHDR && !current.supportsHDR {
            set(current)
        }
    }

    /// Re-read the system preference (it can be changed from Terminal too).
    func refresh() {
        let raw = system?.string(forKey: Self.typeKey)?.lowercased() ?? "png"
        current = ScreenshotFormat(rawValue: raw == "jpeg" ? "jpg" : raw) ?? .png
        captureHDR = system?.bool(forKey: Self.hdrKey) ?? false
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func set(_ format: ScreenshotFormat) {
        system?.set(format.rawValue, forKey: Self.typeKey)
        // HDR only works with HEIC; otherwise every screenshot fails to save.
        let hdr = format.supportsHDR && own.bool(forKey: Self.wantsHDRKey)
        system?.set(hdr, forKey: Self.hdrKey)
        system?.synchronize()
        current = format
        captureHDR = hdr
    }

    /// Quick switch between the two formats that matter day to day.
    func toggleHEICPNG() {
        set(current == .heic ? .png : .heic)
    }

    func setCaptureHDR(_ enabled: Bool) {
        own.set(enabled, forKey: Self.wantsHDRKey)
        let hdr = enabled && current.supportsHDR
        system?.set(hdr, forKey: Self.hdrKey)
        system?.synchronize()
        captureHDR = hdr
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Launch at login failed: \(error)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
