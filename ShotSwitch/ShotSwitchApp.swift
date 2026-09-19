//
//  ShotSwitchApp.swift
//  ShotSwitch
//

import SwiftUI

@main
struct ShotSwitchApp: App {
    @StateObject private var store = ScreenshotFormatStore()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(store: store)
        } label: {
            Label(store.current.menuTitle, systemImage: "camera.viewfinder")
                .labelStyle(.titleAndIcon)
        }
    }
}
