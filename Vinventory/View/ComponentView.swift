import SwiftUI

struct ComponentView: View {
  @State var componentVM = ComponentViewModel()
  @State private var isComponentCreateViewPresented = false
  @State private var isComponentDetailViewPresented = false
  @State private var isLoading = false
  @State private var expandedComponentID: Int?
  @State private var isFilterSheetPresented = false
  @State private var isSortingMenuPresented = false
  @State private var isFiltersApplied = false

  var body: some View {
    NavigationStack {
      VStack {
        HStack {
          Button(action: {
            isFilterSheetPresented = true
          }) {
            Label("Filter", systemImage: "line.horizontal.3.decrease.circle")
              .padding(.horizontal)
              .padding(.vertical, 5)
              .foregroundColor(isFiltersApplied ? .white : .blue)
              .background {
                Capsule().fill(isFiltersApplied ? Color.blue : .clear)
              }
              .padding(.horizontal)
          }
          Spacer()
          Menu {
            if componentVM.sorts != .none {
              Button {
                componentVM.sorts = .none
                Task {
                  await componentVM.applyFiltersAndSort()
                }
              } label: {
                HStack {
                  Text("Remove Sort")
                  Image(systemName: "xmark.circle.fill")
                }
                .foregroundColor(.white)
                .background(Color.red)
                .cornerRadius(5)
              }
            }
            ForEach(ComponentSort.allCases.filter { $0 != .none }, id: \.self) { sortOption in
              let sortOptionCamelCased = sortOption.rawValue
                .replacingOccurrences(of: "_", with: " ")
                .capitalizedWords()
              Button(sortOptionCamelCased) {
                componentVM.sorts = sortOption
                Task {
                  await componentVM.applyFiltersAndSort()
                }
              }
            }
          } label: {
            Label(sortLabel(), systemImage: "arrow.up.arrow.down")
              .padding(.horizontal)
              .padding(.vertical, 5)
              .foregroundColor(componentVM.sorts != .none ? .white : .blue)
              .background {
                Capsule().fill(componentVM.sorts != .none ? Color.blue : .clear)
              }
              .padding(.horizontal)
          }
        }
        .fullScreenCover(isPresented: $isFilterSheetPresented) {
          FilterSheetView(filters: $componentVM.filters, componentVM: $componentVM, applyFilters: {
            isFiltersApplied = componentVM.filters != componentVM.savedFilters
            isFilterSheetPresented = false
            Task {
              await componentVM.applyFiltersAndSort()
            }
          }, resetFilters: {
            componentVM.filters = ComponentFilter(status: "",
                                                  brand: "",
                                                  typeId: "",
                                                  modelYear: "",
                                                  screenSize: "",
                                                  processorType: "",
                                                  processorCores: "",
                                                  ram: "",
                                                  condition: "")
            isFiltersApplied = false
            isFilterSheetPresented = false
            Task {
              await componentVM.applyFiltersAndSort()
            }
          }, didTapCancel: {
            isFilterSheetPresented = false
          })
        }

        List {
          ForEach(componentVM.componentList, id: \.id) { component in
            VStack(alignment: .leading) {
              HStack {
                Text("\(component.brand) \(component.model)")
                Spacer()
                if componentVM.sorts != .none {
                  Text(sortValue(for: component))
                    .foregroundColor(.gray)
                    .font(.caption)
                    .padding(.trailing, 10)
                }
                Button {
                  expandedComponentID = (expandedComponentID == component.id) ? nil : component.id
                } label: {
                  Image(systemName: expandedComponentID == component.id ? "chevron.up" : "chevron.down")
                }
              }
              .contentShape(Rectangle())
              .onTapGesture {
                expandedComponentID = (expandedComponentID == component.id) ? nil : component.id
              }
              if expandedComponentID == component.id {
                VStack {
                  Divider()
                  HStack {
                    statusView(for: component.status)
                    conditionView(for: component.condition)
                    Spacer()
                    Button {
                      expandedComponentID = nil
                      componentVM.component = component
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {

                        if componentVM.component.status == "Out of Inventory" {
                          componentVM.selectedUser.componentStatus = "Out of Inventory"
                        }
                        Task {
                          isLoading = true
                          try await componentVM.getComponentsLastInteractant(for: component.id!)
                          componentVM.condition = component.condition
                          await componentVM.getSpesificType(for: component.typeID)
                          isLoading = false
                          isComponentDetailViewPresented = true
                        }
                      }
                    } label: {
                      Image(systemName: "info.circle")
                        .padding(.leading, 10)
                    }
                  }
                  .padding(.top, 10)
                }
              }
            }
            .padding(.vertical, 5)
          }
        }
        .searchable(text: $componentVM.searchText)
        .overlay {
          if isLoading {
            ProgressView()
          }
        }
      }
      .environment(componentVM)
      .navigationBarTitle("Components", displayMode: .automatic)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            isComponentCreateViewPresented = true
          } label: {
            Image(systemName: "plus")
          }
        }
      }
      .onChange(of: componentVM.searchText) { _, _ in
        Task {
          await componentVM.searchComponents(searchText: componentVM.searchText)
        }
      }
      .onAppear {
        isLoading = true
        Task {
          await componentVM.getComponentsList()
          isLoading = false
        }
      }
      .navigationDestination(isPresented: $isComponentDetailViewPresented) {
        ComponentDetailView(componentVM: componentVM)
      }
      .fullScreenCover(isPresented: $isComponentCreateViewPresented, onDismiss: {
        isLoading = true
        Task {
          await componentVM.getComponentsList()
          isLoading = false
        }
      }, content: {
        CreateComponentView()
      })
    }
  }

  private func sortLabel() -> String {
    if componentVM.sorts == .none {
      return "Sort by..."
    } else {
      return sortLabel(for: componentVM.sorts)
    }
  }

  private func sortLabel(for sortOption: ComponentSort) -> String {
    let sortOptionCamelCased = sortOption.rawValue
      .replacingOccurrences(of: "_", with: " ")
      .capitalizedWords()
    return sortOptionCamelCased
  }

  private func statusColor(for status: String) -> Color {
    switch status {
    case "Ready to Use":
      return Color.green
    case "Being Used":
      return Color.yellow
    case "Out of Inventory":
      return Color.gray
    default:
      return Color.gray
    }
  }

  private func conditionColor(for condition: String) -> Color {
    switch condition {
    case "Functioning":
      return Color.blue
    case "Slightly Damaged":
      return Color.orange
    case "Broken":
      return Color.red
    default:
      return Color.gray
    }
  }

  private func statusView(for status: String) -> some View {
    RoundedRectangle(cornerRadius: 5)
      .stroke(lineWidth: 1)
      .foregroundStyle(statusColor(for: status))
      .frame(height: 20)
      .frame(maxWidth: 120)
      .overlay(
        Text(status)
          .foregroundColor(statusColor(for: status))
          .font(.caption)
      )
      .padding(.trailing, 5)
  }

  private func conditionView(for condition: String) -> some View {
    RoundedRectangle(cornerRadius: 5)
      .stroke(lineWidth: 1)
      .foregroundStyle(conditionColor(for: condition))
      .frame(height: 20)
      .frame(maxWidth: 120)
      .overlay(
        Text(condition)
          .foregroundStyle(conditionColor(for: condition))
          .font(.caption)
      )
      .padding(.trailing, 10)
  }

  private func sortValue(for component: Component) -> String {
    switch componentVM.sorts {
    case .status:
      return component.status
    case .modelYear:
      return "\(component.modelYear)"
    case .processorCores:
      return "\(component.processorCores)"
    case .ram:
      return "\(component.ram)"
    case .none:
      return ""
    }
  }
}

struct FilterSheetView: View {
    @Binding var filters: ComponentFilter
    @Binding var componentVM: ComponentViewModel
    var applyFilters: () -> Void
    var resetFilters: () -> Void
    var didTapCancel: () -> Void

    @State private var status = ""
    @State private var brand = ""
    @State private var typeId = ""
    @State private var modelYear = ""
    @State private var screenSize = ""
    @State private var processorType = ""
    @State private var processorCores = ""
    @State private var ram = ""
    @State private var condition = ""

    @State private var isFilterDetailViewPresented = false
    @State private var currentFilterType: String?
    @State private var filterAttributesString: FilterAttributesString = []
    @State private var filterAttributesInt: FilterAttributesInt = []
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Filters")) {
                    Button("Status: \(status.isEmpty ? "" : status)") {
                        currentFilterType = "status"
                        fetchFilterAttributesString(for: "status")
                    }
                    Button("Brand: \(brand.isEmpty ? "" : brand)") {
                        currentFilterType = "brand"
                        fetchFilterAttributesString(for: "brand")
                    }
                    Button("Screen Size: \(screenSize.isEmpty ? "" : screenSize)") {
                        currentFilterType = "screenSize"
                        fetchFilterAttributesString(for: "screen_size")
                    }
                    Button("Processor Type: \(processorType.isEmpty ? "" : processorType)") {
                        currentFilterType = "processorType"
                        fetchFilterAttributesString(for: "processor_type")
                    }
                    Button("Condition: \(condition.isEmpty ? "" : condition)") {
                        currentFilterType = "condition"
                        fetchFilterAttributesString(for: "condition")
                    }
                }
                if filters != ComponentFilter(status: "", brand: "", typeId: "", modelYear: "", screenSize: "", processorType: "", processorCores: "", ram: "", condition: "") {
                    Section {
                        Button("Reset Filters") {
                            resetFilters()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Filter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        didTapCancel()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        filters = ComponentFilter(
                            status: status,
                            brand: brand,
                            typeId: typeId,
                            modelYear: modelYear,
                            screenSize: screenSize,
                            processorType: processorType,
                            processorCores: processorCores,
                            ram: ram,
                            condition: condition
                        )
                        applyFilters()
                    }) {
                        Text("Apply")
                    }
                }
            }
            .onAppear {
                status = filters.status
                brand = filters.brand
                typeId = filters.typeId
                modelYear = filters.modelYear
                screenSize = filters.screenSize
                processorType = filters.processorType
                processorCores = filters.processorCores
                ram = filters.ram
                condition = filters.condition
            }
            .sheet(isPresented: $isFilterDetailViewPresented) {
              FilterDetailView(selectedFilterType: currentFilterType ?? "", filterAttributes: $filterAttributesString, isFilterDetailViewPresented: $isFilterDetailViewPresented) { selectedAttribute in
                    updateFilter(with: selectedAttribute)
                }
            }
        }
    }

    private func fetchFilterAttributesString(for attribute: String) {
        Task {
            do {
                filterAttributesString = try await componentVM.getFilterAttributesString(for: attribute)
                isFilterDetailViewPresented = true
            } catch {
                print("Failed to fetch filter attributes")
            }
        }
    }
  private func fetchFilterAttributesInt(for attribute: String) {
      Task {
          do {
              filterAttributesInt = try await componentVM.getFilterAttributesInt(for: attribute)
              isFilterDetailViewPresented = true
          } catch {
              print("Failed to fetch filter attributes")
          }
      }
  }

    private func updateFilter(with selectedAttribute: String) {
        guard let filterType = currentFilterType else { return }
        switch filterType {
        case "status":
            status = selectedAttribute
        case "brand":
            brand = selectedAttribute
        case "typeId":
            typeId = selectedAttribute
        case "modelYear":
            modelYear = selectedAttribute
        case "screenSize":
            screenSize = selectedAttribute
        case "processorType":
            processorType = selectedAttribute
        case "processorCores":
            processorCores = selectedAttribute
        case "ram":
            ram = selectedAttribute
        case "condition":
            condition = selectedAttribute
        default:
            break
        }
        isFilterDetailViewPresented = false
    }
}

struct FilterDetailView: View {
    var selectedFilterType: String
    @Binding var filterAttributes: FilterAttributesString
    @Binding var isFilterDetailViewPresented: Bool
    var onSelectAttribute: (String) -> Void

    var body: some View {
        NavigationStack {
            List(filterAttributes, id: \.self) { attribute in
                Button(attribute) {
                    onSelectAttribute(attribute)
                }
            }
            .navigationTitle("Select \(selectedFilterType.capitalized)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                      isFilterDetailViewPresented = false
                    }
                }
            }
        }
    }
}

@Observable class ComponentViewModel {
  // View
  var searchText = ""
  // Create Component View
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
  var condition = ""
  var notes = ""
  var status = ""
  var requiredFields: [String] = []
  var typesList: [ComponentType] = []
  var selectedTypes: ComponentType?
  // Functions
  var componentList: [Component] = []
  let client = HTTPClient()
  var component = Component.components.first!
  var type = ComponentType.types.first!
  var userList: [User] = []
  var componentHistory: [InventoryHistory]?
  var addUserList: [User]?
  var savedFilters = ComponentFilter(status: "",
                                     brand: "",
                                     typeId: "",
                                     modelYear: "",
                                     screenSize: "",
                                     processorType: "",
                                     processorCores: "",
                                     ram: "",
                                     condition: "")
  var filters = ComponentFilter(status: "",
                                brand: "",
                                typeId: "",
                                modelYear: "",
                                screenSize: "",
                                processorType: "",
                                processorCores: "",
                                ram: "",
                                condition: "")
  var filterAttributes: FilterAttributesString = []
  var sorts: ComponentSort = .none
  var isComponentInfoViewPresented = false
  var selectedUser: ADDUserWithStatus = .init(componentStatus: "Ready to Use",
                                              lastInteractantUser: .init(displayName: "",
                                                                         email: "",
                                                                         firstName: "",
                                                                         id: "",
                                                                         lastName: ""))

  enum Condition: String, CaseIterable {
    case functioning = "Functioning"
    case slightlyDamaged = "Slightly damaged"
    case broken = "Broken"
  }

  var modelYearString: String {
    get {
      return component.modelYear == 0 ? "" : "\(component.modelYear)"
    }
    set {
      if let year = Int(newValue) {

        component.modelYear = year
      }
    }
  }

  var processorCoresString: String {
    get {
      return component.processorCores == 0 ? "" : "\(component.processorCores)"
    }
    set {
      if let processorCores = Int(newValue) {
        component.modelYear = processorCores
      }
    }
  }

  var ramString: String {
    get {
      return component.ram == 0 ? "" : "\(component.ram)"
    }
    set {
      if let ram = Int(newValue) {
        component.ram = ram
      }
    }
  }

  func getComponentsList() async {
    do {
      self.componentList = try await client.getComponents(filters: filters, sorts: sorts)
    } catch {

      print("Can't get components")
    }
  }
  func applyFiltersAndSort() async {
    self.savedFilters = filters
    await getComponentsList()
  }

  func getSpesificType(for id: Int) async {
    do {
      self.type = try await client.getType(for: id)
    } catch {
      print("Can't get specific type")
    }
  }

  func getTypesList() async throws {
    self.typesList = try await client.getTypes()
  }

  func editComponent(component: Component) async {
    do {
      _ = try await client.editComponent(component: component, for: component.id!)
    } catch {
      print("Can't edit component")
    }
  }

  func activateComponent(component: Component, for id: Int) async {
      do {
        try await client.activateComponent(component: component, for: id)
        print("Component activated successfully")
      } catch {
        print("Error activating component: \(error)")
      }
    }

    func deactiveComponent(component: Component, for id: Int) async {
      do {
        try await client.deactivateComponent(for: id)
        print("Component deactivated successfully")
      } catch {
        print("Error deactivating component: \(error)")
      }
    }

  func searchComponents(searchText: String) async -> [Component] {
    let searchedComponents = try? await client.searchComponent(for: searchText)
    self.componentList = searchedComponents ?? []
    return searchedComponents ?? []
  }

  func changeComponentForUser(inventoryHistory: InventoryHistory) async {
    _ = try? await client.assignComponentToUser(inventoryHistory: inventoryHistory)
  }

  func getUsers() async {
    do {
      self.userList = try await client.getAllUsers()
    } catch {
      print("Can't get users")
    }
  }

  func getComponentHistory(for id: Int) async throws {
    self.componentHistory = try await client.getComponentHistory(for: id)

    print("Component History succesful")
  }

  func getComponentHistoryForDetail(for id: Int) async throws -> String {
    let componentHistory = try await client.getComponentHistory(for: id)
    return componentHistory.last!.operationType
  }

  func getAADUsersFromHistory() async throws {
    guard let historyList = componentHistory else { return }
    self.addUserList = []
    for history in historyList {
      if let addUser = try? await client.getADDUser(for: history.userID) {
        print("Getting Users")
        self.addUserList?.append(addUser)
      }
    }
  }

  func getComponentsLastInteractant(for id: Int) async throws {
    let selectedUser = try await client.getComponentsLastInteractant(for: id)
    if try await getComponentHistoryForDetail(for: component.id!) != "Added" {
      if selectedUser.componentStatus == "Being Used" {
        self.selectedUser = selectedUser
      } else {
        self.selectedUser = ADDUserWithStatus(componentStatus: "Ready to Use",
                                              lastInteractantUser: .init(displayName: "",
                                                                         email: "",
                                                                         firstName: "",
                                                                         id: "",
                                                                         lastName: ""))
      }
    }
  }
  func assignComponentToUser(inventoryHistory: InventoryHistory) async throws {
    do {
      let assignedInventoryHistory = try await client.assignComponentToUser(inventoryHistory: inventoryHistory)
      print("Component assigned to user successfully: \(assignedInventoryHistory)")
    } catch {
      print("Error assigning component to user: \(error)")
    }
  }
  func getHistoryAndUsers(for id: Int) async {
    do {
      try await getComponentHistory(for: id)
      try await getAADUsersFromHistory()
    } catch {
      print("Failed to get history or users")
    }
  }
  func getFilterAttributesString(for attribute: String) async throws -> FilterAttributesString {
    return try await client.getFilterAttributesString(for: attribute)
  }
  func getFilterAttributesInt(for attribute: String) async throws -> FilterAttributesInt {
    return try await client.getFilterAttributesInt(for: attribute)
  }
}
