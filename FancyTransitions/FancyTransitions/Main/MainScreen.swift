//
//  MainScreen.swift
//  FancyTransitions
//
//  Created by Leonardo  on 22/04/23.
//

import UIKit

typealias SizeRatio = (width: CGFloat, height: CGFloat)
enum MainSection {
    case trailer
    case anime
    
    init(_ value: Int) {
        switch value {
            case 0: self = .trailer
            case 1: self = .anime
            default: self = .trailer
        }
    }
    
    var detailCoverImageSizeRatio: SizeRatio {
        switch self {
            case .trailer:
                return SizeRatio(width: 1, height: 0.25)
            case .anime:
                return SizeRatio(width: 1, height: 0.7)
        }
    }
}

final class MainScreen: UIViewController {
    // MARK: State
    private let contents: [Content] = Content.getDummyContent(count: 3)
    private let screenSize: CGSize = UIScreen.main.bounds.size
    
    private(set) lazy var collectionDataSource = MainCollectionDataSource(contents: contents)
    
    private let settingsManager = SettingsManager()
    private lazy var transitionManager = CardTransitionManager(settingsManager: settingsManager)
    
    private lazy var mainCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = .init(top: 20, left: 0, bottom: 0, right: 0)
        
        let collection = UICollectionView(frame: .zero,
                                          collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.dataSource = collectionDataSource
        collection.delegate = self
        collection.register(AnimeCell.self, forCellWithReuseIdentifier: AnimeCell.reuseID)
        collection.backgroundColor = UIColor.systemBackground
        collection.contentInset = .init(top: 0, left: 20, bottom: 0, right: 20)
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        
        view.addSubview(collection)
        return collection
    }()
    
    // MARK: Initializers
    init() {
        super.init(nibName: nil, bundle: nil)
        transitionManager.appStoreLikeAnimatorDelegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Lifecycle
extension MainScreen {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        navigationItem.title = "Fancy Transitions"
        layoutUI()
    }
}

// MARK: - CollectionDelegate
extension MainScreen: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionStyle = MainSection(indexPath.section)
        
        var width: CGFloat
        var height: CGFloat
        switch sectionStyle {
            case .trailer:
                width = screenSize.width * 0.9
                height = screenSize.width * 0.4
            case .anime:
                height = 300.0
                width = height / 1.66
        }
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let anime = contents[indexPath.item]
        let section = MainSection(indexPath.section)
        
        transitionToDetail(with: anime, in: section)
    }
}

// MARK: - Transitions
private extension MainScreen {
    func transitionToDetail(with content: Content, in section: MainSection) {
        let animeDetailVC = AnimeDetailScreen(content: content, mainSection: section)
        animeDetailVC.modalPresentationStyle = .overCurrentContext
        animeDetailVC.transitioningDelegate = transitionManager
        
        present(animeDetailVC, animated: true)
    }
}

// MARK: - UI
private extension MainScreen {
    func layoutUI() {
        let settingsView = layoutSettingsView()
        layoutMainCollection(settingsView: settingsView)
    }
    
    func layoutMainCollection(settingsView: SettingsView) {
        NSLayoutConstraint.activate([
            mainCollection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainCollection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainCollection.topAnchor.constraint(equalTo: settingsView.bottomAnchor),
            mainCollection.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func layoutSettingsView() -> SettingsView {
        let settingsView = settingsManager.getSettingsView()
        settingsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsView)
        
        let height: CGFloat = 50.0
        NSLayoutConstraint.activate([
            settingsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            settingsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            settingsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            settingsView.heightAnchor.constraint(equalToConstant: height)
        ])
        
        return settingsView
    }
}

// MARK: - AppStoreLikeAnimator delegate
extension MainScreen: AppStoreLikeAnimatorDelegate {
    func getSelectedCellView() -> UIView? {
        guard let indexPath = mainCollection.indexPathsForSelectedItems?.first else { return nil }
        guard let cell = mainCollection.cellForItem(at: indexPath) as? FeedCell else { return nil }
        
        return cell.getImageView()
    }
    
    func getSuperView() -> UIView {
        return view
    }
}
