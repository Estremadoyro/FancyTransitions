//
//  CardTransitionManager.swift
//  FancyTransitions
//
//  Created by Leonardo  on 22/04/23.
//

import UIKit

enum CardTransitionType {
    case presentation
    case dismissal
}

final class CardTransitionManager: NSObject {
    // MARK: State
    private let transitionDuration: CGFloat = 0.8
    private let shrinkDuration: CGFloat = 0.2

    private var transition: CardTransitionType = .presentation
    private let settingsManager: SettingsManager

    // Animator delegates
    weak var appStoreLikeAnimatorDelegate: AppStoreLikeAnimatorDelegate?

    // MARK: Animators
    private lazy var appstoreLikeAnimator = AppStoreLikeAnimator(transition: transition,
                                                                 settings: settingsManager,
                                                                 presentingDelegate: appStoreLikeAnimatorDelegate)

    // MARK: Initializers
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        super.init()
    }
}

// MARK: - Transition delegate
extension CardTransitionManager: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        appstoreLikeAnimator.transition = .presentation
        return appstoreLikeAnimator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        appstoreLikeAnimator.transition = .dismissal
        return appstoreLikeAnimator
    }
}
