//
//  InventoryClient.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 12.07.2024.
//

import Foundation

protocol ComponentProtocol {
  func getComponents(filters: ComponentFilter, sorts: ComponentSort)        async throws -> [Component]
  func createComponent(componentRequest: ComponentRequest)                  async throws
  func editComponent(component: Component, for id: Int)                     async throws -> Component
  func getSpesificComponent(for id: Int)                                    async throws -> Component
  func searchComponent(for searchText: String)                              async throws -> [Component]
  func getComponentHistory(for id: Int)                                     async throws -> [InventoryHistory]
  func assignComponentToUser(inventoryHistory: InventoryHistory)            async throws
  func getComponentsLastInteractant(for id: Int)                            async throws -> ADDUserWithStatus
}

extension HTTPClient: ComponentProtocol {
  func getComponents(filters: ComponentFilter, sorts: ComponentSort) async throws -> [Component] {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/components",
                                        httpMethod: .get,
                                        queryParameters: [
                                          "status": filters.status,
                                          "brand": filters.brand,
                                          "type_id": filters.typeId,
                                          "model_year": filters.modelYear,
                                          "screen_size": filters.screenSize,
                                          "processor_Type": filters.processorType,
                                          "processor_cores": filters.processorCores,
                                          "ram": filters.ram,
                                          "condition": filters.condition,
                                          "sort": sorts.rawValue,
                                          "order": "desc"
                                        ])
    return try await processRequest(urlRequest: urlRequest, returningType: [Component].self)
  }
  func createComponent(componentRequest: ComponentRequest) async throws {
    do {
      let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                          path: "/components",
                                          httpMethod: .post,
                                          with: componentRequest)
      _ = try await processRequest(urlRequest: urlRequest,
                               returningType: ComponentRequest.self)
    }
  }
  func editComponent(component: Component, for id: Int) async throws -> Component {
    do {
      let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                          path: "/components/\(id)",
                                          httpMethod: .put,
                                          with: component)
      let response = try await processRequest(urlRequest: urlRequest, returningType: Component.self)
      return response
    } catch {
      print("Error editing component: \(error)")
      throw error
    }
  }

  func getSpesificComponent(for id: Int) async throws -> Component {
    do {
      let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                          path: "/components/\(id)",
                                          httpMethod: .get)
      let component = try await processRequest(urlRequest: urlRequest, returningType: Component.self)
      print(component)
      return component
    }
  }

  func activateComponent(component: Component, for id: Int) async throws {
    do {
      let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                          path: "/components/\(id)/active/\(AppEnvironment.shared.currentUser!.id)",
                                          httpMethod: .put,
                                          with: component)
      try await processRequest(urlRequest: urlRequest)
    } catch {

    }
  }

  func deactivateComponent(for id: Int) async throws {
    do {
      let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                          path: "/components/\(id)/deactivate/\(AppEnvironment.shared.currentUser!.id)",
                                          httpMethod: .put)
      try await processRequest(urlRequest: urlRequest)
    }
  }

  func searchComponent(for searchText: String) async throws -> [Component] {
    do {
      let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                          path: "/components",
                                          httpMethod: .get,
                                          queryParameters: ["search": searchText])
      let response = try await processRequest(urlRequest: urlRequest, returningType: [Component].self)
      return response
    } catch {
      print("Error searching for searchText: \(error)")
      throw error
    }
  }
  func getComponentHistory(for id: Int) async throws -> [InventoryHistory] {
    do {
      let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                          path: "/components/\(id)/inventory-history",
                                          httpMethod: .get)
      let inventoryHistory = try await processRequest(urlRequest: urlRequest, returningType: [InventoryHistory].self)
      print("Inventory history: \(inventoryHistory)")
      return inventoryHistory
    } catch {
      throw error
    }
  }

  func assignComponentToUser(inventoryHistory: InventoryHistory) async throws {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/inventory-history",
                                        httpMethod: .post, with: inventoryHistory)
    _ = try await processRequest(urlRequest: urlRequest, returningType: InventoryHistory.self)
  }
  func getComponentsLastInteractant(for id: Int) async throws -> ADDUserWithStatus {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/components/\(id)/last-interactant",
                                        httpMethod: .get)
    return try await processRequest(urlRequest: urlRequest, returningType: ADDUserWithStatus.self)
  }

  func getFilterAttributesString(for attribute: String) async throws -> FilterAttributesString {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/components/\(attribute)/uniquevalue",
                                        httpMethod: .get)
    return try await processRequest(urlRequest: urlRequest, returningType: FilterAttributesString.self)
  }
  
  func getFilterAttributesInt(for attribute: String) async throws -> FilterAttributesInt {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/components/\(attribute)/uniquevalue",
                                        httpMethod: .get)
    return try await processRequest(urlRequest: urlRequest, returningType: FilterAttributesInt.self)
  }
}

struct ComponentFilter: Equatable {
    var status: String
    var brand: String
    var typeId: String
    var modelYear: String
    var screenSize: String
    var processorType: String
    var processorCores: String
    var ram: String
    var condition: String

    static func ==(lhs: ComponentFilter, rhs: ComponentFilter) -> Bool {
        return lhs.status == rhs.status &&
               lhs.brand == rhs.brand &&
               lhs.typeId == rhs.typeId &&
               lhs.modelYear == rhs.modelYear &&
               lhs.screenSize == rhs.screenSize &&
               lhs.processorType == rhs.processorType &&
               lhs.processorCores == rhs.processorCores &&
               lhs.ram == rhs.ram &&
               lhs.condition == rhs.condition
    }
}

enum ComponentSort: String, CaseIterable {
  case none = ""
  case status
  case modelYear = "model_year"
  case processorCores = "processor_cores"
  case ram
}
