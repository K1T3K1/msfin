//
//  CategoryView.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 15/01/2024.
//

import SwiftUI
import SwiftData
import SFSymbolsPicker
import AlertToast

struct CategoryView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var allowAdd: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
            ForEach(categories) { category in
                NavigationLink(destination: AddCategoryView()) {
                    VStack{
                        HStack{
                            Image(systemName: category.image)
                            Text(category.name)
                            }
                        Divider()
                        }
                    .padding()
                    .frame(maxWidth: 300)
                }
                .backgroundStyle(.clear)
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: 5))
            }
          }
        }.toolbar {
            ToolbarItem {
              Button(action: { withAnimation { allowAdd.toggle() } }) {
                Image(systemName: "plus")
                  .renderingMode(.template)
              }
              .sheet(
                isPresented: $allowAdd,
                content: {
                  AddCategoryView()
                })
            }
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var categoryName: String = ""
    @State private var icon = "star.fill"
    @State private var isPresented = false
    @State private var showError: Bool = false
    @State private var errorText: String = ""
    
    var body: some View {
        VStack {
            Text("Add category")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .padding()
            HStack {
                Text("Name: ")
                    .fontWeight(.heavy)
                TextField("", text: $categoryName) }
            Button("Select a symbol") {
                isPresented.toggle()
            }
            Image(systemName: icon).font(.title3)
                .sheet(isPresented: $isPresented, content: {
                    SymbolsPicker(selection: $icon, title: "Pick a symbol", autoDismiss: true)
                }).padding()
            Button("Submit") {
                submitCategory()
            }
        }
        .toast(isPresenting: $showError) {
          AlertToast(
            displayMode: .alert, type: .error(.red), title: errorText)
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
        .frame(maxWidth: 350)
    }
    
    func submitCategory() {
        if categoryName == "" {
            errorText = "Category name cannot be empty"
            showError.toggle()
        } else {
            let category = Category(name: categoryName, image: icon)
            modelContext.insert(category)
            dismiss()
        }
    }
}

struct EditCategoryView: View {
    @Bindable public var category: Category
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
            Text("")
    }
    
}

#Preview {
    MainActor.assumeIsolated {
      CategoryView().modelContainer(PreviewModelContainer)
    }
}
