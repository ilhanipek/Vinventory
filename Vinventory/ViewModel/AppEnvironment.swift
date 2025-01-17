//
//  MainViewModel.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 2.07.2024.
//

import Foundation
import SwiftUI

enum SelectedTab {
    case inventory
    case types
    case users
}

@Observable
class AppEnvironment {
    var path = NavigationPath()
    var currentUser: CurrentUserModel?
    var idToken: String?
    var accessToken: String?

    static let shared = AppEnvironment()

    private init() {}
}
