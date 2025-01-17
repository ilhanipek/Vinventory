import SwiftUI

struct UsersView: View {
  @State private var userVM = UserViewModel()
  @State private var isLoading = true
  @State private var isLoadingImages = true
  @State private var isUserDetailViewPresented = false
  @State private var isGettingHistory = false

  var body: some View {
    NavigationStack {
      VStack {
        List {
          ForEach(userVM.userList, id: \.id) { user in
            Button {
              userVM.selectedUserId = user.id
              isUserDetailViewPresented = true
            } label: {
              HStack {
                if isLoadingImages {
                  ProgressView()
                    .frame(width: 50, height: 50)
                } else if let photo = userVM.userPhotos[user.id] {
                  AsyncImage(url: URL(string: photo.photoURL)) { image in
                    image
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(width: 50, height: 50)
                      .clipShape(Circle())
                  } placeholder: {
                    Image(systemName: "photo")
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(width: 50, height: 50)
                      .clipShape(Circle())
                      .foregroundColor(.gray)
                  }
                } else {
                  Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
                }
                HStack {
                  VStack(alignment: .leading) {
                    Text(user.displayName)
                    Text(user.email)
                  }
                  Spacer()
                  Image(systemName: "chevron.right")
                }
              }
              .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
          }
        }
        .overlay(alignment: .center) {
          if isGettingHistory {
            ProgressView()
          }
        }
      }
      .navigationTitle("Users")
      .navigationBarTitleDisplayMode(.large)
      .onAppear {
        Task {
          await userVM.getUsers()
          isLoadingImages = false
        }
      }
      .navigationDestination(isPresented: $isUserDetailViewPresented) {
        UserDetailView(userVM: userVM, userId: userVM.selectedUserId ?? "0")
      }

    }
  }
}

@Observable
class UserViewModel {
  var userList: [User] = []
  var userPhotos: [String: Photo] = [:]
  var selectedUserId: String?
  private var isFetched = false

  let client = HTTPClient()

  func getUsers() async {
    guard !isFetched else { return }

    do {
      self.userList = try await client.getAllUsers()
      await loadUserPhotos()
      isFetched = true
      dump(userList)
    } catch {
      print(error)
    }
  }

  private func loadUserPhotos() async {
    await withTaskGroup(of: (String, Photo?).self) { group in
      for user in userList {
        group.addTask {
          do {
            let photo = try await self.client.getUsersPhoto(for: user.id)
            return (user.id, photo)
          } catch {
            print("Error fetching photo for user \(user.id): \(error)")
            return (user.id, nil)
          }
        }
      }

      for await (userId, photo) in group {
        if let photo = photo {
          self.userPhotos[userId] = photo
        }
      }
    }
  }

  func getUserHistory(for userId: String) async throws -> [InventoryHistory] {
    do {
      return try await client.getUsersInventoryHistory(for: userId)
    } catch {
      print(error)
      throw error
    }
  }

  func getSpecificComponent(for id: Int) async throws -> Component {
    let urlRequest = try client.makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                               path: "/components/\(id)",
                                               httpMethod: .get)
    return try await client.processRequest(urlRequest: urlRequest, returningType: Component.self)
  }

  func getADDUser(for id: String) async throws -> User {
    let urlRequest = try client.makeUrlRequest(baseUrl: URL(string: baseUrl)!,
                                               path: "/auth/users/\(id)",
                                               httpMethod: .get)
    return try await client.processRequest(urlRequest: urlRequest, returningType: User.self)
  }

  func resetUserHistory() {
    
  }
}
