//
//  AppStoreLikeAnimator.swift
//  FancyTransitions
//
//  Created by Leonardo  on 22/04/23.
//

import UIKit

protocol AppStoreLikeAnimatorDelegate: AnyObject {
    func getSelectedCellView() -> UIView?
    func getSuperView() -> UIView
}

final class AppStoreLikeAnimator: NSObject {
    // MARK: State
    private let settingsManger: SettingsManager
    var transition: CardTransitionType
    
    private var transitionDuration: CGFloat { settingsManger.durationSteppervalue }
    
    // Views
    private var closeButtonView: UIView?
    private var closeButtonTopConstraint: NSLayoutConstraint?
    private var closeButtonTrailingConstraint: NSLayoutConstraint?
    
    // Delegates
    private weak var delegate: AppStoreLikeAnimatorDelegate?

    // Constraints
    private var cardLeadingConstraint: NSLayoutConstraint?
    private var cardWidthConstraint: NSLayoutConstraint?
    private var cardTopConstraint: NSLayoutConstraint?
    private var cardHeightConstraint: NSLayoutConstraint?
    
    // MARK: Initializers
    init(transition: CardTransitionType, settings: SettingsManager, presentingDelegate: AppStoreLikeAnimatorDelegate?) {
        self.transition = transition
        self.settingsManger = settings
        self.delegate = presentingDelegate
        
        super.init()
    }
}

extension AppStoreLikeAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard transition == .presentation else {
            transitionContext.completeTransition(true)
            return
        }
        // Remove all subviews
        let transitionContainer = transitionContext.containerView
        transitionContainer.subviews.forEach { $0.removeFromSuperview() }
        
        // Configure transition views.
        configureViews(in: transitionContainer)
        
        // Get the cover-image-view.
        guard let coverImageView = getCellCoverImageView(in: transitionContext) as? UIImageView else { return }
        
        // Get copy from the image-view to use in the transition-container
        let cardCopyView = createImageViewCopy(from: coverImageView)
        transitionContainer.addSubview(cardCopyView)
        
        guard let animeDetailVC: AnimeDetailScreen = getToVC(in: transitionContext) else { return }
        
        // Position the copy view in the container and hide the original
        positionCardCopy(cardCopyView, original: coverImageView, in: transitionContainer)
        positionCloseButtonView(superview: cardCopyView, in: transitionContainer)
        
        // Add the Presenting-VC's view to the TransitionContainer's subview hierarchy in order to make the AnimeDetail-VC visible.
        transitionContainer.addSubview(animeDetailVC.view)
        animeDetailVC.viewsAreHidden = true
        
        // Transition animation
        animateTransition(in: transitionContext, cardCopy: cardCopyView, animeDetailVC: animeDetailVC) { [weak self] _ in
            transitionContext.completeTransition(true)

            animeDetailVC.viewsAreHidden = false
            coverImageView.isHidden = false

            cardCopyView.removeFromSuperview()
            
            self?.closeButtonView = nil
            print("Full transition completed")
        }
    }
}

// MARK: - Implementation Detail
private extension AppStoreLikeAnimator {
    func configureViews(in containerView: UIView) {}
    
    func getCellCoverImageView(in context: UIViewControllerContextTransitioning) -> UIView? {
        // Get the both-ends controllers.
        // Each of these will update depending when preseting/dismissing.
        let toVC = context.viewController(forKey: .to)
        let fromVC = (context.viewController(forKey: .from) as? UINavigationController)?.topViewController
        
        switch transition {
            case .presentation:
                return (fromVC as? MainScreen)?.getSelectedCellView()
            case .dismissal:
                return (toVC as? MainScreen)?.getSelectedCellView()
        }
    }
    
    func createImageViewCopy(from imageView: UIImageView) -> UIImageView {
        let copy = UIImageView(image: imageView.image)
        copy.translatesAutoresizingMaskIntoConstraints = false
        copy.contentMode = .scaleAspectFill
        copy.clipsToBounds = true
        return copy
    }
    
    func positionCardCopy(_ coverImageViewCopy: UIImageView,
                          original cellCoverImageView: UIImageView,
                          in transitionContainer: UIView) {
        // Get absolute frame from Cover-image-view to Main-screen.
        let absoluteFrame = cellCoverImageView.convert(cellCoverImageView.frame, to: delegate?.getSuperView())
        
        // Constrain the copy-cover-image to the transition-container.
        let constraints = coverImageViewCopy.fit(nextView: transitionContainer, frame: absoluteFrame)
        (cardLeadingConstraint, cardTopConstraint, cardWidthConstraint, cardHeightConstraint) = constraints
        
        coverImageViewCopy.clipsToBounds = true
        coverImageViewCopy.layer.masksToBounds = true
        coverImageViewCopy.layer.cornerRadius = 12
        
        // Hide the original-cover-view as it is not neccessary anymore.
        cellCoverImageView.isHidden = true
        
        // This is A MUST before doing any animation, Transition-Container's layout must be up-to-date
        // or the constraints set in .fit will be also be animated making the animation start from x0 y0.
        transitionContainer.layoutIfNeeded()
    }
    
    func positionCloseButtonView(superview coverImageViewCopy: UIImageView, in transitionContainer: UIView) {
        closeButtonView = makeCloseButton()
        guard let closeButtonView else { return }
        coverImageViewCopy.addSubview(closeButtonView)
        
        let (width, height) = (30.00, 30.0)
        
        let topPaddingRatio: CGFloat = transitionContainer.safeAreaInsets.top / transitionContainer.frame.size.height
        let topPadding: CGFloat      = coverImageViewCopy.frame.size.height * topPaddingRatio
        
        let toVCTrailingPadding: CGFloat = 20.0
        let xPaddingRatio: CGFloat = toVCTrailingPadding / transitionContainer.frame.size.width
        let xPadding: CGFloat      = coverImageViewCopy.frame.size.width * xPaddingRatio
        
        let constraints: [NSLayoutConstraint] = [
            closeButtonView.widthAnchor.constraint(equalToConstant: width),
            closeButtonView.heightAnchor.constraint(equalToConstant: height)
        ]
        
        closeButtonTrailingConstraint = closeButtonView.trailingAnchor.constraint(equalTo: coverImageViewCopy.trailingAnchor,
                                                                                  constant: -xPadding)
        closeButtonTrailingConstraint?.isActive = true
        
        closeButtonTopConstraint = closeButtonView.topAnchor.constraint(equalTo: coverImageViewCopy.topAnchor,
                                                                        constant: topPadding)
        closeButtonTopConstraint?.isActive = true
        
        NSLayoutConstraint.activate(constraints)
        
        transitionContainer.layoutIfNeeded()
    }
    
    func getToVC<T: UIViewController>(in context: UIViewControllerContextTransitioning) -> T? {
        return context.viewController(forKey: .to) as? T
    }
}

// MARK: - Animations
// Animations needed:
// 1. Shrink card 0.8 & identity
// 2. Transition card to top
// 3. Expand to 1.2 & identity
private extension AppStoreLikeAnimator {
    func animateTransition(in context: UIViewControllerContextTransitioning,
                           cardCopy: UIView,
                           animeDetailVC: AnimeDetailScreen,
                           completion: @escaping (Bool) -> Void) {
        // Animators
        let shrinkAnimator = makeShrinkAnimator(in: context, cardCopy: cardCopy)
        let transitionAnimator = makeTransitionAnimator(in: context, cardCopy: cardCopy, animeDetailVC: animeDetailVC)
        
        let cornerAnimator = makeCornerAnimator(in: context, cardCopy: cardCopy)
        
        // Animators completions
        shrinkAnimator.addCompletion { _ in
            transitionAnimator.startAnimation()
        }
        
        transitionAnimator.addCompletion { _ in
            completion(true)
        }
        
        // Start animators
        cornerAnimator.startAnimation()
        shrinkAnimator.startAnimation()
        animateButtonTransition(in: context, cardCopy: cardCopy)
    }
    
    /// Shrinks the card.
    func makeShrinkAnimator(in context: UIViewControllerContextTransitioning, cardCopy: UIView) -> UIViewPropertyAnimator {
        return .init(duration: transitionDuration * 0.1, curve: .easeOut) {
            // Transformations
            cardCopy.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            
            // Sync. updates
            context.containerView.layoutIfNeeded()
        }
    }
    
    /// Transitions the card
    func makeTransitionAnimator(in context: UIViewControllerContextTransitioning, cardCopy: UIView, animeDetailVC: AnimeDetailScreen) -> UIViewPropertyAnimator {
        let springTiming = UISpringTimingParameters(dampingRatio: 0.8, initialVelocity: .init(dx: 0, dy: 4))
        let animator = UIViewPropertyAnimator(duration: transitionDuration * 0.9, timingParameters: springTiming)
        animator.addAnimations { [weak self] in
            guard let self else { return }
            // Re-position the card.
            self.cardLeadingConstraint?.constant = 0
            self.cardTopConstraint?.constant = 0
            self.cardWidthConstraint?.constant = context.containerView.frame.size.width * animeDetailVC.getCoverImageSizeRatio().width
            self.cardHeightConstraint?.constant = context.containerView.frame.size.height * animeDetailVC.getCoverImageSizeRatio().height
            
            // Revert transform.
            cardCopy.transform = .identity
            
            // Sync. updates
            context.containerView.layoutIfNeeded()
        }
        
        return animator
    }
    
    /// Animates the corner radius.
    func makeCornerAnimator(in context: UIViewControllerContextTransitioning, cardCopy: UIView) -> UIViewPropertyAnimator {
        return .init(duration: transitionDuration, curve: .linear) {
            cardCopy.layer.cornerRadius = 0
        }
    }
    
    func animateButtonTransition(in context: UIViewControllerContextTransitioning, cardCopy: UIView) {
        let transitionAnimator = makeButtonTransitionAnimator(in: context, cardCopy: cardCopy)
        let opacityAnimator = makeButtonOpacityAnimator()
        
        transitionAnimator.startAnimation()
        opacityAnimator.startAnimation()
    }
    
    func makeButtonTransitionAnimator(in context: UIViewControllerContextTransitioning, cardCopy: UIView) -> UIViewPropertyAnimator {
        return .init(duration: transitionDuration * 1/3, curve: .easeIn) { [weak self] in
            guard let self else { return }
            // Transition
            let newTopConstant = context.containerView.safeAreaInsets.top
            self.closeButtonTopConstraint?.constant = newTopConstant
            
            let newTrailingConstant = 20.0
            self.closeButtonTrailingConstraint?.constant = -newTrailingConstant
            
            // Fade in
            self.closeButtonView?.alpha = 1
            context.containerView.layoutIfNeeded()
        }
    }
    
    func makeButtonOpacityAnimator() -> UIViewPropertyAnimator {
        return .init(duration: transitionDuration, curve: .linear) { [weak self] in
            self?.closeButtonView?.alpha = 1
        }
    }
}

// MARK: - Additional Views
private extension AppStoreLikeAnimator {
    func makeCloseButton() -> UIView {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.backgroundColor = .black.withAlphaComponent(0.6)
        button.tintColor = .white
        button.layer.cornerRadius = 8.0
        button.alpha = 0
        
        return button
    }
}
