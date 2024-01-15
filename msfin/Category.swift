//
//  Category.swift
//  msfin
//
//  Created by Kajetan Patryk Zarzycki on 15/01/2024.
//

import Foundation
import SwiftData

@Model
class Category {
    var id: UUID
    var name: String
    var image: String
    
    init(name: String, image: String) {
        self.id = UUID()
        self.name = name
        self.image = image
    }
}
