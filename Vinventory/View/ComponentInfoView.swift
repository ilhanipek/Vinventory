import SwiftUI

struct ComponentInfoView: View {
    @State var componentVM: ComponentViewModel

    var body: some View {
        NavigationView {
            VStack {
                if let componentHistory = componentVM.componentHistory,
                   let addUserList = componentVM.addUserList,
                   componentHistory.count == addUserList.count {
                    List {
                        ForEach(componentHistory.indices, id: \.self) { index in
                            let history = componentHistory[index]
                            let user = addUserList[index]

                            VStack(alignment: .leading) {
                                Text("User Name: \(user.displayName)")
                                    .font(.headline)
                                Text("Operation Type: \(history.operationType)")
                                    .font(.headline)
                                if let createdAtDate = history.createdAt,
                                   let date = date(from: createdAtDate) {
                                    Text("Created At: \(formattedDate(from: date))")
                                        .font(.subheadline)
                                } else {
                                    Text("Created At: Unknown")
                                        .font(.subheadline)
                                }
                                Divider()
                            }
                            .padding()
                        }
                    }
                } else {
                    Text("No history available.")
                        .padding()
                }
            }
            .navigationTitle("Component History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withFractionalSeconds, .withTimeZone]
        return formatter
    }()

    private func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func date(from string: String) -> Date? {
        // Handling fractional seconds with a custom DateFormatter for this specific format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX"
        return formatter.date(from: string) ?? isoDateFormatter.date(from: string)
    }
}
