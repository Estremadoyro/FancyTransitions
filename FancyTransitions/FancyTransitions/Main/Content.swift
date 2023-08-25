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
    var info: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: Content, rhs: Content) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(title: String, image: UIImage, info: String) {
        self.title = title
        self.image = image
        self.info = info
    }
    
    static func getDummyContent(count: Int) -> [Content] {
        return Array(0 ..< count)
            .map { Content(title: "Dr. Stone: New World \($0)",
                           image: UIImage(named: "dr-stone-banner")!,
                           info: "asjdf9fasjdf890asjdf8a9sdfjs98 djfas98df ja9ds8fj a98sj f9asdjf as8 j9sjf s jf9s8jsf")
            }
    }
}
