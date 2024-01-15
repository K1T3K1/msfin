//
//  MainView.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 08/01/2024.
//

import SwiftUI

struct MainView: View {
  var body: some View {
    VStack {
        List {
            NavigationLink(destination: TransactionListView()) {
                Text("Transactions")
            }
            NavigationLink(destination: AccountsView()) {
                Text("Accounts")
            }
        }

    }
  }
}

#Preview {
  MainView()
}
