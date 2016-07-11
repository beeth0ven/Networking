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
    
    private var repository: Repository! {
        didSet { updateUI() }
    }
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var languageLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var urlLabel: UILabel!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Github.getRepository(user: user, name: name)
            .observeOn(MainScheduler.instance)
            .doOnNext { [unowned self] repo in self.repository = repo }
            .subscribeError { error in print(error) }
            .addDisposableTo(disposeBag)

    }
    
    func updateUI() {
        nameLabel.text        = repository.name
        languageLabel.text    = repository.language
        descriptionLabel.text = repository.description
        urlLabel.text         = repository.url
    }
}