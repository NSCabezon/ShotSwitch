//
//  MenuContent.swift
//  ScreenshotFormat
//

import SwiftUI

struct MenuContent: View {
    @ObservedObject var store: ScreenshotFormatStore

    var body: some View {
        Text("Formato actual: \(store.current.menuTitle)")

        Button(store.current == .heic ? "Cambiar a PNG (compatible)" : "Cambiar a HEIC (Apple)") {
            store.toggleHEICPNG()
        }
        .keyboardShortcut("t")

        Divider()

        Picker("Formato", selection: Binding(
            get: { store.current },
            set: { store.set($0) }
        )) {
            ForEach(ScreenshotFormat.allCases) { format in
                Text(format.displayName).tag(format)
            }
        }
        .pickerStyle(.inline)

        Divider()

        Toggle("Capturar en HDR (solo HEIC)", isOn: Binding(
            get: { store.captureHDR },
            set: { store.setCaptureHDR($0) }
        ))
        .disabled(!store.current.supportsHDR)

        Toggle("Abrir al iniciar sesión", isOn: Binding(
            get: { store.launchAtLogin },
            set: { store.setLaunchAtLogin($0) }
        ))

        Button("Salir") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
