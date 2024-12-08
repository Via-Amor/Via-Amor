//
//  CustomAlert.swift
//  Amor
//
//  Created by 김상규 on 11/30/24.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class CustomAlert: BaseView {
    enum AlertButtonType {
        case oneButton
        case twoButton
    }
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let entireStackView = UIStackView()
    let contentStackView = UIStackView()
    let buttonStackView = UIStackView()
    lazy var confirmButton = CommonButton(
        title: AlertText.AlertButtonText.confirm.rawValue,
        foregroundColor: .themeWhite,
        backgroundColor: .themeGreen
    )
    var cancelButton = CommonButton(
        title: AlertText.AlertButtonText.cancel.rawValue,
        foregroundColor: .themeWhite,
        backgroundColor: .themeInactive
    )

    let alertButtonType: AlertButtonType
    
    init(alertType: AlertButtonType) {
        self.alertButtonType = alertType
        
        super.init(frame: .zero)
        configureHierarchy()
        configureLayout()
    }
    
    override func configureHierarchy() {
        addSubview(containerView)
        containerView.addSubview(entireStackView)
        entireStackView.addArrangedSubview(contentStackView)
        entireStackView.addArrangedSubview(buttonStackView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(subtitleLabel)
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(confirmButton)
    }
    
    override func configureLayout() {
        containerView.snp.makeConstraints { make in
            make.center.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(24)
            make.top.greaterThanOrEqualTo(safeAreaLayoutGuide).offset(24)
            make.bottom.lessThanOrEqualTo(safeAreaLayoutGuide).offset(-24)
        }
        
        entireStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    
    override func configureView() {
        self.backgroundColor = .black.withAlphaComponent(0.4)
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
        
        entireStackView.axis = .vertical
        entireStackView.spacing = 16
        
        contentStackView.axis = .vertical
        contentStackView.spacing = 8
        
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 8
        
        titleLabel.font = .title2
        titleLabel.textAlignment = .center
        
        subtitleLabel.font = .body
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        
        if alertButtonType == .oneButton {
            cancelButton.isHidden = true
        }
    }
    
    func configureContent(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        
        if title.isEmpty {
            titleLabel.isHidden = true
        }
        
        if subtitle.isEmpty {
            subtitleLabel.isHidden = true
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cancelButtonTap() -> ControlEvent<Void> {
        return cancelButton.rx.tap
    }
    
    func confirmButtonTap() -> ControlEvent<Void> {
        return confirmButton.rx.tap
    }
}
