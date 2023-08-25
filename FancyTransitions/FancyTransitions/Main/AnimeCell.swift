//
//  AnimeCell.swift
//  FancyTransitions
//
//  Created by Leonardo  on 22/04/23.
//

import UIKit

protocol FeedCell: UICollectionViewCell {
    func getImageView() -> UIImageView
}

final class AnimeCell: UICollectionViewCell {
    // MARK: State
    static let reuseID: String = String(describing: AnimeCell.self)
    var content: Content?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.systemBackground
        label.numberOfLines = 1
        label.font = .boldSystemFont(ofSize: 24.0)
        label.textAlignment = .left
        
        contentView.addSubview(label)
        return label
    }()
    
    private lazy var coverImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        
        contentView.addSubview(imageView)
        return imageView
    }()

    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        coverImageView.image = nil
        coverImageView.isHidden = false
    }

    // MARK: Methods
    func setup() {
        titleLabel.text = content?.title
        coverImageView.image = content?.image
    }
}

private extension AnimeCell {
    func layoutUI() {
        contentView.layer.cornerRadius = 12.0
        contentView.clipsToBounds = true
        
        layoutCoverImageView()
        layoutTitleLabel()
    }
    
    func layoutTitleLabel() {
        let padding: CGFloat = 10.0
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
    }
    
    func layoutCoverImageView() {
        NSLayoutConstraint.activate([
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

extension AnimeCell: FeedCell {
    func getImageView() -> UIImageView {
        return coverImageView
    }
}
