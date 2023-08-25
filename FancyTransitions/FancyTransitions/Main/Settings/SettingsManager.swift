//
//  SettingsManager.swift
//  FancyTransitions
//
//  Created by Leonardo  on 7/05/23.
//

import UIKit

final class SettingsManager {
    // MARK: State
    private lazy var settingsView: SettingsView = {
        let view = SettingsView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    // MARK: Initializers
    init() {}
    
    // MARK: Methods
    func getSettingsView() -> SettingsView {
        return settingsView
    }
    
    var durationSteppervalue: CGFloat { settingsView.durationSetepperValue }
}

final class SettingsView: UIView {
    // MARK: State
    private lazy var durationStepperView: UIStepper = {
        let stepper = UIStepper(frame: .zero)
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.minimumValue = 0.1
        stepper.maximumValue = 1
        stepper.value = 0.50
        stepper.stepValue = 0.05
        stepper.addTarget(self, action: #selector(durationStapperDidChange), for: .touchUpInside)
        
        insertSubview(stepper, aboveSubview: self)
        return stepper
    }()
    
    private lazy var durationStepperLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.numberOfLines = 1
        label.text = "Duration: \(durationStepperView.value)"
        
        addSubview(label)
        return label
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
    
    // MARK: Methods
    var durationSetepperValue: CGFloat { durationStepperView.value }
}

private extension SettingsView {
    func layoutUI() {
        backgroundColor = .systemPink
        layoutDurationStepperLabel()
        layoutDurationStepperView()
    }
    
    func layoutDurationStepperLabel() {
        NSLayoutConstraint.activate([
            durationStepperLabel.leadingAnchor.constraint(equalTo: durationStepperView.leadingAnchor),
            durationStepperLabel.topAnchor.constraint(equalTo: self.topAnchor)
        ])
    }
    
    func layoutDurationStepperView() {
        let xPadding: CGFloat = 5.0
        NSLayoutConstraint.activate([
            durationStepperView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: xPadding),
            durationStepperView.topAnchor.constraint(equalTo: durationStepperLabel.bottomAnchor),
        ])
    }
}

private extension SettingsView {
    @objc
    func durationStapperDidChange(_ stepper: UIStepper) {
        durationStepperLabel.text = String(format: "Duration: %.2f", stepper.value)
    }
}
