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
    let rx_repository = FlatVariable(Github.getRepository(user: "beeth0ven", name: "Timer"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupRx()
        
        rx_repository.asObservable()
            .doOnNext { print("4", $0) }
            .doOnError { print($0) }
            .subscribeNext { [unowned self] in self.updateUI(with: $0) }
            .addDisposableTo(disposeBag)
    }
    
    @IBAction func doEdit(sender: UIBarButtonItem) {
        rx_repository.value = Repository(
            name: "luojie",
            language: "luojie",
            description: "luojie",
            url: "luojie"
            )
    }
    
    @IBAction func refresh(sender: UIBarButtonItem) {
        rx_repository.refresh()
    }
    
    func updateUI(with model: Repository) {
        nameLabel.text        = model.name
        languageLabel.text    = model.language
        descriptionLabel.text = model.description
        urlLabel.text         = model.url
    }
}

//extension RepositoryTableViewController: RxModelViewControllerType {
//    
//    typealias Model = Repository
//    
//    var rx_model: Observable<Model> {
//        return Github.getRepository(user: user, name: name)
//    }
//    
//    func updateUI(with model: Model) {
//        nameLabel.text        = model.name
//        languageLabel.text    = model.language
//        descriptionLabel.text = model.description
//        urlLabel.text         = model.url
//    }
//}