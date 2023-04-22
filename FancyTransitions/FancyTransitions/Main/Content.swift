//
//  Content.swift
//  FancyTransitions
//
//  Created by Leonardo  on 22/04/23.
//

import Foundation
import class UIKit.UIImage

struct Content: Hashable {
    var id = UUID()
    var title: String
    var image: UIImage
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: Content, rhs: Content) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(title: String, image: UIImage) {
        self.title = title
        self.image = image
    }
}
