//
//  OrganizationTableViewController.swift
//  Networking
//
//  Created by luojie on 16/7/14.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class OrganizationTableViewController: UITableViewController {
    
    var name = "Apple"
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var blogURLLabel: UILabel!
    @IBOutlet private weak var htmlURLLabel: UILabel!
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRx()
    }
}

extension OrganizationTableViewController: RxModelViewControllerType {
    
    typealias Model = Organization
    
    var rx_model: Observable<Model> {
        return Github.getOrganization(name: name)
    }
    
    func updateUI(with model: Model) {
        nameLabel.text        = model.name
        locationLabel.text    = model.location
        blogURLLabel.text     = model.blogURL
        htmlURLLabel.text     = model.htmlURL
    }
}
