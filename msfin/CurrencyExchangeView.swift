//
//  CurrencyExchangeView.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 21/01/2024.
//

import Foundation
import SwiftUI

struct CurrencyExchangeView: View {
  @Environment(\.colorScheme) var colorScheme
  @State private var inputCurrency = "PLN"
  @State private var outputCurrency = "EUR"
  @State private var value: Double = 0.0
  @State private var exchangeRate: Double = 0.0
  @State private var exchangeResult: Double = 0.0
  let currencies = [
    ("PLN", "Złoty"), ("EUR", "Euro"), ("USD", "Dolary Amerykańskie"), ("AUD", ""),
    ("CAD", "Dolary Kanadyjskie"), ("JPY", "Yen"), ("CZK", "Korona Czeska"),
    ("DKK", "Korona Duńska"), ("GBP", "Funt Szterling"), ("HUF", "Forint Węgierski"),
    ("SEK", "Korona Szweedzka"), ("CHF", "Frank Szwajcarski"), ("RUB", "Rubel"),
    ("BRL", "Real Brazylijski"), ("CNY", "Yuan Chiński"),
  ]

  let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
  }()

  func getCurrenciesList() -> some View {
    return ForEach(currencies, id: \.0) { currency in
      Text("\(currency.0) | \(currency.1)").tag(currency.0)
            .font(.system(size: 12))
    }
  }

  func exchange() {
      getCurrencyPair(currencyA: inputCurrency, currencyB: outputCurrency){ rate in
          exchangeRate = rate
          exchangeResult = value * exchangeRate
      }
  }

  var body: some View {
    VStack {
      HStack {
        HStack {
          Text("From: ")
          Picker("currencyA", selection: $inputCurrency) {
            getCurrenciesList()
          }
          .pickerStyle(.wheel)
        }
        HStack {
          Text("To: ")
          Picker("currencyB", selection: $outputCurrency) {
            getCurrenciesList()
          }
          .pickerStyle(.wheel)
        }
      }
      Divider()
      VStack {
        HStack {
          Text("Value: ")
            .fontWeight(.heavy)
          TextField("", value: $value, formatter: formatter).keyboardType(
            .numbersAndPunctuation
          )
          .padding()
          .textFieldStyle(.roundedBorder)
        }
        Stepper(value: $value, in: 0.00...9_999_999, step: 0.01) {
        }
      }
      VStack {
        Text("Exchange Rate: ")
        Text("\(exchangeRate)")
      }
      VStack {
        Text("Result: \(exchangeResult)")
        Button(action: { withAnimation { exchange() } }) {
          Text("Exchange")
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

  }
}
