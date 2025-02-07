//
//  SpaceActiveViewController.swift
//  Amor
//
//  Created by 홍정민 on 10/30/24.
//

import UIKit
import SnapKit
import PhotosUI
import RxSwift
import RxCocoa
import Toast

enum SpaceActiveViewType {
    case create(SpaceSimpleInfo?)
    case edit(SpaceSimpleInfo)
    
    var navigationTitle: String {
        switch self {
        case .create:
            return "라운지 생성"
        case .edit:
            return "라운지 편집"
        }
    }
}

protocol SpaceActiveViewDelegate {
    func editComplete()
}

final class SpaceActiveViewController: BaseVC<SpaceActiveView> {
    var coordinator: SpaceActiveCoordinator?
    var delegate: SpaceActiveViewDelegate?
    let viewModel: SpaceActiveViewModel
    
    private let selectedImage = BehaviorRelay<UIImage?>(value: nil)
    private let selectedImageName = BehaviorRelay<String?>(value: nil)

    init(viewModel: SpaceActiveViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func configureNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: .xmark,
            style: .plain,
            target: self,
            action: nil
        )
        
        navigationItem.leftBarButtonItem?.tintColor = .themeBlack
    }

    override func bind() {
        let input = SpaceActiveViewModel.Input(
            viewWillAppearTrigger: rx.methodInvoked(#selector(self.viewWillAppear))
                .map { _ in },
            nameTextFieldText: baseView.nameTextFieldText(),
            descriptionTextFieldText: baseView.descriptionTextFieldText(),
            image: selectedImage, imageName: selectedImageName,
            buttonTap: baseView.confirmButtonTap()
        )

        let output = viewModel.transform(input)

        output.navigationTitle
            .bind(to: navigationItem.rx.title)
            .disposed(by: disposeBag)

        output.spaceImage
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, value in
                owner.baseView.setSpaceImageFromServer(image: value)
            }
            .disposed(by: disposeBag)

        output.confirmButtonEnabled
            .bind(with: self) { owner, value in
                owner.baseView.completeButtonEnabled(isEnabled: value)
            }
            .disposed(by: disposeBag)
        
        output.createComplete
            .bind(with: self) { owner, value in
                owner.coordinator?.dismissSheetFlow(isCreated: true)
                switch owner.viewModel.viewType {
                case .create:
                    break
                case .edit:
                    owner.delegate?.editComplete()
                }
            }
            .disposed(by: disposeBag)
        
        navigationItem.leftBarButtonItem?.rx.tap
            .bind(with: self) { owner, _ in
                owner.coordinator?.dismissSheetFlow()
            }
            .disposed(by: disposeBag)
        
        baseView.cameraButtonTap()
            .bind(with: self) { owner, _ in
                owner.showPHPickerView()
            }
            .disposed(by: disposeBag)
        
        selectedImage
            .bind(with: self) { owner, value in
                owner.baseView.setSpaceImageFromPicker(image: value)
            }
            .disposed(by: disposeBag)
        
        output.showToast
            .bind(with: self) { owner, value in
                owner.baseView.makeToast(value)
            }
            .disposed(by: disposeBag)
    }
}

extension SpaceActiveViewController: PHPickerViewControllerDelegate {
    func showPHPickerView() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.selection = .default
        configuration.filter = .images
        
        let pickerView = PHPickerViewController(configuration: configuration)
        pickerView.delegate = self
        present(pickerView, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let itemProvider = results.first?.itemProvider else { return }
            itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.selectedImage.accept(image)
                        self.selectedImageName.accept(Date().toServerDateStr())
                }
            }
        }
    }
}
