//
//  InventoryHistory.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 21.07.2024.
//

import Foundation

struct InventoryHistory: Codable {
  let componentID: Int
  let createdAt: String?
  let id: Int
  let operationType, userID: String

  enum CodingKeys: String, CodingKey {
    case componentID = "componentId"
    case createdAt, id, operationType
    case userID = "userId"
  }
}
