// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let welcome = try? JSONDecoder().decode(Welcome.self, from: jsonData)

import Foundation

struct Component: Codable {
  var id: Int?
  var status, brand, model: String
  var modelYear, typeID: Int
  var screenSize, resolution, processorType: String
  var processorCores, ram: Int
  var warrantyEndDate: Date
  var serialNumber, condition, notes: String

  enum CodingKeys: String, CodingKey {
    case id, status, brand, model, modelYear
    case typeID = "typeId"
    case screenSize, resolution, processorType, processorCores, ram, warrantyEndDate, serialNumber, condition, notes
  }
}

extension Component {
  static let components: [Component] = [
    .init(id: nil, status: "", brand: "", model: "", modelYear: 0,
          typeID: 0, screenSize: "", resolution: "", processorType: "",
          processorCores: 0, ram: 0, warrantyEndDate: Date(), serialNumber: "", condition: "", notes: "")
  ]
}

struct ComponentRequest: Codable {
    let component: Component
}
