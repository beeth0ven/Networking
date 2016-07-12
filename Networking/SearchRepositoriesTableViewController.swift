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
    
    private var repositories = [Repository]() {
        didSet { tableView.reloadData() }
    }
    
    @IBOutlet private weak var searchBar: UISearchBar!
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.rx_text
            .filter { text in !text.isEmpty }
            .throttle(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { text in Github.searchRepositories(text: text) }
            .observeOn(MainScheduler.instance)
            .doOnNext { [unowned self] repositories in self.repositories = repositories }
            .subscribeError { error in print(error) }
            .addDisposableTo(disposeBag)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UITableViewCell")!
        let repository = repositories[indexPath.row]
        cell.textLabel?.text        = repository.name
        cell.detailTextLabel?.text  = repository.description
        return cell
    }
}