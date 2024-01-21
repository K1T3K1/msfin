//
//  CurrencyRequest.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 21/01/2024.
//

import Foundation

struct CurrencyResponse: Codable {
  let data: [String: Double]
}

func getCurrencyPair(currencyA: String, currencyB: String, completion: @escaping (Double) -> Void) {
  guard
    let url = URL(
      string:
        "https://api.freecurrencyapi.com/v1/latest?apikey=fca_live_DP4IGWQn9No61iuXJ5ANczF3KqGcqN90Bo7Yjr74&currencies=\(currencyB)&base_currency=\(currencyA)"
    )
  else {
    completion(0.0)
    return
  }

  let urlRequest = URLRequest(url: url)

  URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
    if let error = error {
      print("Request error: ", error)
      return
    }

    guard let response = response as? HTTPURLResponse else {
      print("Dupa")
      return
    }
    if response.statusCode == 200 {
      guard let data = data else { return }
      do {
        let decodedCurrency = try JSONDecoder().decode(CurrencyResponse.self, from: data)
        let result = decodedCurrency.data[currencyB] ?? 750.0
        completion(result)
      } catch let error {
        print("Error decoding: ", error)
      }
    }
  }.resume()

}
