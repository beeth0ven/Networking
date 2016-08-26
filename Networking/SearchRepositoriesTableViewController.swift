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
    
    typealias RxRepositories = Scan<[Repository]>
    let rx_repositories: RxRepositories = Scan(seed: [])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.becomeFirstResponder()
        
        tableView.dataSource = nil
        tableView.delegate = nil
        
        rx_repositories
            .asDriver()
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
            .map { (repositories) -> RxRepositories.Updated in
                return { items in items += repositories }
            }
            .bindTo(rx_repositories.updated)
            .addDisposableTo(disposeBag)
        
        addBarButtonItem.rx_tap
            .map { () -> RxRepositories.Updated in
                return { repositories in
                    let repository = Repository(name: "luojie", language: "luojie", description: "luojie", url: "luojie")
                    repositories.insert(repository, atIndex: 0)
                }
            }
            .bindTo(rx_repositories.updated)
            .addDisposableTo(disposeBag)

        
        tableView.rx_itemDeleted
            .map { indexPath -> RxRepositories.Updated in
                return { repositories in repositories.removeAtIndex(indexPath.row) }
            }
            .bindTo(rx_repositories.updated)
            .addDisposableTo(disposeBag)
    }
    
}