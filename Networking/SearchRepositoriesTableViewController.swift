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
    
    let rx_repositories = Scan(seed: [Repository]())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = nil
        tableView.delegate = nil
        
        rx_repositories
            .asObservable()
            .bindTo(tableView.rx_itemsWithCellIdentifier("UITableViewCell")) { row, repository, cell in
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
            .subscribeNext { [unowned self] (repositories) in
                self.rx_repositories.updateElement.value = { items in
                    items += repositories
                }
            }
            .addDisposableTo(disposeBag)
        
        tableView.rx_itemDeleted
            .subscribeNext { [unowned self] indexPath in
                self.rx_repositories.updateElement.value = { items in
                    items.removeAtIndex(indexPath.row)
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    @IBAction func doAdd(sender: UIBarButtonItem) {
        rx_repositories.updateElement.value = { items in
            let r = Repository(name: "luojie", language: "luojie", description: "luojie", url: "luojie")
            items.insert(r, atIndex: 0)
        }
    }
    
}

struct Scan<Element> {
    
    let updateElement: Variable<((inout Element) -> Void)> = Variable ({ _ in })
    
    var seed: Element
    
    func asObservable() -> Observable<Element> {
        return updateElement
            .asObservable()
            .scan(seed) { (element, updateElement) -> Element in
                var element = element
                updateElement(&element);
                return element
        }
        
    }
}
