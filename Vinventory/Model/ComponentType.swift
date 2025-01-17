//
//  Type.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 2.07.2024.
//

import Foundation

struct ComponentType: Codable, Identifiable {
    let id: Int?
    var name: String
    var attributes: [String]
}

extension ComponentType {
  static let types: [ComponentType] = [
    .init(id: 1, name: "Type1", attributes: ["1", "2"]),
    .init(id: 2, name: "Type2", attributes: ["1", "2"]),
    .init(id: 3, name: "Type3", attributes: ["1", "2"])
  ]
}
