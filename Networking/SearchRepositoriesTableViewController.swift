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
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = nil
        tableView.delegate = nil
        
        searchBar.rx_text
            .filter { text in !text.isEmpty }
            .throttle(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .map { text in Github.searchRepositories(text: text) }
            .flatMapLatest { searchRepositories in
                searchRepositories.rx_model(Github.SearchRepositoriesResult.self)
            }
            .doOnError { error in print(error) }
            .bindTo(tableView.rx_itemsWithCellIdentifier("UITableViewCell")) { row, repository, cell in
                cell.textLabel?.text = repository.name
                cell.detailTextLabel?.text = repository.description
            }
            .addDisposableTo(disposeBag)
    }
}