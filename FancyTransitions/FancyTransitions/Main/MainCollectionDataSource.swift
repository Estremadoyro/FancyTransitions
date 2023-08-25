//
//  MainCollectionDataSource.swift
//  FancyTransitions
//
//  Created by Leonardo  on 22/04/23.
//

import UIKit

protocol CollectionDataSource: AnyObject {
    func numberOfSections() -> Int
    func numberOfItemsInSection(_ collectionView: UICollectionView, section: Int) -> Int
    func dequeueCellAt(_ collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell
}

final class MainCollectionDataSource: NSObject {
    // MARK: State
    private let contents: [Content]
    
    // MARK: Initializers
    init(contents: [Content]) {
        self.contents = contents
        
        super.init()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Methods
}

extension MainCollectionDataSource: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        contents.isEmpty ? 0 : 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        contents.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AnimeCell.reuseID,
                                                      for: indexPath) as! AnimeCell
        cell.content = contents[indexPath.item]
        cell.setup()
        return cell
    }
}
