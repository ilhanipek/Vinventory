import SwiftUI

struct UserDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @State var userVM: UserViewModel
  @State private var details: [(InventoryHistory?, Component?, User?)] = []
  @State private var isLoading = false
  @State var userId: String

  var body: some View {
    VStack {
      if isLoading {
        ProgressView("Loading...")
          .progressViewStyle(CircularProgressViewStyle())
      } else {
        if details.isEmpty {
          VStack(spacing: 4) {
            Text("No User History")
            Image(systemName: "archivebox")
              .resizable()
              .frame(width: 70, height: 70, alignment: .center)
          }
          .padding(.top, 70)
        } else {
          List {
            ForEach(details, id: \.0?.id) { detail in
              if let history = detail.0,
                 let component = detail.1,
                 let user = detail.2 {
                DetailViewCell(
                  email: user.email,
                  createdAt: date(from: history.createdAt!) ?? Date(),
                  operationType: history.operationType,
                  brand: component.brand,
                  model: component.model
                )
              }
            }
          }
          .listRowSpacing(20)
        }
      }
    }
    .padding(.top, 40)
    .onAppear {
      loadDetails()
    }
    .navigationBarBackButtonHidden()
    .navigationTitle("User Device History")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        Button(action: {
          dismiss()
        }) {
          Image(systemName: "chevron.left")
            .foregroundColor(.blue)
        }
      }
    }
  }

  private func loadDetails() {
    print("Getting History")
      Task {
          isLoading = true
          defer { isLoading = false }
          do {
            print(userId)
              let userHistory = try await userVM.getUserHistory(for: userId)
              dump(userHistory)
              var tempDetails: [(InventoryHistory?, Component?, User?)] = []
              for history in userHistory {
                  do {
                      let component = try await userVM.getSpecificComponent(for: history.componentID)
                      let user = try await userVM.getADDUser(for: history.userID)
                      tempDetails.append((history, component, user))
                  } catch {
                      print("Error fetching component or user: \(error)")
                  }
              }
              details = tempDetails
          } catch {
              print("Failed to load user history: \(error)")
          }
      }
  }

  private func date(from string: String?) -> Date? {
      guard let string = string else { return nil }
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX"
      return formatter.date(from: string)
  }
}

struct DetailViewCell: View {
  let email: String
  let createdAt: Date
  let operationType: String
  let brand: String
  let model: String

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Brand:")
          .font(.headline)
        Text(brand)
          .font(.subheadline)
      }
      HStack {
        Text("Model:")
          .font(.headline)
        Text(model)
          .font(.subheadline)
      }
      HStack {
        Text("Operation:")
          .font(.headline)
        Text(operationType)
          .font(.subheadline)
      }
      HStack {
        Text("Created At:")
          .font(.headline)
        Text(formattedDate(createdAt))
          .font(.subheadline)
      }
    }
  }

  private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
