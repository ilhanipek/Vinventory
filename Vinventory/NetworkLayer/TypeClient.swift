//
//  TypeClient.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 12.07.2024.
//

import Foundation

protocol TypesProtocol {
  func getTypes() async throws -> [ComponentType]
  func getType(for id: Int) async throws -> ComponentType
  func createTypes(type: ComponentType) async throws -> ComponentType
  func editTypes(componentType: ComponentType, for id: Int) async throws -> ComponentType
  func searchTypes(for searchText: String) async throws -> [ComponentType]
  func deleteTypes(for id: Int) async throws
}

extension HTTPClient: TypesProtocol {
  func getTypes() async throws -> [ComponentType] {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/types",
                                        httpMethod: .get)
    return try await processRequest(urlRequest: urlRequest, returningType: [ComponentType].self)
  }

  func getType(for id: Int) async throws -> ComponentType {

    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/types/\(id)",
                                        httpMethod: .get)
    return try await processRequest(urlRequest: urlRequest, returningType: ComponentType.self)
  }
  func createTypes(type: ComponentType) async throws -> ComponentType {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/types",
                                        httpMethod: .post,
                                        with: type)
    return try await processRequest(urlRequest: urlRequest, returningType: ComponentType.self)
  }

  func editTypes(componentType: ComponentType, for id: Int) async throws -> ComponentType {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/types/\(id)",
                                        httpMethod: .put,
                                        with: componentType)
    return try await processRequest(urlRequest: urlRequest, returningType: ComponentType.self)
  }

  func searchTypes(for searchText: String) async throws -> [ComponentType] {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/types",
                                        httpMethod: .get,
                                        queryParameters: ["search": searchText])
    return try await processRequest(urlRequest: urlRequest, returningType: [ComponentType].self)
  }

  func deleteTypes(for id: Int) async throws {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/types/\(id)",
                                        httpMethod: .delete)
    _ = try await processRequest(urlRequest: urlRequest, returningType: ComponentType.self)
  }
}
