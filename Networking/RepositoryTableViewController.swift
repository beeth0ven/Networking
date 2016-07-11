//
//  RepositoryTableViewController.swift
//  SeverRequest
//
//  Created by luojie on 16/7/11.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import UIKit

class RepositoryTableViewController: UITableViewController {
    
    var user = "beeth0ven", name = "Timer"
    
    private var repository: Repository! {
        didSet { updateUI() }
    }
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var languageLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var urlLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Github.getRepository(user: user, name: name,
                didGet: { repo in self.repository = repo },
                didFail: { error in print(error) }
        )
    }
    
    func updateUI() {
        nameLabel.text        = repository.name
        languageLabel.text    = repository.language
        descriptionLabel.text = repository.description
        urlLabel.text         = repository.url
    }
}