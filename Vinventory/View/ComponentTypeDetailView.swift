import SwiftUI

struct ComponentTypeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isAttributesSheetPresented = false
    @State private var selectedAttributes: [String] = []
    @State var componentTypeVM: ComponentTypeViewModel

    var body: some View {
        Form {
            Section(header: Text("Type Name")) {
                TextField("Name", text: $componentTypeVM.type.name)
            }
            Section(header: Text("Attributes")) {
                ForEach(selectedAttributes, id: \.self) { attribute in
                    HStack {
                        Text(formatAttribute(attribute))
                        Spacer()
                        Image(systemName: "trash")
                            .foregroundStyle(Color.red)
                            .onTapGesture {
                                if let index = selectedAttributes.firstIndex(where: { $0.lowercased() == attribute.lowercased() }) {
                                    selectedAttributes.remove(at: index)
                                }
                            }
                    }
                }
                Button("Add Attributes") {
                    isAttributesSheetPresented = true
                }
            }
            Section("Delete Component Type") {
                HStack {
                    Button("Delete", role: .destructive, action: {
                        Task {
                            do {
                                try await componentTypeVM.deleteTypes(type: componentTypeVM.type)
                                dismiss() // Ekranı kapat
                            } catch {
                                print("Failed to delete type")
                                // Hata işleme
                            }
                        }
                    })
                }
            }
        }
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task {
                        componentTypeVM.type.attributes = getSelectedAttributes()
                        let camelCaseAttributes = componentTypeVM.type.attributes.map { attribute in
                            attribute.split(separator: " ").enumerated().map { index, element in
                                index == 0 ? element.lowercased() : element.capitalized
                            }.joined()
                        }
                        try await componentTypeVM.editTypes(type: ComponentType(id: componentTypeVM.type.id, name: componentTypeVM.type.name, attributes: camelCaseAttributes))
                    }
                }
                .disabled(componentTypeVM.type.name.isEmpty)
            }
        })
        .navigationTitle(componentTypeVM.type.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAttributesSheetPresented) {
            AttributesSheetView(selectedAttributes: $selectedAttributes, didTapDone: {
                isAttributesSheetPresented = false
            })
        }
        .onAppear {
            selectedAttributes = componentTypeVM.type.attributes.map { formatAttribute($0) }
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

    private func getSelectedAttributes() -> [String] {
        var attributes = selectedAttributes.map { $0.lowercased() }
        if !attributes.contains("serial number") {
            attributes.append("serial number")
        }
        if !attributes.contains("warranty end date") {
            attributes.append("warranty end date")
        }
        return Array(Set(attributes)).compactMap { lowercased in
            formatAttribute(lowercased)
        }
    }
}

struct AttributesSheetView: View {
    @Binding var selectedAttributes: [String]
    var didTapDone: (() -> Void)

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredAttributes(), id: \.self) { attribute in
                    MultipleSelectionRow(title: attribute,
                                         isSelected: selectedAttributes.map {
                        $0.lowercased()
                    }.contains(attribute.lowercased())) {
                        toggleSelection(attribute)
                    }
                }
            }
            .navigationTitle("Select Attributes")
            .navigationBarItems(trailing: Button("Done") {
                didTapDone()
            })
        }
    }

    private func toggleSelection(_ attribute: String) {
        let lowercasedAttribute = attribute.lowercased()
        if selectedAttributes.map({ $0.lowercased() }).contains(lowercasedAttribute) {
            selectedAttributes.removeAll { $0.lowercased() == lowercasedAttribute }
        } else {
            selectedAttributes.append(attribute)
        }
    }

    private func filteredAttributes() -> [String] {
        let allAttributes = [
            "Brand", "Model", "Model Year", "Screen Size", "Resolution",
            "Processor Type", "Processor Cores", "RAM", "Serial Number", "Condition"
        ]

        let existingAttributes = Set(selectedAttributes.map { $0.lowercased() })
        return allAttributes.filter { !existingAttributes.contains($0.lowercased()) }
    }
}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: "plus")
                .foregroundStyle(Color.blue)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
