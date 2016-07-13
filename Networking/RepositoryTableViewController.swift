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
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Github.getRepository(user: user, name: name)
            .rx_model(Github.GetRepositoryResult.self)
            .doOnError { error in print(error) }
            .bindTo(rx_userInterface)
            .addDisposableTo(disposeBag)

    }
    
    var rx_userInterface: AnyObserver<Repository> {
        return UIBindingObserver(UIElement: self) {
            repositoryTableViewController, repository in
            repositoryTableViewController.nameLabel.text        = repository.name
            repositoryTableViewController.languageLabel.text    = repository.language
            repositoryTableViewController.descriptionLabel.text = repository.description
            repositoryTableViewController.urlLabel.text         = repository.url
        }.asObserver()
    }
}