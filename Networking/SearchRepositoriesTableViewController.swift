//
//  SearchRepositoriesTableViewController.swift
//  Networking
//
//  Created by luojie on 16/7/12.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SearchRepositoriesTableViewController: UITableViewController {
    
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet weak var addBarButtonItem: UIBarButtonItem!
    
    let disposeBag = DisposeBag()
    
    let repositories = Variable<[Repository]>([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.becomeFirstResponder()
        
        tableView.dataSource = nil
        tableView.delegate = nil
        
        repositories.asDriver()
            .drive(tableView.rx_itemsWithCellIdentifier("UITableViewCell")) { row, repository, cell in
                cell.textLabel?.text = repository.name
                cell.detailTextLabel?.text = repository.description
            }
            .addDisposableTo(disposeBag)
        
        searchBar.rx_text
            .filter { text in !text.isEmpty }
            .throttle(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { text in Github.searchRepositories(text: text) }
            .doOnError { error in print(error) }
            .bindTo(repositories)
            .addDisposableTo(disposeBag)
        
        addBarButtonItem.rx_tap.asDriver()
            .driveNext { [unowned self] in
                let repository = Repository(name: "luojie", language: "luojie", description: "luojie", url: "luojie")
                self.repositories.value.insert(repository, atIndex: 0)
            }
            .addDisposableTo(disposeBag)

        
        tableView.rx_itemDeleted.asDriver()
            .driveNext { [unowned self] indexPath in
                self.repositories.value.removeAtIndex(indexPath.row)
            }
            .addDisposableTo(disposeBag)
    }
    
}