import SwiftUI

struct CreateComponentTypeView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var name: String = ""
  @State private var selectedAttributes: [String] = []
  @State private var isAttributesSheetPresented = false
  @State var componentTypeVM: ComponentTypeViewModel

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Type Name")) {
          TextField("Name", text: $name)
        }
        Section(header: Text("Attributes")) {
          ForEach(selectedAttributes, id: \.self) { attribute in
            Text(formatAttribute(attribute))
              .onTapGesture {
                if let index = selectedAttributes.firstIndex(where: { $0.lowercased() == attribute.lowercased() }) {
                  selectedAttributes.remove(at: index)
                }
              }
          }
          Button("Add Attributes") {
            isAttributesSheetPresented = true
          }
        }
        Section {
          HStack {
            Button("Save") {
              Task {
                // Yeni bir ComponentType oluşturun
                let newType = ComponentType(id: nil, name: name, attributes: getFilteredAttributes())
                do {
                  try await componentTypeVM.createType(type: newType)
                  dismiss()
                  try await componentTypeVM.getTypesList()
                } catch {
                  // Hata işleme
                  print("Failed to create type: \(error)")
                }
              }
            }
            .disabled(name.isEmpty)
          }
        }
      }
      .navigationTitle("Create Component Type")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar(content: {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            componentTypeVM.isCreateTypesViewPresented = false
          } label: {
            Image(systemName: "xmark")
          }
        }
      })
      .sheet(isPresented: $isAttributesSheetPresented) {
        AttributesSheetView(selectedAttributes: $selectedAttributes, didTapDone: {
          isAttributesSheetPresented = false
        })
      }
    }
  }

  private func formatAttribute(_ attribute: String) -> String {
    switch attribute.lowercased() {
    case "serialnumber":
      return "Serial Number"
    case "model":
      return "Model"
    case "warrantyenddate":
      return "Warranty End Date"
    case "modelyear":
      return "Model Year"
    case "screensize":
      return "Screen Size"
    case "condition":
      return "Condition"
    case "brand":
      return "Brand"
    case "resolution":
      return "Resolution"
    case "processortype":
      return "Processor Type"
    case "processorcores":
      return "Processor Cores"
    case "ram":
      return "RAM"
    default:
      return attribute.capitalized
    }
  }

  private func getFilteredAttributes() -> [String] {
    var attributes = selectedAttributes.map { $0.lowercased() }
    // Varsayılan özellikleri kaldır
    attributes.removeAll { attribute in
      ["serialnumber", "warrantyenddate"].contains(attribute)
    }
    // Özellikleri benzersiz yap ve formatla
    return Array(Set(attributes)).compactMap { lowercased in
      formatAttribute(lowercased)
    }
  }
}



