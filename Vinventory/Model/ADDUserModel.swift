//
//  LastInteractant.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 24.07.2024.
//

import Foundation

struct ADDUserWithStatus: Codable {
  var componentStatus: String
  var lastInteractantUser: User
}

struct User: Codable, Identifiable {
  var displayName, email: String
  let firstName: String?
  let id: String
  let lastName: String?
}
