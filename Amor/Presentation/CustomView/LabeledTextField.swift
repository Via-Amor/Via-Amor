//
//  LabeledTextField.swift
//  Amor
//
//  Created by 양승혜 on 10/28/24.
//

import UIKit
import SnapKit

final class LabeledTextField: UIView {

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .fill
        return stack
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.title2
        label.textColor = .black
        return label
    }()
    
    let textField: SignTextField
    
    // MARK: - Initialization
    init(title: String, placeholderText: String, fontSize: UIFont = UIFont.body) {
        self.textField = SignTextField(placeholderText: placeholderText, fontSize: fontSize)
        super.init(frame: .zero)
        
        titleLabel.text = title
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupLayout() {
        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(textField)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
