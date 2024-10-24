//
//  SearchViewController.swift
//  Amor
//
//  Created by 양승혜 on 10/23/24.
//

import UIKit

final class SearchViewController: UIViewController {
    
    let dummyLabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.Size.caption
        label.text = "Search VC"
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .themeGray
        view.addSubview(dummyLabel)
        dummyLabel.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
    }
}
