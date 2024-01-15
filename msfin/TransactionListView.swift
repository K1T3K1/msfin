//
//  TransactionListView.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 08/01/2024.
//

import AlertToast
import SwiftData
import SwiftUI

struct Ordering: Hashable {
  private var description: String
  private var sortDescriptor: SortDescriptor<Transaction>
}

struct TransactionListView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.colorScheme) var colorScheme
  @Query private var transactions: [Transaction]
  @State private var sortedTransactions: [Transaction] = []
  @Query private var accounts: [Account]
  @State private var isAdding: Bool = false
  @State private var selectedTab = "All"
  @State private var transactionOrder = "Date Desc."
  private let orders: [String] = [
    "Date Desc.",
    "Date Asc.",
    "Value Desc.",
    "Value Asc.",
  ]
  private var tabs = ["All", "Incomes", "Expenses"]

  var body: some View {
    ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
      TabView(selection: $selectedTab) {
        getTransactionView(expression: "All")
          .tag("All")
        getTransactionView(expression: "Income")
          .tag("Incomes")
        getTransactionView(expression: "Expense")
          .tag("Expenses")
      }
      .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
      .ignoresSafeArea(.all, edges: .bottom)
      HStack(alignment: .center, spacing: 0) {
        Button(action: { selectedTab = "All" }) {
          Image(systemName: "cart.fill").imageScale(.large)
        }.frame(maxWidth: .infinity).buttonStyle(.plain).padding(.vertical, 10).padding(
          .horizontal)
        Button(action: { selectedTab = "Incomes" }) {
          Image(systemName: "cart.fill.badge.plus").imageScale(.large)
        }.frame(maxWidth: .infinity).buttonStyle(.plain).padding(.vertical, 10).padding(
          .horizontal)
        Button(action: { selectedTab = "Expenses" }) {
          Image(systemName: "cart.fill.badge.minus").imageScale(.large)
        }.frame(maxWidth: .infinity).buttonStyle(.plain).padding(.vertical, 10).padding(
          .horizontal)
      }
      .padding(.horizontal, 25)
      .padding(.vertical, 5)
      .background(colorScheme == .dark ? Color.black : Color.white)
      .clipShape(Capsule())
      .shadow(
        color: (colorScheme == .dark ? Color.white : Color.black).opacity(0.15), radius: 5, x: 5,
        y: 5
      )
      .shadow(
        color: (colorScheme == .dark ? Color.white : Color.black).opacity(0.15), radius: 5, x: -5,
        y: -5
      )
      .padding(.horizontal)
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .background(Color.black.opacity(0.05).ignoresSafeArea(.all, edges: .all))
    .toolbar {
      ToolbarItem {
        Picker("Order", selection: $transactionOrder) {
          ForEach(orders, id: \.self) { order in
            Text(order)
          }
        }.onChange(of: transactionOrder) {
          sortTransactions()
        }
      }
      ToolbarItem {
        Button(action: { withAnimation { isAdding.toggle() } }) {
          Image(systemName: "plus").renderingMode(.template)
        }.sheet(isPresented: $isAdding) {
          AddTransactionView()
        }
      }
    }
    .onAppear(perform: sortTransactions)
    .onChange(of: transactions) { sortTransactions() }
  }

  func sortTransactions() {
    let comparator = getComparator(expression: $transactionOrder.wrappedValue)
    sortedTransactions = transactions.sorted(by: comparator)
  }

  func getComparator(expression: String) -> (Transaction, Transaction) -> Bool {
    if expression == "Date Desc." {
      return { tranA, tranB in tranA.timestamp > tranB.timestamp }
    } else if expression == "Date Asc." {
      return { tranA, tranB in tranA.timestamp < tranB.timestamp }
    } else if expression == "Value Desc." {
      return { tranA, tranB in tranA.value > tranB.value }
    } else if expression == "Value Asc." {
      return { tranA, tranB in tranA.value < tranB.value }
    }
    return { tranA, tranB in tranA.timestamp > tranB.timestamp }
  }

  func getTransactionView(expression: String) -> some View {
    return ScrollView(.vertical, showsIndicators: false) {
      ForEach(sortedTransactions) { transaction in
        if getFilterExpression(expression: expression, value: transaction.value) {
          NavigationLink(destination: EditTransactionView(transaction: transaction)) {
            VStack(alignment: .leading) {
              Text(String(format: "%.2f", transaction.value))
                .foregroundStyle(transaction.value < 0 ? Color.red : Color.green)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
              Spacer()
              Text("\(transaction.name)")
              Text("Account: \(transaction.account.name)")
                .fontWeight(.bold)
              Divider()
              Text("\(transaction.timestamp.formatted(date: .numeric, time: .shortened))")
                HStack {
                    Text("Category: ")
                    if let img = transaction.category?.image {
                        Image(systemName: img)
                    }
                    Text("\(transaction.category?.name ?? "None")")
                }
            }
          }
        }
      }
    }
    .frame(maxWidth: 300)
    .backgroundStyle(.clear)
    .buttonStyle(.bordered)
    .buttonBorderShape(.roundedRectangle(radius: 5))
    .padding()
  }

  func getFilterExpression(expression: String, value: Double) -> Bool {
    if expression == "Expense" {
      return value < 0
    } else if expression == "Income" {
      return value >= 0
    } else {
      return true
    }
  }
}

struct EditTransactionView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) var dismiss
  @Bindable public var transaction: Transaction
  @State private var uuid: UUID
  @State private var newValue: Double
  @State private var newAccount: String
  @State private var newName: String = ""
  @State private var newDate: Date = Date()
  @State private var newCategory: Category? = nil
  @State private var showError: Bool = false
  @State private var errorText: String = ""
  @Query private var accounts: [Account]

  let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
  }()

  init(transaction: Transaction) {
    _transaction = Bindable(wrappedValue: transaction)
    _uuid = State(wrappedValue: transaction.id)
    _newValue = State(wrappedValue: transaction.value)
    _newAccount = State(wrappedValue: transaction.account.name)
    _newName = State(wrappedValue: transaction.name)
    _newDate = State(wrappedValue: transaction.timestamp)
    _newCategory = State(wrappedValue: transaction.category)
  }

  var body: some View {
    VStack {
      Text("Edit transaction")
        .font(.system(size: 28, weight: .bold, design: .monospaced))
      VStack {
        Picker("Account", selection: $newAccount) {
          ForEach(accounts) {
            a in
            Text(a.name).tag(a.name)
          }
        }
        Divider()
        HStack {
          Text("Name: ")
            .fontWeight(.heavy)
          TextField("", text: $newName).padding()
        }
        Divider()
        HStack {
          HStack {
            Text("Value: ")
              .fontWeight(.heavy)
            TextField("", value: $newValue, formatter: formatter).keyboardType(.decimalPad)
              .padding()
          }
          Stepper(value: $newValue, in: 0.00...9_999_999, step: 0.01) {

          }
        }
        Divider()
        DatePicker("Date: ", selection: $newDate)
        Button(action: { withAnimation { submitChanges() } }) {
          Text("Submit")
        }
      }
    }
    .padding()
    .background(colorScheme == .dark ? Color.black : Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .shadow(
      color: (colorScheme == .dark ? Color.white : Color.black).opacity(0.15), radius: 5, x: 5,
      y: 5
    )
    .shadow(
      color: (colorScheme == .dark ? Color.white : Color.black).opacity(0.15), radius: 5, x: -5,
      y: -5
    )
    .frame(maxWidth: 350)
    .toast(isPresenting: $showError) {
      AlertToast(
        displayMode: .alert, type: .error(.red), title: errorText)
    }
  }

  func submitChanges() {
    do {
      let nAccount = try modelContext.fetch(
        FetchDescriptor<Account>(predicate: #Predicate { $0.name == newAccount }))
      let transaction = try modelContext.fetch(
        FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == uuid }))
      if let acc = nAccount.first {
        if let transactionUnwrapped = transaction.first {
          transactionUnwrapped.account.balance -= transactionUnwrapped.value
          acc.balance += newValue
          transactionUnwrapped.value = newValue
          transactionUnwrapped.name = newName
          transactionUnwrapped.account = acc
          transactionUnwrapped.category = newCategory
          transactionUnwrapped.timestamp = newDate
          dismiss()
        } else {
          errorText = "Transaction doesn't exist"
          showError.toggle()
        }
      } else {
        errorText = "Account doesn't exist"
        showError.toggle()
      }
    } catch {
      errorText = "Failed to edit transaction"
      showError.toggle()
    }
  }
}

struct AddTransactionView: View {
  @Environment(\.dismiss) var dismiss
  @Environment(\.modelContext) private var modelContext
  @Environment(\.colorScheme) var colorScheme
  @State public var value: Double = 0.0
  @State public var date: Date = Date()
  @State public var name: String = ""
  @State public var selectedAccount: String = ""
  @State public var transactionType: String = ""
  @State public var transactionCategory: String = ""
  @Query public var accounts: [Account]
  @Query public var categories: [Category]

  let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
  }()

  var body: some View {
    if let accountFirst = accounts.first {
      VStack {
        Text("Add transaction")
          .font(.system(size: 28, weight: .bold, design: .monospaced))
        VStack {
          Picker("Account", selection: $selectedAccount) {
            ForEach(accounts) {
              a in
              Text(a.name).tag(a.name)
            }
          }
          Divider()
          Picker("Category", selection: $transactionCategory) {
              ForEach(categories, id: \.self) {
              a in
                VStack{
                    Image(systemName: a.image)
                    Spacer()
                    Text(a.name)
                }
                .tag(a.name)
                .padding()
            }
          }
          Divider()
          HStack {
            Text("Name: ")
              .fontWeight(.heavy)
            TextField("", text: $name).padding()
          }
          Divider()
          HStack {
            HStack {
              Text("Value: ")
                .fontWeight(.heavy)
              TextField("", value: $value, formatter: formatter).keyboardType(
                .numbersAndPunctuation
              ).padding()
            }
            Stepper(value: $value, in: 0.00...9_999_999, step: 0.01) {

            }
          }
          Divider()
          DatePicker("Date: ", selection: $date)
            .fontWeight(.heavy)
          Button(action: { withAnimation { submitTransaction() } }) {
            Text("Submit")
          }
        }
      }
      .padding()
      .background(colorScheme == .dark ? Color.black : Color.white)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .shadow(
        color: (colorScheme == .dark ? Color.white : Color.black).opacity(0.15), radius: 5, x: 5,
        y: 5
      )
      .shadow(
        color: (colorScheme == .dark ? Color.white : Color.black).opacity(0.15), radius: 5, x: -5,
        y: -5
      )
      .frame(maxWidth: 350)
      .onAppear(perform: fillValues)
    } else {
      VStack {
        Text("Accounts empty. Add an account before adding transaction")
      }
    }
  }

  func fillValues() {
    getAccount()
    getCategory()
  }

  func getAccount() {
    selectedAccount = accounts.first?.name ?? ""
  }

  func getCategory() {
      transactionCategory = categories.first?.name ?? ""
  }

  func submitTransaction() {
    do {
      let account = try modelContext.fetch(
        FetchDescriptor<Account>(predicate: #Predicate { $0.name == selectedAccount })
      )
        let category = categories.first(where: {category in category.name == transactionCategory})
      if let accountUn = account.first {
        let transaction = Transaction(
          timestamp: date, value: value, account: accountUn, name: name,
          category: category)
        modelContext.insert(transaction)
        accountUn.balance += transaction.value
        dismiss()
      } else {
        return
      }
    } catch {
      print("\(error)")
      return
    }
  }
}
#Preview {
  TransactionListView().modelContainer(PreviewModelContainer)
}
