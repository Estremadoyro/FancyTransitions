//
//  AnimeDetailScreen.swift
//  FancyTransitions
//
//  Created by Leonardo  on 22/04/23.
//

import UIKit

enum HeaderSize {
    case big
    case small
}

final class AnimeDetailScreen: UIViewController {
    // MARK: State
    private let anime: Content
    private let mainSection: MainSection
    
    private var lastScrollOffset: CGFloat = 0
    private let screenSize: CGSize = UIScreen.main.bounds.size
    
    var coverViewAnimator: UIViewPropertyAnimator?
    
    private var coverContainerHeightConstraint: NSLayoutConstraint?
    private var maxCoverContainerHeight: CGFloat { mainSection.detailCoverImageSizeRatio.height * view.frame.size.height }
    private var minCoverContainerHeight: CGFloat { view.safeAreaInsets.top * 2 }
    
    /// # UI
    /// # Cover Image Container
    private lazy var coverContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.clipsToBounds = true
        
        self.view.insertSubview(view, aboveSubview: collectionView)
        return view
    }()

    /// # Cover Image
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        imageView.image = anime.image
        
        coverContainerView.addSubview(imageView)
        return imageView
    }()
    
    /// # Close Button
    private let closeButtonSize = CGSize(width: 30.0, height: 30.0)
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        button.backgroundColor = .black.withAlphaComponent(0.6)
        button.tintColor = .white
        button.layer.cornerRadius = 8.0
        
        view.insertSubview(button, aboveSubview: blurView)
        return button
    }()
    
    /// # Blur View
    private lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: nil)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = false
        
        self.view.insertSubview(view, aboveSubview: coverContainerView)
        return view
    }()
    
    /// # Header Title
    private var headerTitleLabelCenterYAnchor: NSLayoutConstraint?
    private let headerTitleLabelFont: UIFont = .systemFont(ofSize: 21, weight: .bold)
    private let headerTitleXPadding: CGFloat = 20.0
    private var maxHeaderYPadding: CGFloat = 0
    
    /// The trailing padding calculated considering the CloseButton's trailing padding & its width.
    private lazy var headerTitleTrailingPadding: CGFloat = headerTitleXPadding + closeButton.frame.size.width + 20.0
    
    /// The available max. width (In points) of the header title.
    private lazy var maxHeaderTitleWidth: CGFloat = screenSize.width - headerTitleXPadding - headerTitleTrailingPadding
    
    /// The size of the title with its font (The # of lines is not considered.)
    private var headerTitleFontSize: CGSize {
        let fontAttr = [NSAttributedString.Key.font: headerTitleLabelFont]
        
        let size = (anime.title as NSString).size(withAttributes: fontAttr)
        
        // Account for default paddings in X/Y directions.
        let yDefaultPadding: CGFloat = size.height * (1 - 0.98761)
        let xDefaultPadding: CGFloat = size.width * (1 - 0.99838)
        
        return CGSize(width: size.width + xDefaultPadding,
                      height: size.height + yDefaultPadding)
    }
    
    /// # Collapsed header
    private var headerCollapsedViewTopConstraint: NSLayoutConstraint?
    private var headerCollapsedView: UIView?
    
    /// Calculate if the title can fit in 1 line.
    private var headerTitleFitsInOneLine: Bool {
        let size = headerTitleFontSize
        return size.width <= maxHeaderTitleWidth
    }
    
    private var headerTitleLabel: UILabel?
    
    /// # Animators
    private let blurAnimator = UIViewPropertyAnimator(duration: 0.5, curve: .linear)
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = .zero
        layout.sectionInset = .init(top: maxCoverContainerHeight, left: 0, bottom: 0, right: 0)
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.delegate = self
        collection.dataSource = self
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceVertical = true
        collection.backgroundColor = .clear
        collection.register(AnimeInfoCell.self, forCellWithReuseIdentifier: String(describing: AnimeInfoCell.self))
        collection.register(AnimeTitleCell.self, forCellWithReuseIdentifier: String(describing: AnimeTitleCell.self))
        collection.contentInsetAdjustmentBehavior = .never
        
        view.addSubview(collection)
        return collection
    }()
    
    var viewsAreHidden: Bool = false {
        didSet {
            coverContainerView.isHidden = viewsAreHidden
            coverImageView.isHidden = viewsAreHidden
            closeButton.isHidden = viewsAreHidden
            collectionView.isHidden = viewsAreHidden
            blurView.isHidden = viewsAreHidden
            
            view.backgroundColor = viewsAreHidden ? .clear : .systemBackground
        }
    }
    
    // MARK: Initializers
    init(content: Content, mainSection: MainSection) {
        self.anime = content
        self.mainSection = mainSection
        
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { releaseDeinit() }
    
    // MARK: Methods
    func getCoverImageSizeRatio() -> SizeRatio {
        return mainSection.detailCoverImageSizeRatio
    }
    
    func getMainSection() -> MainSection {
        return mainSection
    }
}

// MARK: - LifeCycle
extension AnimeDetailScreen {
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutUI()
        view.addGestureRecognizer(collectionView.panGestureRecognizer)
        blurAnimator.addAnimations { [weak self] in
            self?.blurView.effect = UIBlurEffect(style: .dark)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("senku [DEBUG] \(String(describing: type(of: self))) - max height: \(maxCoverContainerHeight)")
        print("senku [DEBUG] \(String(describing: type(of: self))) - min height: \(minCoverContainerHeight)")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
}

// MARK: - UI
private extension AnimeDetailScreen {
    func releaseDeinit() {
        if blurAnimator.state != .inactive {
            blurAnimator.stopAnimation(false)
            blurAnimator.finishAnimation(at: .current)
        }
    }
    
    func layoutUI() {
        view.backgroundColor = .systemBackground
        layoutCollectionView()
        layoutCoverContainerView()
        layoutCoverImageView()
        layoutBlurView()
        layoutCloseButton()
    }
    
    func layoutCoverContainerView() {
        let (widthRatio) = mainSection.detailCoverImageSizeRatio.width
        NSLayoutConstraint.activate([
            coverContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coverContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: widthRatio),
            coverContainerView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        coverContainerHeightConstraint = coverContainerView.heightAnchor.constraint(equalToConstant: maxCoverContainerHeight)
        coverContainerHeightConstraint?.isActive = true
    }
    
    func layoutCoverImageView() {
        coverImageView.fit(to: coverContainerView)
    }
    
    func layoutBlurView() {
        blurView.fit(to: coverContainerView)
    }
    
    func layoutCollectionView() {
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func layoutCloseButton() {
        let (width, height, xPadding) = (closeButtonSize.width, closeButtonSize.height, 20.0)
//        let yPadding: CGFloat = (minCoverContainerHeight - view.safeAreaInsets.top) * 0.5 - height * 0.5
        print("top inset: \(view.safeAreaInsets.top)")
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -xPadding),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            closeButton.widthAnchor.constraint(equalToConstant: width),
            closeButton.heightAnchor.constraint(equalToConstant: height)
        ])
    }
    
    func layoutHeaderTitleLabel() {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.numberOfLines = 1
        label.textAlignment = .left
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacingBefore = 0
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: headerTitleLabelFont,
            .paragraphStyle: paragraphStyle
        ]
        let attrText = NSAttributedString(string: anime.title, attributes: textAttrs)
        label.attributedText = attrText
        label.alpha = 1
        
        blurView.contentView.addSubview(label)
        let xPadding: CGFloat = 20.0
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: xPadding),
            label.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -xPadding)
        ])
        
        /// Calculate the initial padding by substracting the bottomY - difference between button.height and headerTitle.height / 2
        let centerYPadding: CGFloat = (minCoverContainerHeight / 2) - (closeButtonSize.height - headerTitleFontSize.height) * 0.5
        maxHeaderYPadding = centerYPadding
        headerTitleLabelCenterYAnchor = label.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor,
                                                                       constant: centerYPadding)
        headerTitleLabelCenterYAnchor?.isActive = true
        
        headerTitleLabel = label
        print("font size: \(headerTitleFontSize)")
        view.layoutIfNeeded()
    }
    
    func layoutHeaderCollapsedView() {
        // Header view
        let headerView = UIView(frame: .zero)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(headerView)
        
        let xPadding: CGFloat = 20.0
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: xPadding),
            headerView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -xPadding),
        ])
        
        // view.safeAreaInsets.top
        let topPadding: CGFloat = minCoverContainerHeight - view.safeAreaInsets.top
        headerCollapsedViewTopConstraint = headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                                           constant: topPadding)
        headerCollapsedViewTopConstraint?.isActive = true
        
        // Anime title
        let titleLabel = layoutHeaderTitleLabelV2()
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor)
        ])
        
        // Anime info.
        let detailsStackView = layoutHeaderDetailsStack()
        headerView.addSubview(detailsStackView)
        
        NSLayoutConstraint.activate([
            detailsStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            detailsStackView.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor),
            detailsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            detailsStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        
        self.headerCollapsedView = headerView
        
        view.layoutIfNeeded()
    }
    
    func layoutHeaderTitleLabelV2() -> UILabel {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.font = .systemFont(ofSize: 18, weight: .heavy)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.text = anime.title
        
        return label
    }
    
    func layoutHeaderDetailsStack() -> UIStackView {
        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 4.0
        
        let item1 = layoutHeaderDetailItem(with: "Episodes: 1 - ")
        let item2 = layoutHeaderDetailItem(with: "Stars: 8.0 - ")
        let item3 = layoutHeaderDetailItem(with: "2023")
        
        stack.addArrangedSubview(item1)
        stack.addArrangedSubview(item2)
        stack.addArrangedSubview(item3)
        
        return stack
    }
    
    func layoutHeaderDetailItem(with text: String) -> UILabel {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.textAlignment = .left
        label.text = text
        
        return label
    }
}

extension AnimeDetailScreen: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        guard let cell = collectionView.cellForItem(at: indexPath) else { return .zero }
        let width = UIScreen.main.bounds.size.width
        let height = 100.0
        
        return CGSize(width: width, height: height)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 15
    }
}

extension AnimeDetailScreen: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.item {
            case 0: return dequeueTitleCell(at: indexPath)
            default: return dequeueInfoCell(at: indexPath)
        }
    }

    private func dequeueTitleCell(at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: AnimeTitleCell.self),
                                                            for: indexPath) as? AnimeTitleCell else {
            fatalError("Error dequeuing")
        }
        cell.setup(with: anime.title)
        return cell
    }

    private func dequeueInfoCell(at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: AnimeInfoCell.self),
                                                            for: indexPath) as? AnimeInfoCell else {
            fatalError("Error dequeuing")
        }
        
        cell.setup(anime: anime)
        return cell
    }
}

enum SwipeDirection {
    case up, down, middle
    init(difference: CGFloat) {
        switch difference {
            case 0: self = .middle
            case CGFloat(Int.min) ..< 0: self = .down
            default: self = .up
        }
    }
}

extension AnimeDetailScreen: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y
        let newHeight = maxCoverContainerHeight - yOffset

        if newHeight <= minCoverContainerHeight {
            coverContainerHeightConstraint?.constant = minCoverContainerHeight
            
            // Layout header title if needed.
            if headerCollapsedView == nil { layoutHeaderCollapsedView() }
            
            let newCollapsedHeaderYPadding = view.safeAreaInsets.top - (minCoverContainerHeight - newHeight)
            print("new padding: \(newCollapsedHeaderYPadding)")
            if newCollapsedHeaderYPadding >= 0 {
                headerCollapsedViewTopConstraint?.constant = newCollapsedHeaderYPadding
                headerCollapsedView?.alpha = 1 - (newCollapsedHeaderYPadding / view.safeAreaInsets.top)
            } else {
                headerCollapsedViewTopConstraint?.constant = 0
                headerCollapsedView?.alpha = 1
            }
            
        } else {
            coverContainerHeightConstraint?.constant = newHeight
            
            // Remove collapsed header if needed.
            if headerCollapsedView != nil { headerCollapsedView?.removeFromSuperview(); headerCollapsedView = nil }
        }
        
        updateCoverImageBlur()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print("Didd end draggin")
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        print("will decelerate")
    }
}

private extension AnimeDetailScreen {
    func checkCollectionReachedTheEnd(at currentOffset: CGFloat) -> Bool {
        // Get the content size of the collection view
        let contentSize = collectionView.contentSize

        // Get the size of the visible portion of the collection view
        let visibleSize = collectionView.bounds.size

        // Calculate the maximum content offset value
        let maximumOffset = contentSize.height - visibleSize.height
        
        return currentOffset >= maximumOffset
    }
    
    func updateCoverImageBlur() {
        let coverImageHeight: CGFloat = coverContainerHeightConstraint?.constant ?? 0
        let percentage: CGFloat = 1 - (coverImageHeight / maxCoverContainerHeight)
        blurAnimator.fractionComplete = percentage
    }
    
    @objc
    func dismissVC(_ button: UIButton) {
        self.dismiss(animated: true)
    }
}
