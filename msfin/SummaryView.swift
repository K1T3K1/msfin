//
//  SummaryView.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 15/01/2024.
//

import Charts
import Foundation
import SwiftData
import SwiftUI

struct SummaryView: View {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.modelContext) private var modelContext
  @Query private var transactions: [Transaction]
  @Binding public var chartBy: String
  @State private var sectorExpenses: [String: Double] = [:]
  @State private var sectorIncomes: [String: Double] = [:]
  @State private var sumIncomes: Double = 0.0
  @State private var sumExpenses: Double = 0.0
  @State private var sortedTransactions: [Transaction] = []
  @State private var fromDate: Date =
      Calendar.current.date(
        byAdding: .month,
        value: -1,
        to: Date()) ?? Date()
    @State private var toDate: Date = Date()

  let chartCategories = ["Accounts", "Categories"]
  var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      Text("Summary").padding()
        .font(.system(size: 28, weight: .bold, design: .monospaced))
        Divider()
        DatePicker("From", selection: $fromDate).onChange(of: fromDate) { getCharts() }
        DatePicker("To", selection: $toDate).onChange(of: toDate) { getCharts() }
      GroupBox {
        Text("Incomes shares: ").padding()
          .font(.system(size: 18, weight: .bold, design: .monospaced))
        Chart {
          ForEach(Array(sectorIncomes.keys), id: \.self) { key in
            SectorMark(
              angle: .value("Percent", (sectorIncomes[key] ?? 0.0) / sumIncomes),
              innerRadius: .ratio(0.50)
            )
            .foregroundStyle(by: .value("Type", key))
          }
        }.padding()
        VStack(alignment: .leading) {
          ForEach(Array(sectorIncomes.keys), id: \.self) { key in
            HStack {
              Text("\(key) - ")
                .fontWeight(.heavy)
              Text(String(format: "%.2f", sectorIncomes[key] ?? 0.0))
            }
          }
        }
      }
      .padding()
      .background(Color(.systemGray5))
      .clipShape(RoundedRectangle(cornerRadius: 5))
      .padding()
      GroupBox {
        Text("Expenses shares: ").padding()
          .font(.system(size: 18, weight: .bold, design: .monospaced))
        Chart {
          ForEach(Array(sectorExpenses.keys), id: \.self) { key in
            SectorMark(
              angle: .value("Percent", (sectorExpenses[key] ?? 0.0) / sumExpenses),
              innerRadius: .ratio(0.50)
            )
            .foregroundStyle(by: .value("Type", key))
          }
        }.padding()
        VStack(alignment: .leading) {
          ForEach(Array(sectorExpenses.keys), id: \.self) { key in
            HStack {
              Text("\(key) - ")
                .fontWeight(.heavy)
              Text(String(format: "%.2f", sectorExpenses[key] ?? 0.0))
            }
          }
        }
      }
      .padding()
      .background(Color(.systemGray5))
      .buttonStyle(.bordered)
      .clipShape(RoundedRectangle(cornerRadius: 5))
      .padding()
    }
    .onAppear(perform: getCharts)
    .onChange(of: chartBy, getCharts)
    .frame(maxWidth: 350)
    .backgroundStyle(.clear)
    .buttonStyle(.bordered)
    .buttonBorderShape(.roundedRectangle(radius: 5))
    .padding()
  }

  func getCharts() {
    sectorExpenses = [:]
    sectorIncomes = [:]
    sumIncomes = 0.0
    sumExpenses = 0.0
    filterTransactions()
    getChartIncomes()
    getChartExpenses()
  }

    func filterTransactions() {
        sortedTransactions = try! transactions.filter(#Predicate { fromDate < $0.timestamp && $0.timestamp < toDate } )
    }
    
  func getChartIncomes() {
    for transaction in sortedTransactions {
      if transaction.value >= 0 {
        if chartBy == "Accounts" {
          if let val = sectorIncomes[transaction.account.name] {
            let updateValue = val + transaction.value
            sectorIncomes.updateValue(updateValue, forKey: transaction.account.name)
          } else {
            sectorIncomes.updateValue(transaction.value, forKey: transaction.account.name)
          }
        } else if chartBy == "Categories" {
          let categoryName = transaction.category?.name ?? "No category"
          if let val = sectorIncomes[categoryName] {
            let updateValue = val + transaction.value
            sectorIncomes.updateValue(updateValue, forKey: categoryName)
          } else {
            sectorIncomes.updateValue(transaction.value, forKey: categoryName)
          }
        }
      }
    }
    sumIncomes = sectorIncomes.values.reduce(0.0, +)
  }

  func getChartExpenses() {
    for transaction in sortedTransactions {
      if transaction.value < 0 {
        if chartBy == "Accounts" {
          if let val = sectorExpenses[transaction.account.name] {
            let updateValue = val + transaction.value
            sectorExpenses.updateValue(updateValue, forKey: transaction.account.name)
          } else {
            sectorExpenses.updateValue(transaction.value, forKey: transaction.account.name)
          }
        } else if chartBy == "Categories" {
          let categoryName = transaction.category?.name ?? "No category"
          if let val = sectorExpenses[categoryName] {
            let updateValue = val + transaction.value
            sectorExpenses.updateValue(updateValue, forKey: categoryName)
          } else {
            sectorExpenses.updateValue(transaction.value, forKey: categoryName)
          }
        }
      }
    }
    sumExpenses = sectorExpenses.values.reduce(0.0, +)
  }
}
