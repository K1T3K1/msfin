//
//  AccountsView.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 08/01/2024.
//

import AlertToast
import Charts
import SwiftData
import SwiftUI

struct AccountsView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.modelContext) private var modelContext
  @State private var allowAdd: Bool = false
  @Query private var accounts: [Account]

  var body: some View {
    NavigationView {
      ScrollView(.vertical, showsIndicators: false) {
        VStack {
          ForEach(accounts) { account in
            NavigationLink(destination: SingleAccountView(accountRef: account)) {
              VStack(alignment: .leading) {
                Text("\(account.name)")
                  .font(.system(size: 28, weight: .bold, design: .monospaced))
                Text("\((account.type.rawValue))")
                Spacer()
                Divider()
                HStack {
                  Text("Current Balance: ")
                  Text("\(String(format: "%.2f", account.balance))").foregroundStyle(
                    account.balance < 0.0 ? Color.red : Color.green)
                }
              }.padding()
            }
            .frame(maxWidth: 300)
            .backgroundStyle(.clear)
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 5))
          }
        }
        .padding(.vertical)
      }
      .toolbar {
        ToolbarItem {
          Button(action: { withAnimation { allowAdd.toggle() } }) {
            Image(systemName: "plus")
              .renderingMode(.template)
          }
          .sheet(
            isPresented: $allowAdd,
            content: {
              AddAccountView(allowAdd: $allowAdd)
            })
        }
        ToolbarItem(placement: .topBarLeading) {
          NavigationLink(
            destination: TransactionListView()
          ) {
            Image(systemName: "cart.fill")
          }
        }
        ToolbarItem(placement: .topBarLeading) {
          NavigationLink(
            destination: CategoryView()
          ) {
            Image(systemName: "squareshape.split.3x3")
          }
        }
      }
    }.foregroundStyle(colorScheme == .light ? Color.black : Color.white)
  }
}

struct AddAccountView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.colorScheme) var colorScheme
  @Binding var allowAdd: Bool
  @State private var accountName: String = ""
  @State private var accountBalance: Double = 0.0
  @State private var accountType: String = "Debit"
  @State private var showError: Bool = false
  @State private var errorText: String = ""

  let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
  }()

  var body: some View {
    VStack {
      Text("Add account")
        .font(.system(size: 28, weight: .bold, design: .monospaced))
        .padding()
      Picker("Type", selection: $accountType) {
        Text("Debit").tag("Debit")
        Text("Cash").tag("Cash")
        Text("Saving").tag("Saving")
        Text("Credit").tag("Credit")
      }.fontWeight(.heavy)
      Divider()
      HStack {
        Text("Name: ")
          .fontWeight(.heavy)
        TextField("", text: $accountName)
          .padding()
          .textFieldStyle(.roundedBorder)
      }
      Divider()
      VStack {
        HStack {
          Text("Balance: ")
            .fontWeight(.heavy)
          TextField("", value: $accountBalance, formatter: formatter)
            .keyboardType(.numbersAndPunctuation).padding()
            .textFieldStyle(.roundedBorder)
        }
        Stepper(value: $accountBalance, in: 0.00...9_999_999, step: 0.01) {
        }
      }
      Button(action: { withAnimation { submitAccount() } }) {
        Text("Submit")
      }
    }
    .toast(isPresenting: $showError) {
      AlertToast(
        displayMode: .alert, type: .error(.red), title: errorText)
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
  }

  func submitAccount() {
    if accountName == "" {
      errorText = "Account name cannot be empty"
      showError.toggle()
      return
    }
    let accType = AccountType(rawValue: accountType)
    if let aType = accType {
      do {
        let accounts = try modelContext.fetch(
          FetchDescriptor<Account>(predicate: #Predicate { $0.name == accountName }))
        if !accounts.isEmpty {
          errorText = "Account with the same name already exists"
          showError.toggle()
          return
        }
      } catch {
        print("\(error)")
      }
      let account = Account(name: accountName, type: aType, balance: accountBalance)
      modelContext.insert(account)
      allowAdd.toggle()
    }
  }
}

struct ChartValue: Identifiable {
  var id: UUID
  var value: Double
  var currentBalance: Double
  var timestamp: Date
  var name: String
}

struct SingleAccountView: View {
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.modelContext) private var modelContext
  @Environment(\.colorScheme) var colorScheme
  @Bindable var account: Account
  @Query private var transactions: [Transaction]
  @State var chartValues: [ChartValue] = []
  @State var showDeleteScreen: Bool = false

  init(accountRef: Account) {
    _account = Bindable(wrappedValue: accountRef)
    let id = _account.id
    _transactions = Query(
      filter: #Predicate<Transaction> { transaction in transaction.account.id == id },
      sort: \Transaction.timestamp, order: .reverse)
    chartValues.sort(by: { $0.timestamp < $1.timestamp })
  }

  var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      VStack {
        Text("\(account.name)")
          .font(.system(size: 28, weight: .bold, design: .monospaced))
        Text("\(account.type.rawValue)")
        HStack {
          Text("Account balance: ")
          Text("\(String(format: "%.2f", account.balance))").foregroundStyle(
            account.balance < 0 ? Color.red : Color.green)
        }
        GroupBox {
          Chart {
            ForEach(chartValues) { cv in
              LineMark(x: .value("Date", cv.timestamp), y: .value("Balance", cv.currentBalance))
            }
          }
        }
        .frame(maxHeight: 400)
        Button(action: { withAnimation { showDeleteScreen.toggle() } }) {
          Text("Delete account")
            .foregroundStyle(.red)
        }
        .sheet(
          isPresented: $showDeleteScreen,
          content: {
            DeleteAccountView(account: account)
          })
        Divider()
        VStack(alignment: .leading) {
          Text("Latest transactions")
            .font(.system(size: 28, weight: .bold, design: .monospaced))
          VStack {
            ForEach(transactions) { transaction in
              GroupBox {
                Text(String(format: "%.2f", transaction.value))
                  .foregroundStyle(transaction.value < 0 ? Color.red : Color.green)
                  .font(.system(size: 28, weight: .bold, design: .monospaced))
                Spacer()
                Text("\(transaction.name)")
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
              .padding()
              .frame(alignment: .leading)
              .clipShape(RoundedRectangle(cornerRadius: 10))
              .shadow(radius: 5)
            }
          }
        }
      }
    }
    .padding()
    .background(colorScheme == .dark ? Color.black : Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .shadow(radius: 5)
    .frame(maxWidth: 350)
    .onAppear {
      getTransactions()
    }
  }

  func getTransactions() {
    chartValues.append(
      ChartValue(
        id: UUID(), value: _account.balance.wrappedValue,
        currentBalance: _account.balance.wrappedValue, timestamp: Date.now, name: "Balance")
    )
    var currentBalance = account.balance
    for transaction in transactions {
      currentBalance = currentBalance - transaction.value
      chartValues.append(
        ChartValue(
          id: UUID(), value: transaction.value, currentBalance: currentBalance,
          timestamp: transaction.timestamp, name: transaction.name))
    }
    chartValues.sort(by: { $0.timestamp < $1.timestamp })
  }
}
struct EditAccountView: View {
  @Environment(\.presentationMode) var presentationMode
  @State var account: Account

  var body: some View {
    NavigationStack {
      Text("Edit account")
    }
  }
}

struct DeleteAccountView: View {
  @Bindable var account: Account
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) var dismiss

  var body: some View {
    Text("Delete account? Deleting account will delete all binded transactions")
      .foregroundStyle(.red)
      .fontWeight(.heavy)
    Button(action: { withAnimation { deleteAccount() } }) {
      Text("Delete")
        .foregroundStyle(.red)
    }
  }

  func deleteAccount() {
    do {
      let id = account.id
      let transactions = try modelContext.fetch(
        FetchDescriptor<Transaction>(
          predicate: #Predicate { transaction in
            transaction.account.id == id
          }
        ))
      modelContext.delete(account)
      for transaction in transactions {
        modelContext.delete(transaction)
      }
      try modelContext.save()
      dismiss()
    } catch {

    }
  }
}

#Preview {
  MainActor.assumeIsolated {
    AccountsView().modelContainer(PreviewModelContainer)
  }
}
