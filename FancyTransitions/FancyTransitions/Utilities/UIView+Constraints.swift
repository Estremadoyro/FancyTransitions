//
//  UIView+Constraints.swift
//  FancyTransitions
//
//  Created by Leonardo  on 22/04/23.
//

import UIKit

typealias FitFrameConstraints = (leading: NSLayoutConstraint, top: NSLayoutConstraint, width: NSLayoutConstraint, height: NSLayoutConstraint)
extension UIView {
    func fit(to nextView: UIView) {
        NSLayoutConstraint.activate([
            self.leadingAnchor.constraint(equalTo: nextView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: nextView.trailingAnchor),
            self.topAnchor.constraint(equalTo: nextView.topAnchor),
            self.bottomAnchor.constraint(equalTo: nextView.bottomAnchor)
        ])
    }
    
    @discardableResult
    func fit(nextView: UIView, frame: CGRect) -> FitFrameConstraints {
        let height: CGFloat = frame.size.height
        let width: CGFloat  = frame.size.width
        let xPos: CGFloat   = frame.minX
        let yPos: CGFloat   = frame.minY
        
        let leadingConstraint = self.leadingAnchor.constraint(equalTo: nextView.leadingAnchor, constant: xPos)
        let topConstraint = self.topAnchor.constraint(equalTo: nextView.topAnchor, constant: yPos)
        let widthConstraint = self.widthAnchor.constraint(equalToConstant: width)
        let heightConstraint = self.heightAnchor.constraint(equalToConstant: height)
        
        let constraints: [NSLayoutConstraint] = [leadingConstraint, topConstraint, widthConstraint, heightConstraint]
        NSLayoutConstraint.activate(constraints)
        
        return (leadingConstraint, topConstraint, widthConstraint, heightConstraint)
    }
}
