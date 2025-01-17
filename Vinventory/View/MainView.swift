//  MainView.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 2.07.2024.
//

import SwiftUI

struct MainView: View {
  @Environment(AppEnvironment.self) private var appEnvironment

    var body: some View {
        if appEnvironment.idToken != nil {
            ZStack {
                WelcomeView()
            }
        } else {
            TabView {
                ComponentView()
                    .tabItem {
                        Label("Components", systemImage: "house.fill")
                    }
                ComponentTypeView()
                    .tabItem {
                        Label("Types", systemImage: "t.square.fill")
                    }
                UsersView()
                    .tabItem {
                        Label("Users", systemImage: "person.fill")
                    }
            }

        }
    }
}

#Preview {
    MainView()
}
