//
//  MainScreen.swift
//  FancyTransitions
//
//  Created by Leonardo  on 22/04/23.
//

import UIKit

final class MainScreen: UIViewController {
    // MARK: State
    private let contents: [Content] = []
    
    private lazy var collectionDataSource = MainCollectionDataSource(contents: contents)
    
    private lazy var mainCollection: UICollectionView = {
        let collection = UICollectionView(frame: .zero)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.collectionViewLayout = UICollectionViewFlowLayout()
        collection.dataSource = collectionDataSource
        
        view.addSubview(collection)
        return collection
    }()
    
    // MARK: Initializers
    init() {
        super.init(nibName: nil, bundle: nil)
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
    }
}
