import SwiftUI

struct ComponentDetailView: View {
  @State var componentVM: ComponentViewModel
  @State private var isTypeSelectSheetPresented = false
  @State private var showAlert = false
  @State private var alertMessage = ""
  @State private var selectedDate: Date = Date()
  @State private var isUserSelectSheetPresented = false
  @State private var isAssignButton = true
  @State private var isGettingComponentHistory = false
  @State private var isOutOfInventory = false

  var body: some View {
    VStack {
      Form {
        Section(header: Text("Type")) {
          Button(action: {
            isTypeSelectSheetPresented = true
          }) {
            HStack {
              Text(componentVM.type.name)
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
            TypeSelectionSheetViewDetail(isPresented: $isTypeSelectSheetPresented, componentVM: componentVM)
          }
        }

        Section(header: Text("User Assignment")) {
          HStack {
            Text(componentVM.selectedUser.lastInteractantUser.displayName == "" ? "Select User" : "\(componentVM.selectedUser.lastInteractantUser.displayName)")
              .foregroundColor(componentVM.selectedUser.lastInteractantUser.displayName == "" ? .blue : .black)
              .onTapGesture {
                if isAssignButton {
                  isUserSelectSheetPresented = true
                }
              }
            Spacer()
            Button(action: {
              Task {
                if isAssignButton {
                  print("Assigning")
                  print(isAssignButton)
                  await assignUser(user: componentVM.selectedUser.lastInteractantUser)
                  isAssignButton.toggle()
                  print(isAssignButton)
                  print("Assigned")
                } else {
                  print("Returning")
                  print(isAssignButton)
                  await returnUser()
                  isAssignButton.toggle()
                  print(isAssignButton)
                  print("Returned")
                }
              }
            }) {
              Text(isAssignButton ? "Assign" : "Return")
                .foregroundStyle(componentVM.selectedUser.lastInteractantUser.displayName == "" ? .gray : .blue)
                .foregroundColor(.blue)
            }
            .disabled(componentVM.selectedUser.lastInteractantUser.displayName == "")
          }

          .sheet(isPresented: $isUserSelectSheetPresented) {
            UserSelectionSheet(isPresented: $isUserSelectSheetPresented, selectedUser: $componentVM.selectedUser)
          }
        }

        Section(header: Text("Component Details")) {
          Menu {
            ForEach(CreateComponentView.ViewModel.Condition.allCases, id: \.self) { condition in
              Button(action: {
                componentVM.condition = condition.rawValue
              }) {
                Text(condition.rawValue)
              }
            }
          } label: {
            HStack(alignment: .center) {
              Text("Condition: \(componentVM.condition)")
                .foregroundColor(.blue)
              Spacer()
              Image(systemName: "chevron.down")
            }
          }
          if componentVM.selectedUser.componentStatus == "Being Used" {
            Text("Component Status: \(componentVM.selectedUser.componentStatus)")
              .foregroundColor(.black)
              .padding(.top, 5)
          } else {
            if componentVM.component.status == "Out of Inventory" {
              Menu(componentVM.component.status) {
                if componentVM.component.status == "Ready to Use" {
                  Button("Out of Inventory") {
                    componentVM.component.status = "Out of Inventory"
                  }
                } else if componentVM.component.status == "Out of Inventory"{
                  Button("Ready to Use") {
                    componentVM.component.status = "Ready to Use"
                  }
                }
              }
            } else {
              Menu(componentVM.selectedUser.componentStatus) {
                if componentVM.selectedUser.componentStatus == "Ready to Use" {
                  Button("Out of Inventory") {
                    componentVM.selectedUser.componentStatus = "Out of Inventory"
                  }
                } else if componentVM.selectedUser.componentStatus == "Out of Inventory"{
                  Button("Ready to Use") {
                    componentVM.selectedUser.componentStatus = "Ready to Use"
                  }
                }
              }
            }
          }
          CustomTextField2(title: "Brand", text: $componentVM.component.brand, isRequired: componentVM.requiredFields.contains("brand"))
          CustomTextField2(title: "Model", text: $componentVM.component.model, isRequired: componentVM.requiredFields.contains("model"))
          CustomTextField2(title: "Model Year", text: $componentVM.modelYearString, isRequired: componentVM.requiredFields.contains("modelYear"))
            .keyboardType(.numberPad)
          CustomTextField2(title: "Screen Size", text: $componentVM.component.screenSize, isRequired: componentVM.requiredFields.contains("screenSize"))
            .keyboardType(.numberPad)
          CustomTextField2(title: "Resolution", text: $componentVM.component.resolution, isRequired: componentVM.requiredFields.contains("resolution"))
          CustomTextField2(title: "Processor Type", text: $componentVM.component.processorType, isRequired: componentVM.requiredFields.contains("processorType"))
          CustomTextField2(title: "Processor Cores", text: $componentVM.processorCoresString, isRequired: componentVM.requiredFields.contains("processorCores"))
            .keyboardType(.numberPad)
          CustomTextField2(title: "RAM", text: $componentVM.ramString, isRequired: componentVM.requiredFields.contains("ram"))
            .keyboardType(.numberPad)
          CustomTextField2(title: "Serial Number", text: $componentVM.component.serialNumber, isRequired: componentVM.requiredFields.contains("serialNumber"))
          DatePicker("Warranty End Date", selection: $selectedDate, displayedComponents: .date)
          CustomTextField2(title: "Notes", text: $componentVM.component.notes, isRequired: false)
        }
      }
      .navigationTitle(componentVM.component.brand)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") {
            if checkRequiredFields() {
              Task {
                componentVM.component.condition = componentVM.condition
                componentVM.component.typeID = componentVM.type.id!
                componentVM.component.warrantyEndDate = selectedDate

                if componentVM.selectedUser.componentStatus == "Out of Inventory" {
                  componentVM.component.status = "Out of Inventory"
                } else if componentVM.selectedUser.componentStatus == "Ready to Use" {
                  componentVM.component.status = "Ready to Use"
                }
                await componentVM.editComponent(component: componentVM.component)
              }
            } else {
              showAlert = true
            }
          }
          .buttonBorderShape(.capsule)
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            isGettingComponentHistory = true
            Task {
              await componentVM.getHistoryAndUsers(for: componentVM.component.id!)
              isGettingComponentHistory = false
              componentVM.isComponentInfoViewPresented = true
            }
          } label: {
            Image(systemName: "info.circle")
          }
        }
      }
      .alert(isPresented: $showAlert) {
        Alert(title: Text("Alert"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
      }
    }
    .overlay {
      if isGettingComponentHistory {
        ProgressView()
      }
    }
    .onAppear {
      Task {
        await componentVM.getSpesificType(for: componentVM.component.id!)
        selectedDate = componentVM.component.warrantyEndDate ?? Date()
        await getComponentStatus()
      }
    }
    .sheet(isPresented: $componentVM.isComponentInfoViewPresented, content: {
      ComponentInfoView(componentVM: componentVM)
    })
  }

  private func checkRequiredFields() -> Bool {
    var missingFields = [String]()

    func checkField(_ field: String, _ value: String, _ displayName: String) {
      if value.isEmpty { missingFields.append(displayName) }
    }

    for field in componentVM.requiredFields {
      switch field {
      case "status":
        checkField(field, componentVM.component.status, "Status")
      case "brand":
        checkField(field, componentVM.component.brand, "Brand")
      case "model":
        checkField(field, componentVM.component.model, "Model")
      case "modelYear":
        checkField(field, "\(componentVM.component.modelYear)", "Model Year")
      case "screenSize":
        checkField(field, componentVM.component.screenSize, "Screen Size")
      case "resolution":
        checkField(field, componentVM.component.resolution, "Resolution")
      case "processorType":
        checkField(field, componentVM.component.processorType, "Processor Type")
      case "processorCores":
        checkField(field, "\(componentVM.component.processorCores)", "Processor Cores")
      case "ram":
        checkField(field, "\(componentVM.component.ram)", "RAM")
      case "serialNumber":
        checkField(field, componentVM.component.serialNumber, "Serial Number")
      case "condition":
        checkField(field, componentVM.component.condition, "Condition")
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

  private func getComponentStatus() async {
    do {
      try await componentVM.getComponentsLastInteractant(for: componentVM.component.id!)
      if componentVM.component.status == "Being Used" {
        componentVM.selectedUser = ADDUserWithStatus(componentStatus: componentVM.component.status,
                                                     lastInteractantUser: componentVM.selectedUser.lastInteractantUser)
        isAssignButton = false
      } else {
        isAssignButton = true
      }
    } catch {
      print("Error getting component status: \(error)")
    }
  }

  private func assignUser(user: User) async {
    do {
      let inventoryHistory = InventoryHistory(componentID: componentVM.component.id!,
                                              createdAt: nil,
                                              id: 0,
                                              operationType: "Assigned",
                                              userID: user.id)
      try await componentVM.assignComponentToUser(inventoryHistory: inventoryHistory)
      componentVM.selectedUser.componentStatus = "Being Used"
      print("User assigned successfully")
    } catch {
      print("Error assigning user: \(error)")
    }
  }

  private func returnUser() async {
    do {
      let inventoryHistory = InventoryHistory(componentID: componentVM.component.id!,
                                              createdAt: nil,
                                              id: 0,
                                              operationType: "Returned",
                                              userID: componentVM.selectedUser.lastInteractantUser.id)
      try await componentVM.assignComponentToUser(inventoryHistory: inventoryHistory)
      componentVM.selectedUser.componentStatus = "Ready to Use"
      componentVM.selectedUser.lastInteractantUser.displayName = ""
      print("User returned successfully")
    } catch {
      print("Error returning user: \(error)")
    }
  }
}

struct UserSelectionSheet: View {
  @Binding var isPresented: Bool
  @Binding var selectedUser: ADDUserWithStatus
  @State private var userVM = UserViewModel()
  @State private var isLoading = false

  var body: some View {
    NavigationView {
      List(userVM.userList) { user in
        Button(action: {
          selectedUser = ADDUserWithStatus(componentStatus: "Ready to Use", lastInteractantUser: user)
          isPresented = false
        }) {
          Text(user.displayName)
        }
      }
      .overlay {
        if isLoading {
          ProgressView()
        }
      }
      .navigationTitle("Select User")
      .navigationBarItems(trailing: Button("Cancel") {
        isPresented = false
      })
      .onAppear {
        isLoading = true
        Task {
          await userVM.getUsers()
          isLoading = false
        }
      }
    }
  }
}

struct TypeSelectionSheetViewDetail: View {
  @Binding var isPresented: Bool
  @State var componentVM: ComponentViewModel

  var body: some View {
    List(componentVM.typesList, id: \.id) { type in
      Button(action: {
        componentVM.type = type
        componentVM.requiredFields = type.attributes
        isPresented = false
      }) {
        Text(type.name)
          .foregroundColor(.blue)
      }
    }
    .navigationTitle("Select Type")
    .navigationBarItems(trailing: Button("Done") {
      isPresented = false
    })
    .task {
      try? await componentVM.getTypesList()
    }
  }
}

struct CustomTextField2: View {
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

enum ComponentStatus: String {
  case readyToUse = "Ready to Use"
  case outOfInventory = "Out of Inventory"
}
