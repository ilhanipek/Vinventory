//
//  UserClient.swift
//  Vinventory
//
//  Created by ilhan serhan ipek on 21.07.2024.
//

import Foundation

protocol UserClient {
  func getCurrentUser() async throws
  func getAllUsers() async throws -> [User]
  func createUser(user: User) async throws
  func getADDUser(for id: String) async throws -> User
  func getUsersInventoryHistory(for id: String) async throws -> [InventoryHistory]
}

extension HTTPClient: UserClient {
  func getCurrentUser() async throws {
    let urlRequest = try makeUrlRequestWithAccessToken(baseUrl: URL(string: currentUserBaseUrl)!,
                                                       path: nil)
    let fetchedCurrentUser = try await processRequest(urlRequest: urlRequest,
                                                                        returningType: CurrentUserModel.self)
    AppEnvironment.shared.currentUser = fetchedCurrentUser
  }
  func getAllUsers() async throws -> [User] {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/auth/users",
                                        httpMethod: .post)
    return try await processRequest(urlRequest: urlRequest, returningType: [User].self)
  }
  func createUser(user: User) async throws {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/users",
                                        httpMethod: .post,
                                        with: user)
    _ = try await processRequest(urlRequest: urlRequest, returningType: [User].self)
  }
  func getADDUser(for id: String) async throws -> User {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/auth/users/\(id)",
                                        httpMethod: .get)
    return try await processRequest(urlRequest: urlRequest, returningType: User.self)
  }
  func getUsersPhoto(for id: String) async throws -> Photo {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/auth/users/\(id)/photo",
                                        httpMethod: .get)
    return try await processRequest(urlRequest: urlRequest, returningType: Photo.self)
  }
  func getUsersInventoryHistory(for id: String) async throws -> [InventoryHistory] {
    let urlRequest = try makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                        path: "/users/\(id)/inventory-history",
                                        httpMethod: .get)
    return try await processRequest(urlRequest: urlRequest, returningType: [InventoryHistory].self)
  }
}
