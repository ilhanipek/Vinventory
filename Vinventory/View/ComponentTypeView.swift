import SwiftUI

struct ComponentTypeView: View {
  @State private var isTypesDetailViewPresented = false
  @State private var componentTypeVM = ComponentTypeViewModel()
  var body: some View {
    NavigationStack {
      VStack {
        List {
          ForEach(componentTypeVM.typesList, id: \.id) { type in
            Button {
              componentTypeVM.type = type
              componentTypeVM.selectedAttributes = type.attributes
              isTypesDetailViewPresented = true
            } label: {
              HStack {
                Text(type.name)
                Spacer()
                Image(systemName: "chevron.right")
                  .foregroundStyle(Color.blue)
              }
          }
            .buttonStyle(.plain)            }

        }
        .navigationTitle("Types")
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
              componentTypeVM.isCreateTypesViewPresented = true
            }) {
              Image(systemName: "plus")
            }
          }
        }
      }
      .fullScreenCover(isPresented: $componentTypeVM.isCreateTypesViewPresented) {
        CreateComponentTypeView(componentTypeVM: componentTypeVM)
      }
      .onAppear {
        Task {
          do {
            try await componentTypeVM.getTypesList()
          } catch {
            print("Can't get types list")
          }
        }
      }
      .navigationDestination(isPresented: $isTypesDetailViewPresented) {
        ComponentTypeDetailView(componentTypeVM: componentTypeVM)
      }
    }
  }
}

@Observable class ComponentTypeViewModel {
  var typesList: [ComponentType] = []
  var type = ComponentType.types.first!
  var name = ""
  var selectedAttributes: [String] = []
  var isDetailViewPresented = false
  var isCreateTypesViewPresented = false
  var isAlertPresented = false
  let client = HTTPClient()

  func getTypesList() async throws {
    self.typesList = try await client.getTypes()
  }

  func editTypes(type: ComponentType) async throws {
    self.type = try await client.editTypes(componentType: type, for: type.id!)
  }

  func deleteTypes(type: ComponentType) async {
    do {
      try await client.deleteTypes(for: type.id!)
    } catch {
      isAlertPresented = true
    }
  }

  func createType(type: ComponentType) async throws {
    do {
      _ = try await client.createTypes(type: type)
    } catch {
      print("Can't create component")
    }
  }
}

#Preview {
  ComponentTypeView()
}
