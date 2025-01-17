//
//  VinventoryApp.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 1.07.2024.
//

import SwiftUI

@main
struct VinventoryApp: App {
  @State private var mainVM = AppEnvironment.shared
    var body: some Scene {
        WindowGroup {
            ZStack {
              Color.Custom.white
                .ignoresSafeArea()
              MainView()
                .environment(mainVM)
            }
        }
    }
}
