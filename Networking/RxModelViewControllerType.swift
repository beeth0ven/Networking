//
//  RxModelViewControllerType.swift
//  Networking
//
//  Created by luojie on 16/8/11.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


protocol RxModelViewControllerType {
    associatedtype Model
    var disposeBag: DisposeBag { get set }
    var rx_model: Observable<Model> { get }
    var rx_userInterface: AnyObserver<Model> { get }
    func updateUI(with model: Model)
}

extension RxModelViewControllerType where Self: UIViewController {
    
    var rx_userInterface: AnyObserver<Model> {
        return UIBindingObserver(UIElement: self) {
            selfvc, model in
            selfvc.updateUI(with: model)
            }.asObserver()
    }
    
    func setupRx() {
        
        rx_model
            .doOnError { error in print(error) }
            .bindTo(rx_userInterface)
            .addDisposableTo(disposeBag)
    }
}


class RepositoryViewController: UITableViewController {
    
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

extension RepositoryViewController: RxModelViewControllerType {
    
    typealias Model = Repository
    
    var rx_model: Observable<Model> {
        return Git.getRepository(user: user, name: name)
    }
    
    func updateUI(with model: Model) {
        nameLabel.text        = model.name
        languageLabel.text    = model.language
        descriptionLabel.text = model.description
        urlLabel.text         = model.url
    }
}

