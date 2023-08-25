//
//  AnimeInfoCell.swift
//  FancyTransitions
//
//  Created by Leonardo  on 7/05/23.
//

import UIKit

final class AnimeInfoCell: UICollectionViewCell {
    // MARK: State
    private lazy var infoLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.numberOfLines = 0
        
        contentView.addSubview(label)
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        infoLabel.text = nil
    }
    
    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Methods
    func setup(anime: Content) {
        infoLabel.text = anime.info
    }
}

private extension AnimeInfoCell {
    func layoutUI() {
        layoutInfoLabel()
    }
    
    func layoutInfoLabel() {
        contentView.translatesAutoresizingMaskIntoConstraints = true
        contentView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width).isActive = true
        
        let xPadding = 20.0
        NSLayoutConstraint.activate([
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: xPadding),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -xPadding),
            infoLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            infoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}
