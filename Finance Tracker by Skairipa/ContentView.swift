//
//  ContentView.swift
//  Finance Tracker by: Skairipa
//
//  Created by Hanna Skairipa on 5/31/23.
//

import SwiftUI
import CloudKit

struct ContentView: View {
    @State private var isAddingAccount = false
    @State private var isEditingAccount = false
    @State private var selectedAccount: Account? = nil
    @State private var editedAccount: Account? = nil
    @State private var accounts: [Account] = [] // Initialize with empty accounts
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Finance Tracker").font(.largeTitle).fontWeight(.bold)
                    Spacer()
                    addButton
                }
                .padding(.horizontal, 30.0)
                
                AccountListView(accounts: $accounts, selectedAccount: $selectedAccount, isEditingAccount: $isEditingAccount)
                //                .navigationBarTitle("Finance Tracker")
                //                .navigationBarItems(trailing: addButton)
            }
        }
        .sheet(isPresented: $isAddingAccount) {
            AddAccountView(isPresented: $isAddingAccount, accounts: $accounts)
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity) // Updated the frame modifier
        }
        .sheet(isPresented: $isEditingAccount) {
                EditAccountView(isPresented: $isEditingAccount, selectedAccount: $selectedAccount, accounts: $accounts, editedAccount: $editedAccount)
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxWidth: .infinity)
                    .onDisappear {
                        // This will be triggered when the sheet is dismissed
                        selectedAccount = nil
                        editedAccount = nil
                }
            }

//                .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
//                .zIndex(1000)
//                .environment(\.colorScheme, .dark) // Force dark mode for the sheet
//        }
        .onAppear {
            loadAccounts()
        }
    }
    
    private func makeEditAccountView() -> some View {
        return EditAccountView(isPresented: $isEditingAccount, selectedAccount: $selectedAccount, accounts: $accounts, editedAccount: $editedAccount)
    }
    
    private func loadAccounts() {
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase

        let recordID = CKRecord.ID(recordName: "AccountsRecord")
        privateDatabase.fetch(withRecordID: recordID) { (record, error) in
            if let error = error {
                print("Failed to fetch accounts from CloudKit: \(error)")
                return
            }

            guard let accountsAsset = record?["accounts"] as? CKAsset else {
                print("Failed to retrieve accounts from CloudKit")
                return
            }

            guard let fileURL = accountsAsset.fileURL else {
                print("Failed to retrieve file URL for accounts asset")
                return
            }

            do {
                let encodedAccounts = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                accounts = try decoder.decode([Account].self, from: encodedAccounts)
            } catch {
                print("Failed to decode accounts: \(error)")
            }
        }
    }

    private var addButton: some View {
        Button(action: {
            isAddingAccount = true
        }) {
            Image(systemName: "plus")
//                .renderingMode(.original)
                .foregroundColor(.blue)
                .padding(.top, 7.0)
                .font(.title2)
                .bold()
        }
    }
}

struct AccountListView: View {
    @Binding var accounts: [Account]
    @Binding var selectedAccount: Account?
    @Binding var isEditingAccount: Bool
    var onDelete: ((IndexSet) -> Void)?

    var body: some View {
        List {
            ForEach(Array(accounts.enumerated()), id: \.1.id) { index, account in
                AccountRowView(account: $accounts[index], selectedAccount: $selectedAccount, isEditingAccount: $isEditingAccount, accounts: $accounts)
                    .onTapGesture {
                        selectedAccount = account
                    }
            }
            .onDelete(perform: onDelete)
        }
        .listStyle(PlainListStyle())
    }
}

//struct AccountRowView: View {
//    @Binding var account: Account
//
//    var body: some View {
//        // Existing code...
//
//        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//            Button(action: {
//                // Perform action when the delete button is tapped
//                deleteAccount()
//            }) {
//                // Delete button
//                Label("Delete", systemImage: "trash")
//            }
//            .tint(.red)
//        }
//    }
//
//    private func deleteAccount() {
//        if let index = accounts.firstIndex(of: account) {
//            accounts.remove(at: index)
//            saveAccounts()
//        }
//    }
//
//    // Existing code...
//}



struct AccountRowView: View {
    @Binding var account: Account
    @Binding var selectedAccount: Account?
    @Binding var isEditingAccount: Bool
    @Binding var accounts: [Account]
    @State private var showAlert = false

    var body: some View {
        NavigationLink(destination: TransactionListView(account: $account), isActive: Binding<Bool>(
            get: { selectedAccount == account },
            set: { newValue in
                if !newValue {
                    selectedAccount = nil
                }
            }
        )) {
            HStack {
                Image(systemName: account.icon)
                    .foregroundColor(account.color.color)
                    .font(.system(size: 36))
                VStack(alignment: .leading) {
                    Text(account.name)
                        .font(.headline)
                    Text(formatAmount(account.balance))
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
//                Spacer()
//
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.gray)
            }
            .padding(10)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(action: {
                    // Perform action when the delete button is tapped
                    deleteAccount()
                }) {
                    // Delete button
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button(action: {
                    // Perform action when the edit button is tapped
                    editAccount()
                }) {
                    // Edit button
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete this account?"),
                    primaryButton: .destructive(Text("Delete")) {
                        confirmDeleteAccount()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
//        })
            .onTapGesture {
                selectedAccount = account
            }
        }
    
    private func deleteAccount() {
        showAlert = true
    }

    private func confirmDeleteAccount() {
        selectedAccount = account
        
        if let selectedAccount = selectedAccount {
            if let index = accounts.firstIndex(where: { $0.id == selectedAccount.id }) {
                print("Deleting:  \(accounts[index])")
                accounts.remove(at: index)
            } else {
                print("Failed to find the selected account in the accounts array.")
            }
        } else {
            print("No selected account to delete.")
        }

        // Reset the selectedAccount and isEditingAccount
        selectedAccount = nil
        isEditingAccount = false

        saveAccounts()
    }

    private func saveAccounts() {
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase

        let recordID = CKRecord.ID(recordName: "AccountsRecord")
        privateDatabase.fetch(withRecordID: recordID) { (record, error) in
            if let error = error as? CKError {
                if error.code == .unknownItem {
                    // Create a new record since it doesn't exist
                    let newRecord = CKRecord(recordType: "Accounts", recordID: recordID)
                    // Set any desired initial values for the record
                    newRecord["accounts"] = CKAsset(fileURL: createTemporaryFileURL())

                    privateDatabase.save(newRecord) { (savedRecord, saveError) in
                        if let saveError = saveError {
                            print("Failed to save accounts to CloudKit: \(saveError)")
                        } else {
                            print("Accounts saved successfully to CloudKit")
                        }
                    }
                } else {
                    print("Failed to fetch accounts record from CloudKit: \(error)")
                }
            } else if let record = record {
                // Update the existing record
                record["accounts"] = CKAsset(fileURL: createTemporaryFileURL())

                privateDatabase.save(record) { (savedRecord, saveError) in
                    if let saveError = saveError {
                        print("Failed to save accounts to CloudKit: \(saveError)")
                    } else {
                        print("Accounts updated successfully in CloudKit")
                    }
                }
            }
        }
    }

    private func createTemporaryFileURL() -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("accounts.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        print(accounts)

        do {
            let encodedAccounts = try encoder.encode(accounts)
            try encodedAccounts.write(to: fileURL)
        } catch {
            print("Failed to encode accounts: \(error)")
        }

        return fileURL
    }
    
    private func editAccount() {
        selectedAccount = account
        isEditingAccount = true
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }
}

struct TransactionListView: View {
    @Binding var account: Account
    @State private var isAddingTransaction = false
    
    var body: some View {
        List {
            ForEach(account.transactions) { transaction in
                TransactionRowView(transaction: transaction)
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle(account.name)
        .navigationBarItems(trailing: addButton)
        .sheet(isPresented: $isAddingTransaction) {
            AddTransactionView(isPresented: $isAddingTransaction, account: $account)
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            isAddingTransaction = true
        }) {
            Image(systemName: "plus")
//                .renderingMode(.original)
                .foregroundColor(.blue)
//                .padding(.top, 7.0)
//                .font(.title2)
                .bold()
        }
    }
}

struct TransactionRowView: View {
    var transaction: Transaction
    
    var body: some View {
        HStack {
//            Image(systemName: "dollarsign.circle.fill")
//                .foregroundColor(Color.green)
//                .font(.system(size: 36))
            VStack(alignment: .leading) {
                Text(transaction.title)
                    .font(.headline)
                Text("\(formatAmount(transaction.amount))")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
            }
            Spacer()
            Text(transaction.date)
                .font(.subheadline)
                .foregroundColor(Color.gray)
        }
        .padding(10)
    }
    
    private func formatAmount(_ amount: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            return formatter.string(from: NSNumber(value: amount)) ?? ""
        }
}

struct BankAccount: Codable {
    var balance: Double
    var transactions: [Transaction]
}

struct Account: Identifiable, Codable, Equatable {
    static func ==(lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id = UUID()
    var name: String
    var balance: Double
    var icon: String
    var color: ColorWrapper
    var transactions: [Transaction]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case balance
        case icon
        case color
        case transactions
    }

    init(name: String, balance: Double, icon: String, color: ColorWrapper, transactions: [Transaction]) {
        self.name = name
        self.balance = balance
        self.icon = icon
        self.color = color
        self.transactions = transactions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        balance = try container.decode(Double.self, forKey: .balance)
        icon = try container.decode(String.self, forKey: .icon)
        color = try container.decode(ColorWrapper.self, forKey: .color)
        transactions = try container.decode([Transaction].self, forKey: .transactions)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(balance, forKey: .balance)
        try container.encode(icon, forKey: .icon)
        try container.encode(color, forKey: .color)
        try container.encode(transactions, forKey: .transactions)
    }
}

struct ColorWrapper: Codable, Equatable, Hashable {
    let color: Color

    init(color: Color) {
        self.color = color
    }

    private enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let opacity = try container.decode(Double.self, forKey: .opacity)
        self.color = Color(red: red, green: green, blue: blue, opacity: opacity)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        try container.encode(Double(red), forKey: .red)
        try container.encode(Double(green), forKey: .green)
        try container.encode(Double(blue), forKey: .blue)
        try container.encode(Double(alpha), forKey: .opacity)
    }
}


struct Transaction: Identifiable, Codable {
    var id = UUID()
    var title: String
    var amount: Double
    var date: String

//    enum CodingKeys: String, CodingKey {
//        case id
//        case title
//        case amount
//        case date
//    }
}

//let accounts = [
//    Account(name: "Savings", balance: 5000, transactions: [
//        Transaction(title: "Groceries", amount: -50, date: "May 29, 2023"),
//        Transaction(title: "Salary", amount: 2000, date: "May 25, 2023"),
//        Transaction(title: "Dinner", amount: -30, date: "May 24, 2023")
//    ]),
//    Account(name: "Checking", balance: 1000, transactions: [
//        Transaction(title: "Utilities", amount: -100, date: "May 28, 2023"),
//        Transaction(title: "Rent", amount: -800, date: "May 26, 2023"),
//        Transaction(title: "Deposit", amount: 500, date: "May 23, 2023")
//    ])
//]

struct AddAccountView: View {
    @Binding var isPresented: Bool
    @Binding var accounts: [Account]
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var accountName = ""
    @State private var selectedIcon: String = "dollarsign.circle.fill"
    
    let iconOptions = [
        "dollarsign.circle.fill",
        "creditcard.fill",
        "creditcard.and.123",
        "building.columns.fill",
        "building.2.fill",
        "house.fill",
        "heart.fill",
        "waveform.path.ecg",
        "car.fill",
    ]
    
    @State private var selectedColor: ColorWrapper = ColorWrapper(color: Color.green)
    
    let colorOptions: [ColorWrapper] = [
        ColorWrapper(color: Color.green),
        ColorWrapper(color: Color.yellow),
        ColorWrapper(color: Color.orange),
        ColorWrapper(color: Color.red),
        ColorWrapper(color: Color.pink),
        ColorWrapper(color: Color.purple),
        ColorWrapper(color: Color.blue),
        ColorWrapper(color: Color.cyan),
        ColorWrapper(color: Color(red: 1, green: 0, blue: 1))
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Details")) {
                    TextField("Account Name", text: $accountName)
                }
                
                Section(header: Text("Select Icon"), content: {
                    GridView(data: iconOptions, columns: 3, spacing: 8) { iconName in
                        IconView(iconName: iconName, selectedColor: selectedColor, selectedIcon: $selectedIcon)
                        
                        //                            Text("Test")
                    }
                    //                        .padding(.horizontal, 8)
                })
                
                Section(header: Text("Select Color")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(colorOptions, id: \.self) { color in
                            ColorView(color: color, selectedColor: $selectedColor)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        addAccount()
                    }) {
                        Text("Add Account")
                    }
                    .disabled(accountName.isEmpty)
                }
                
                Section {
                    Button(action: {
                        addBankAccount()
                    }) {
                        Text("Add Bank Account instead")
                    }
                    .disabled(accountName.isEmpty)
                }
            }
            .navigationBarTitle("Add Account")
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            })
        }
    }
    
    private func addBankAccount() {
        fetchBankAccount { bankAccount in
            if let bankAccount = bankAccount {
                let newAccount = Account(name: accountName, balance: bankAccount.balance, icon: selectedIcon, color: selectedColor, transactions: bankAccount.transactions)
                
                accounts.append(newAccount)
                presentationMode.wrappedValue.dismiss()
                
                saveAccounts()
            } else {
                // Handle the scenario where the bank account data retrieval failed
                print("Failed to fetch bank account data")
            }
        }
    }
    
    private func saveAccounts() {
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        
        let recordID = CKRecord.ID(recordName: "AccountsRecord")
        privateDatabase.fetch(withRecordID: recordID) { (record, error) in
            if let error = error as? CKError {
                if error.code == .unknownItem {
                    // Create a new record since it doesn't exist
                    let newRecord = CKRecord(recordType: "Accounts", recordID: recordID)
                    // Set any desired initial values for the record
                    newRecord["accounts"] = CKAsset(fileURL: createTemporaryFileURL())
                    
                    print(newRecord)
                    
                    privateDatabase.save(newRecord) { (savedRecord, saveError) in
                        if let saveError = saveError {
                            print("Failed to save new record to CloudKit: \(saveError)")
                        } else {
                            print("New record saved successfully")
                        }
                    }
                } else {
                    print("Failed to fetch record from CloudKit: \(error)")
                }
            } else {
                // Existing record fetched successfully, proceed with updating it
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("accounts.json")
                
                do {
                    let encoder = JSONEncoder()
                    let encodedAccounts = try encoder.encode(accounts)
                    try encodedAccounts.write(to: fileURL)
                    
                    print("File URL: \(fileURL)")
                    print("Temporary Directory Contents Before Saving:")
                    printDirectoryContents(at: FileManager.default.temporaryDirectory)
                    
                    let accountsAsset = CKAsset(fileURL: fileURL)
                    
                    print(accountsAsset)
                    
                    if record != nil {
                        record?["accounts"] = accountsAsset
                        privateDatabase.save(record!) { (savedRecord, saveError) in
                            if let saveError = saveError {
                                print("Failed to save record to CloudKit: \(saveError)")
                            }
                        }
                    } else {
                        let newRecord = CKRecord(recordType: "Accounts")
                        newRecord["accounts"] = accountsAsset
                        privateDatabase.save(newRecord) { (savedRecord, saveError) in
                            if let saveError = saveError {
                                print("Failed to save new record to CloudKit: \(saveError)")
                            }
                        }
                    }
                    
                    print("Temporary Directory Contents After Saving:")
                    printDirectoryContents(at: FileManager.default.temporaryDirectory)
                    
                } catch {
                    print("Failed to encode and save accounts: \(error)")
                }
            }
        }
    }
    
    private func createTemporaryFileURL() -> URL {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let uniqueFilename = ProcessInfo.processInfo.globallyUniqueString
        let filename = "\(uniqueFilename).json"
        let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)
        
        do {
            let encoder = JSONEncoder()
            let encodedAccounts = try encoder.encode(accounts)
            try encodedAccounts.write(to: fileURL)
            
            return fileURL
        } catch {
            print("Failed to encode and save accounts: \(error)")
            fatalError("Couldn't save data")
        }
        
    }
    
    private func printDirectoryContents(at directoryURL: URL) {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                print(fileURL.lastPathComponent)
            }
        } catch {
            print("Failed to read contents of directory: \(error)")
        }
    }
    
    private func addAccount() {
        let newAccount = Account(name: accountName, balance: 0, icon: selectedIcon, color: selectedColor, transactions: [])
        accounts.append(newAccount)
        presentationMode.wrappedValue.dismiss()
        
        saveAccounts()
    }
    
    private func fetchBankAccount(completion: @escaping (BankAccount?) -> Void) {
        // Replace with your Chase API credentials
        let clientID = "YOUR_CLIENT_ID"
        let clientSecret = "YOUR_CLIENT_SECRET"
        let accessToken = "eyJhbGciOiJIUzUxMiJ9.eyJJZCI6ImNkMmIxYWZkLTZmZTQtNGFmNS05N2M3LWM0OWRlOTU5M2M2MiIsImV4cCI6MTY4NTg4NTE3MH0.njQ21XnH8JM8HaSFk6PoaXrgH5Gf6hc-Nq_EzJfxCefzDT8SJx5CMIZU446TExvWTilPVGxVUIw3lLgw6wjQ0Q"
        
        // Create the request URL
            let endpoint = "https://api.chase.com/accounts"
            guard let url = URL(string: endpoint) else {
                fatalError("Invalid URL")
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            // Make the API request
            let session = URLSession.shared
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid HTTP response")
                    return
                }

                print("Response Status Code: \(httpResponse.statusCode)")

                if let data = data {
                    let dataString = String(data: data, encoding: .utf8)
                    print("Response Data: \(dataString ?? "")")
                } else {
                    print("Empty response data")
                }

                do {
                    let decoder = JSONDecoder()
                    let bankAccount = try decoder.decode(BankAccount.self, from: data!)
                    print("Bank Account: \(bankAccount)")
                } catch {
                    print("Error decoding API response: \(error.localizedDescription)")
                }
            }
            task.resume()
        }
}

struct AddTransactionView: View {
    @Binding var isPresented: Bool
    @Binding var account: Account

    @Environment(\.presentationMode) var presentationMode
    
    @State private var transactionName = ""
    @State private var transactionAmount = ""
    @State private var isAmountValid = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Transaction Name", text: $transactionName)
                    
                    HStack {
                        Text("$")
                        
                        TextField("Transaction Amount", text: $transactionAmount)
                            .keyboardType(.decimalPad)
                            .onChange(of: transactionAmount, perform: validateAmount)
                            .foregroundColor(isAmountValid ? .primary : .red)
                    }
                }
                
                Section {
                    Button(action: {
//                        addTransaction()
                    }) {
                        Text("Add Transaction")
                    }
                    .disabled(!isAmountValid || transactionName == "")
                }
            }
            .navigationBarTitle("Add Transaction")
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            })
        }
    }
    
    private func validateAmount(_ value: String) {
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        let components = value.components(separatedBy: decimalSeparator)
        
        if components.count <= 2, let wholeNumber = Int(components[0]) {
            if components.count == 1 {
                // Only the whole number part is entered
                isAmountValid = true
                account.balance = Double(wholeNumber)
            } else if let decimalNumber = Int(components[1]), components[1].count <= 2 {
                // Both whole number and decimal part are entered with at most two decimal places
                isAmountValid = true
                account.balance = Double(wholeNumber) + Double(decimalNumber) / 100.0
            } else {
                // Invalid decimal part
                isAmountValid = false
            }
        } else {
            // Invalid amount
            isAmountValid = false
        }
    }

//    private func addTransaction() {
//        guard let amount = Double(transactionAmount) else {
//            // Display an alert or show an error message indicating invalid amount
//            return
//        }
//
//        let newTransaction = Transaction(name: transactionName, amount: amount)
//        account.transactions.append(newTransaction)
//        presentationMode.wrappedValue.dismiss()
//    }
}


struct EditAccountView: View {
    @Binding var isPresented: Bool
    @Binding var selectedAccount: Account?
    @Binding var accounts: [Account]
    @Binding var editedAccount: Account?

    @Environment(\.presentationMode) var presentationMode

    @State private var accountName = ""
    @State private var selectedIcon: String = ""
    @State private var selectedColor: ColorWrapper = ColorWrapper(color: Color.green)

    let iconOptions = [
        "dollarsign.circle.fill",
        "creditcard.fill",
        "creditcard.and.123",
        "building.columns.fill",
        "building.2.fill",
        "house.fill",
        "heart.fill",
        "waveform.path.ecg",
        "car.fill",
    ]

    let colorOptions: [ColorWrapper] = [
        ColorWrapper(color: Color.green),
        ColorWrapper(color: Color.yellow),
        ColorWrapper(color: Color.orange),
        ColorWrapper(color: Color.red),
        ColorWrapper(color: Color.pink),
        ColorWrapper(color: Color.purple),
        ColorWrapper(color: Color.blue),
        ColorWrapper(color: Color.cyan),
        ColorWrapper(color: Color(red: 1, green: 0, blue: 1))
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Details")) {
                    TextField("Account Name", text: $accountName)
                }

                Section(header: Text("Select Icon"), content: {
                    GridView(data: iconOptions, columns: 3, spacing: 8) { iconName in
                        IconView(iconName: iconName, selectedColor: selectedColor, selectedIcon: $selectedIcon)
                    }
                })

                Section(header: Text("Select Color")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(colorOptions, id: \.self) { color in
                            ColorView(color: color, selectedColor: $selectedColor)
                        }
                    }
                }

                Section {
                    Button(action: {
                        editAccount()
                    }) {
                        Text("Save Account")
                    }
                    .disabled(accountName.isEmpty)
                }
            }
            .navigationBarTitle("Edit Account")
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            })
            .onAppear {
                accountName = selectedAccount?.name ?? ""
                selectedIcon = selectedAccount?.icon ?? ""
                selectedColor = selectedAccount?.color ?? ColorWrapper(color: Color.green)
            }
        }
    }

    private func saveAccounts() {
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase

        let recordID = CKRecord.ID(recordName: "AccountsRecord")
        privateDatabase.fetch(withRecordID: recordID) { (record, error) in
            if let error = error as? CKError {
                if error.code == .unknownItem {
                    // Create a new record since it doesn't exist
                    let newRecord = CKRecord(recordType: "Accounts", recordID: recordID)
                    // Set any desired initial values for the record
                    newRecord["accounts"] = CKAsset(fileURL: createTemporaryFileURL())

                    privateDatabase.save(newRecord) { (savedRecord, saveError) in
                        if let saveError = saveError {
                            print("Failed to save accounts to CloudKit: \(saveError)")
                        } else {
                            print("Accounts saved successfully to CloudKit")
                        }
                    }
                } else {
                    print("Failed to fetch accounts record from CloudKit: \(error)")
                }
            } else if let record = record {
                // Update the existing record
                record["accounts"] = CKAsset(fileURL: createTemporaryFileURL())

                privateDatabase.save(record) { (savedRecord, saveError) in
                    if let saveError = saveError {
                        print("Failed to save accounts to CloudKit: \(saveError)")
                    } else {
                        print("Accounts updated successfully in CloudKit")
                    }
                }
            }
        }
    }

    private func createTemporaryFileURL() -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("accounts.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        print(accounts)

        do {
            let encodedAccounts = try encoder.encode(accounts)
            try encodedAccounts.write(to: fileURL)
        } catch {
            print("Failed to encode accounts: \(error)")
        }

        return fileURL
    }
    
    private func editAccount() {
        if let selectedAccount = selectedAccount,
            let index = accounts.firstIndex(where: { $0.id == selectedAccount.id }) {
            accounts[index].name = accountName
            accounts[index].icon = selectedIcon
            accounts[index].color = selectedColor
        }

        saveAccounts()
    }
}

struct GridView<Data, Content>: View where Data: RandomAccessCollection, Content: View {
    let data: Data
    let columns: Int
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    var rows: Int {
        (data.count - 1) / columns + 1
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<rows) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<columns) { column in
                        let index = row * columns + column
                        if index < data.count {
                            content(data[index as! Data.Index])
                        } else {
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, spacing)
    }
}

struct IconView: View {
    var iconName: String
    var selectedColor: ColorWrapper
    @Binding var selectedIcon: String

    var isSelected: Bool {
        iconName == selectedIcon
    }

    var body: some View {
        let iconImage = Image(systemName: iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 96, height: 40)

        let iconForegroundColor = isSelected ? selectedColor.color : Color.gray
        let iconBackground = isSelected ? selectedColor.color.opacity(0.2) : Color.clear

        return VStack {
            iconImage
                .foregroundColor(iconForegroundColor)
        }
        .padding(8)
        .background(iconBackground)
        .cornerRadius(10)
        .onTapGesture {
            selectedIcon = iconName // Update the selectedIcon binding with the iconName
        }
    }
}

//struct IconView: View {
//    let iconName: String
//    let isSelected: Bool
//    var selectedColor: ColorWrapper
////    let onSelect: () -> Void
//
//    var body: some View {
//        Image(systemName: iconName)
//            .resizable()
//            .aspectRatio(contentMode: .fit)
//            .frame(width: 40, height: 40)
//            .padding(8)
//            .background(isSelected ? selectedColor.color : Color.clear)
//            .cornerRadius(8)
//            .foregroundColor(isSelected ? selectedColor.color : Color.gray)
//            .onTapGesture {
////                onSelect()
//            }
//    }
//}

struct ColorView: View {
    var color: ColorWrapper
    @Binding var selectedColor: ColorWrapper

    var body: some View {
        Circle()
            .foregroundColor(color.color)
            .frame(width: 97, height: 40)
            .overlay(
                Circle()
                    .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 2)
            )
            .onTapGesture {
                selectedColor = color
            }
            .padding(4)
    }
}


//extension Account: Codable {}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
