//
//  RxGithubViewControllerType.swift
//  Networking
//
//  Created by luojie on 16/7/14.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol RxGithubViewControllerType {
    associatedtype Model
    var disposeBag: DisposeBag { get set }
    var githubRequest: Github { get }
    var rx_userInterface: AnyObserver<Model> { get }
    func updateUI(with model: Model)
}

extension RxGithubViewControllerType where Self: UIViewController {
    
    var rx_userInterface: AnyObserver<Model> {
        return UIBindingObserver(UIElement: self) {
            selfvc, model in
            selfvc.updateUI(with: model)
            }.asObserver()
    }
    
    func setupRx() {
        
        githubRequest
            .rx_model(Model)
            .doOnError { error in print(error) }
            .bindTo(rx_userInterface)
            .addDisposableTo(disposeBag)
    }
}