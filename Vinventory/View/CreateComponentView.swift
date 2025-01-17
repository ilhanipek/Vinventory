import SwiftUI

struct CreateComponentView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) var colorScheme
  @State private var createComponentVM = ViewModel()
  @State private var selectedDate: Date = Date()
  @State private var isTypeSelectSheetPresented = false
  @State private var showAlert = false
  @State private var alertMessage = ""
  var body: some View {
    NavigationView {
      VStack {
        VStack(alignment: .leading, spacing: 16) {
          Button(action: {
            isTypeSelectSheetPresented = true
          }) {
            HStack {
              Text(createComponentVM.selectedTypes?.name ?? "Select a type..")
                .foregroundColor(.blue)
              Spacer()
              Image(systemName: "chevron.down")
                .foregroundColor(.blue)
            }
            .padding()
            .overlay(
              RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue, lineWidth: 2)
            )
          }
          .sheet(isPresented: $isTypeSelectSheetPresented) {
            TypeSelectionSheetView(isPresented: $isTypeSelectSheetPresented, createComponentVM: createComponentVM)
          }
          List {
            Section(header: Text("Component Details")) {
              Menu {
                ForEach(CreateComponentView.ViewModel.Condition.allCases, id: \.self) { condition in
                  Button(action: {
                    createComponentVM.condition = condition
                  }) {
                    Text(condition.rawValue)
                  }
                }
              } label: {
                HStack(alignment: .center) {
                  Text("Condition: \(createComponentVM.condition.rawValue)")
                    .foregroundColor(createComponentVM.selectedTypes == nil ? colorScheme == .light ? .black : .white : .blue)
                  Spacer()
                  Image(systemName: "chevron.down")
                }
              }

              CustomTextField(title: "Brand",
                              text: $createComponentVM.brand,
                              isRequired: createComponentVM.requiredFields.contains("brand"))
              CustomTextField(title: "Model",
                              text: $createComponentVM.model,
                              isRequired: createComponentVM.requiredFields.contains("model"))
              CustomTextField(title: "Model Year",
                              text: $createComponentVM.modelYear,
                              isRequired: createComponentVM.requiredFields.contains("modelYear"))
              .keyboardType(.numberPad)
              CustomTextField(title: "Screen Size",
                              text: $createComponentVM.screenSize,
                              isRequired: createComponentVM.requiredFields.contains("screenSize"))
              .keyboardType(.numberPad)
              CustomTextField(title: "Processor Type",
                              text: $createComponentVM.processorType,
                              isRequired: createComponentVM.requiredFields.contains("processorType"))
              CustomTextField(title: "Processor Cores",
                              text: $createComponentVM.processorCores,
                              isRequired: createComponentVM.requiredFields.contains("processorCores"))
              .keyboardType(.numberPad)
              CustomTextField(title: "RAM",
                              text: $createComponentVM.ram,
                              isRequired: createComponentVM.requiredFields.contains("ram"))
              .keyboardType(.numberPad)
              CustomTextField(title: "Serial Number",
                              text: $createComponentVM.serialNumber,
                              isRequired: createComponentVM.requiredFields.contains("serialNumber"))
              DatePicker("Warranty End Date",
                         selection: $selectedDate,
                         displayedComponents: .date)
              CustomTextField(title: "Notes", text: $createComponentVM.notes, isRequired: false)
            }
          }

          .disabled(createComponentVM.selectedTypes == nil)
        }
        .padding()

        Spacer()
        HStack {
          Spacer()
          Button(action: {
            if checkRequiredFields() && createComponentVM.selectedTypes != nil {
              Task {
                do {
                  try await createComponentVM.createComponent(componentRequest: ComponentRequest(component: Component(
                    id: nil,
                    status: "",
                    brand: createComponentVM.brand,
                    model: createComponentVM.model,
                    modelYear: Int(createComponentVM.modelYear) ?? 0,
                    typeID: createComponentVM.selectedTypes!.id!,
                    screenSize: createComponentVM.screenSize,
                    resolution: createComponentVM.resolution,
                    processorType: createComponentVM.processorType,
                    processorCores: Int(createComponentVM.processorCores) ?? 0,
                    ram: Int(createComponentVM.ram) ?? 0,
                    warrantyEndDate: selectedDate,
                    serialNumber: createComponentVM.serialNumber,
                    condition: createComponentVM.condition.rawValue,
                    notes: createComponentVM.notes
                  )))
                  dismiss()
                } catch {
                  print("Failed to create component: \(error)")
                }
              }
            } else {
              showAlert = true
            }
          }) {
            Text("Create")
              .padding()
              .frame(maxWidth: .infinity)
              .background(Color.blue)
              .foregroundColor(.white)
              .cornerRadius(10)
          }
          .padding()
        }
      }
      .navigationTitle("Create Component")
      .toolbar(content: {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }

        }
      })
      .alert(isPresented: $showAlert) {
        Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
      }
    }
  }

  private func checkRequiredFields() -> Bool {
    var missingFields = [String]()

    func checkField(_ field: String, _ value: String, _ displayName: String) {
      if value.isEmpty { missingFields.append(displayName) }
    }

    for field in createComponentVM.requiredFields {
      switch field {
      case "status":
        checkField(field, createComponentVM.status, "Status")
      case "brand":
        checkField(field, createComponentVM.brand, "Brand")
      case "model":
        checkField(field, createComponentVM.model, "Model")
      case "modelYear":
        checkField(field, createComponentVM.modelYear, "Model Year")
      case "screenSize":
        checkField(field, createComponentVM.screenSize, "Screen Size")
      case "resolution":
        checkField(field, createComponentVM.resolution, "Resolution")
      case "processorType":
        checkField(field, createComponentVM.processorType, "Processor Type")
      case "processorCores":
        checkField(field, createComponentVM.processorCores, "Processor Cores")
      case "ram":
        checkField(field, createComponentVM.ram, "RAM")
      case "serialNumber":
        checkField(field, createComponentVM.serialNumber, "Serial Number")
      case "condition":
        checkField(field, createComponentVM.condition.rawValue, "Condition")
      default:
        break
      }
    }

    if !missingFields.isEmpty {
      alertMessage = "Please fill in the following fields: \(missingFields.joined(separator: ", "))"
      return false
    }
    return true
  }
}

extension CreateComponentView {
  @Observable
  class ViewModel {
    enum Condition: String, CaseIterable {
      case functioning = "Functioning"
      case slightlyDamaged = "Slightly Damaged"
      case broken = "Broken"
    }

    var id = 0
    var brand = ""
    var model = ""
    var modelYear = ""
    var screenSize = ""
    var resolution = ""
    var processorType = ""
    var processorCores = ""
    var ram = ""
    var serialNumber = ""
    var condition: Condition = .functioning
    var notes = ""
    var status = ""
    var requiredFields: [String] = []
    var typesList: [ComponentType] = []
    var selectedTypes: ComponentType?
    let client = HTTPClient()

    func createComponent(componentRequest: ComponentRequest) async throws {
      do {
        let response = try await client.createComponent(componentRequest: componentRequest)
        print("Component request: \(response)")
      } catch {
        print("Can't create component")
      }
    }

    func getTypesList() async throws {
      self.typesList = try await client.getTypes()
    }
  }
}

struct TypeSelectionSheetView: View {
  @Binding var isPresented: Bool
  @State var createComponentVM: CreateComponentView.ViewModel

  var body: some View {
    List(createComponentVM.typesList, id: \.id) { types in
      Button(action: {
        createComponentVM.selectedTypes = types
        createComponentVM.requiredFields = types.attributes
        isPresented = false
      }) {
        Text(types.name)
          .foregroundColor(.blue)
      }
    }
    .navigationTitle("Select Type")
    .navigationBarItems(trailing: Button("Done") {
      isPresented = false
    })

    .task {
      try? await createComponentVM.getTypesList()
    }
  }
}

struct CustomTextField: View {
  var title: String
  @Binding var text: String
  var isRequired: Bool

  var body: some View {
    HStack {
      Text("\(title):")
        .fontWeight(.regular)
        .overlay(
          Text("*")
            .foregroundColor(.red)
            .offset(x: 6, y: -5)
            .opacity(isRequired ? 1 : 0),
          alignment: .trailing
        )
      TextField("", text: $text)
    }
  }
}
