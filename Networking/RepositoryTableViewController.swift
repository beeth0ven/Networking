//
//  RepositoryTableViewController.swift
//  SeverRequest
//
//  Created by luojie on 16/7/11.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RepositoryTableViewController: UITableViewController {
    
    var user = "beeth0ven", name = "Timer"
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var languageLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var urlLabel: UILabel!
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRx()
    }
}

extension RepositoryTableViewController: RxGithubViewControllerType {
    
    typealias Model = Repository
    
    var githubRequest: Github {
        return Github.getRepository(user: user, name: name)
    }
    
    func updateUI(with model: Model) {
        nameLabel.text        = model.name
        languageLabel.text    = model.language
        descriptionLabel.text = model.description
        urlLabel.text         = model.url
    }
}