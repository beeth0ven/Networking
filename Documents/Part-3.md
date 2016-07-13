# 中级 - RxSwift + Bind

在 [Part-2](https://github.com/beeth0ven/Networking/blob/master/Documents/Part-2.md) 中提到了如何使用 [RxSwift](https://github.com/ReactiveX/RxSwift) 来进行网络请求,并通过原生的方式刷新页面.

现在介绍一下如何使用  [RxSwift](https://github.com/ReactiveX/RxSwift) 的方式来刷新页面.

在 SearchRepositoriesTableViewController 中找到: 

```swift
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
```

将它改为：

```swift
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
            .flatMapLatest { text in Github.searchRepositories(text: text) }
            .observeOn(MainScheduler.instance)
            .doOnError { error in print(error) }
            .bindTo(tableView.rx_itemsWithCellIdentifier("UITableViewCell")) { row, repository, cell in
                cell.textLabel?.text = repository.name
                cell.detailTextLabel?.text = repository.description
            }
            .addDisposableTo(disposeBag)
    }
}
```

这里 RxSwift 变换了 tableView 的构建方式,

以前:

**text -> [Repository] -> numberOfRowsInSection -> cellForRowAtIndexPath -> indxPath -> Repository -> Cell**

现在：

**text -> [Repository] -> Repository -> Cell**

这种逻辑比以前简单了许多.

而且这种转换流程更符合我们的思维方式.

我们用这种方式重构一下 RepositoryTableViewController：

```swift
class RepositoryTableViewController: UITableViewController {
    
    var user = "beeth0ven", name = "Timer"
    
    private var repository: Repository! {
        didSet { updateUI() }
    }
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var languageLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var urlLabel: UILabel!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Github.getRepository(user: user, name: name)
            .observeOn(MainScheduler.instance)
            .doOnNext { [unowned self] repo in self.repository = repo }
            .subscribeError { error in print(error) }
            .addDisposableTo(disposeBag)

    }
    
    func updateUI() {
        nameLabel.text        = repository.name
        languageLabel.text    = repository.language
        descriptionLabel.text = repository.description
        urlLabel.text         = repository.url
    }
}
```

改为：

```swift
class RepositoryTableViewController: UITableViewController {
    
    var user = "beeth0ven", name = "Timer"
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var languageLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var urlLabel: UILabel!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Github.getRepository(user: user, name: name)
            .observeOn(MainScheduler.instance)
            .doOnError { error in print(error) }
            .bindTo(rx_userInterface)
            .addDisposableTo(disposeBag)

    }
    
    var rx_userInterface: AnyObserver<Repository> {
        return UIBindingObserver(UIElement: self) {
            repositoryTableViewController, repository in
            repositoryTableViewController.nameLabel.text        = repository.name
            repositoryTableViewController.languageLabel.text    = repository.language
            repositoryTableViewController.descriptionLabel.text = repository.description
            repositoryTableViewController.urlLabel.text         = repository.url
        }.asObserver()
    }
}
```

将可被观测的 Repository 绑定到观测者 Repository:

**Observable\<Repository\>   --Bind-->   AnyObserver\<Repository\>**

可被观测的 Repository 是 Github.getRepository(user: user, name: name) -> Observable\<Repository\>

而观测者 Repository 就是 var rx_userInterface: AnyObserver\<Repository\> :

```swift
class RepositoryTableViewController: UITableViewController {
    ...
    var rx_userInterface: AnyObserver<Repository> {
        return UIBindingObserver(UIElement: self) {
            repositoryTableViewController, repository in
            repositoryTableViewController.nameLabel.text        = repository.name
            repositoryTableViewController.languageLabel.text    = repository.language
            repositoryTableViewController.descriptionLabel.text = repository.description
            repositoryTableViewController.urlLabel.text         = repository.url
        }.asObserver()
    }
}
```

当观测者收到 Repository 更新的通知后，就运行 Closure 里面的代码：

```swift
    		                                     ... {
            repositoryTableViewController, repository in
            repositoryTableViewController.nameLabel.text        = repository.name
            repositoryTableViewController.languageLabel.text    = repository.language
            repositoryTableViewController.descriptionLabel.text = repository.description
            repositoryTableViewController.urlLabel.text         = repository.url
        } ...
```

当然就是刷新页面.

### 重构网络请求
	
现在看一下执行网络请求的方法:

```swift
struct Github {
    
    static func getRepository(user user: String, name: String) -> Observable<Repository> {
        
        return Observable.create { observer -> Disposable in
            
            let baseURLString = "https://api.github.com"
            let path = "/repos/\(user)/\(name)"
            let url = NSURL(string: baseURLString + path)!
            
            let request =  Alamofire
                .request(.GET, url)
                .responseJSON { response in
                    switch response.result {
                    case .Success(let json):
                        let repository = Repository(json: json)
                        observer.onNext(repository)
                        observer.onCompleted()
                    case .Failure(let error):
                        observer.onError(error)
                    }
            }
            
            return AnonymousDisposable {
                request.cancel()
            }
        }
    }
    
    static func searchRepositories(text text: String) -> Observable<[Repository]> {
        
        return Observable.create { observer -> Disposable in
            
            let baseURLString = "https://api.github.com"
            let path = "/search/repositories"
            let url = NSURL(string: baseURLString + path)!
            let parameters = ["q": text]
            
            let request =  Alamofire
                .request(.GET, url, parameters: parameters, encoding: .URL)
                .responseJSON { response in
                    switch response.result {
                    case .Success(let json):
                        let jsons = (json as? NSDictionary)?.valueForKey("items") as? [AnyObject]
                        let repositories = jsons?.map(Repository.init) ?? []
                        observer.onNext(repositories)
                        observer.onCompleted()
                    case .Failure(let error):
                        observer.onError(error)
                    }
            }
            
            return AnonymousDisposable {
                request.cancel()
            }
        }
    }
}
```

对比两个网络请求后,可以发现一些重复的代码：

```swift
struct Github {
    
    static func getRepository(user user: String, name: String) -> Observable<Repository> {
        
        return Observable.create { observer -> Disposable in
            
            let baseURLString = "https://api.github.com"
            ...
            let url = NSURL(string: baseURLString + path)!
            ...
                .responseJSON { response in
                    switch response.result {
                    case .Success(let json):
                        ...
                        observer.onNext(repository)
                        observer.onCompleted()
                    case .Failure(let error):
                        observer.onError(error)
                    }
            }
            
            return AnonymousDisposable {
                request.cancel()
            }
        }
    }
    
    static func searchRepositories(text text: String) -> Observable<[Repository]> {
        
        return Observable.create { observer -> Disposable in
            
            let baseURLString = "https://api.github.com"
            ...
            let url = NSURL(string: baseURLString + path)!
            ...
                .responseJSON { response in
                    switch response.result {
                    case .Success(let json):
                        ...
                        observer.onNext(repositories)
                        observer.onCompleted()
                    case .Failure(let error):
                        observer.onError(error)
                    }
            }
            
            return AnonymousDisposable {
                request.cancel()
            }
        }
    }
}
```

我们都不喜欢重复的代码，

我们都希望代码可以高度复用.

那我们就要提炼可复用的逻辑.

那么就找一下这两个网络请求有哪些相同点和不同点.

相同点：

* baseURLString 都是 "https://api.github.com"
* url 都是 NSURL(string: baseURLString + path)!
* HTTP 请求都是用的 .GET 方法
* 解析完数据后的回调，都是一样的
* 取消请求的方法都一样

不同点：

* path 不一样
* parameters 不一样
* 解析 json 的方法不一样
* 解析 json 返回的结果不一样

另外我们对 Github 进行网络请求时，

实际上就是在所有接口中选一个来发送请求.

Swift 在处理多选一时，提供了一个强大的类型,就是 **枚举**(enum).

那么我们就选用枚举来重构网络请求，首先声明 Github：

```swift
enum Github {
    case getRepository(user: String, name: String)
    case searchRepositories(text: String)
}
```

然后把两次请求**相同的逻辑**加入进去：

```swift
extension Github {

    static let baseURLString = "https://api.github.com"
    
    var rx_json: Observable<AnyObject> {
        
        return Observable.create { observer -> Disposable in
            
            let url = NSURL(string: Github.baseURLString + self.path)!
            
            let request =  Alamofire
                .request(.GET, url, parameters: self.parameters, encoding: .URL)
                .responseJSON { response in
                    switch response.result {
                    case .Success(let json):
                        observer.onNext(json)
                        observer.onCompleted()
                    case .Failure(let error):
                        observer.onError(error)
                    }
            }
            
            return AnonymousDisposable {
                request.cancel()
            }
        }
    }
}
```

接着把两次请求**不同的逻辑**加入进去：

首先是 ：


> * path 不一样
> * parameters 不一样

```swift
extension Github {

    var path: String {
        switch self {
        case let getRepository(user, name):
            return "/repos/\(user)/\(name)"
        case searchRepositories:
            return "/search/repositories"
        }
    }
    
    var parameters: [String: AnyObject]? {
        switch self {
        case getRepository:
            return nil
        case let searchRepositories(text):
            return ["q": text]
        }
    }
}
```

然后是 ：

> * 解析 json 的方法不一样
> * 解析 json 返回的结果不一样

```swift
extension Github {
    
    typealias GetRepositoryResult = Repository
    typealias SearchRepositoriesResult = [Repository]
    
    func parse(json: AnyObject) -> Any {
        switch self {
        case getRepository:      return parseGetRepositoryResult(json: json)
        case searchRepositories: return parseSearchRepositoriesResult(json: json)
        }
    }
    
    private func parseGetRepositoryResult(json json: AnyObject) -> GetRepositoryResult {
        return Repository(json: json)
    }
    
    private func parseSearchRepositoriesResult(json json: AnyObject) -> SearchRepositoriesResult {
        let jsons = (json as? NSDictionary)?.valueForKey("items") as? [AnyObject]
        return jsons?.map(Repository.init) ?? []
    }
    
    func rx_model<T>(type: T.Type) -> Observable<T> {
        return rx_json
            .map { json in self.parse(json) }
            .map { result in result as! T }
            .observeOn(MainScheduler.instance)
    }
}
```

现在对比一下之前的结构和现在的结构:

以前：

```swift
struct Github {
    ...
    static func searchRepositories(text text: String) -> Observable<[Repository]> {
        
        return Observable.create { observer -> Disposable in
            
            let baseURLString = "https://api.github.com"
            let path = "/search/repositories"
            let url = NSURL(string: baseURLString + path)!
            let parameters = ["q": text]
            
            let request =  Alamofire
                .request(.GET, url, parameters: parameters, encoding: .URL)
                .responseJSON { response in
                    switch response.result {
                    case .Success(let json):
                        let jsons = (json as? NSDictionary)?.valueForKey("items") as? [AnyObject]
                        let repositories = jsons?.map(Repository.init) ?? []
                        observer.onNext(repositories)
                        observer.onCompleted()
                    case .Failure(let error):
                        observer.onError(error)
                    }
            }
            
            return AnonymousDisposable {
                request.cancel()
            }
        }
    }
}
```

现在：

```swift
enum Github {
    case getRepository(user: String, name: String)
    case searchRepositories(text: String)
}

extension Github {
    
    static let baseURLString = "https://api.github.com"
    
    var rx_json: Observable<AnyObject> {
        
        return Observable.create { observer -> Disposable in
            
            let url = NSURL(string: Github.baseURLString + self.path)!
            
            let request =  Alamofire
                .request(.GET, url, parameters: self.parameters, encoding: .URL)
                .responseJSON { response in
                    switch response.result {
                    case .Success(let json):
                        observer.onNext(json)
                        observer.onCompleted()
                    case .Failure(let error):
                        observer.onError(error)
                    }
            }
            
            return AnonymousDisposable {
                request.cancel()
            }
        }
    }
}

extension Github {

    var path: String {
        switch self {
        case let getRepository(user, name):
            return "/repos/\(user)/\(name)"
        case searchRepositories:
            return "/search/repositories"
        }
    }
    
    var parameters: [String: AnyObject]? {
        switch self {
        case getRepository:
            return nil
        case let searchRepositories(text):
            return ["q": text]
        }
    }
}

extension Github {
    
    typealias GetRepositoryResult = Repository
    typealias SearchRepositoriesResult = [Repository]
    
    func parse(json: AnyObject) -> Any {
        switch self {
        case getRepository:      return parseGetRepositoryResult(json: json)
        case searchRepositories: return parseSearchRepositoriesResult(json: json)
        }
    }
    
    private func parseGetRepositoryResult(json json: AnyObject) -> GetRepositoryResult {
        return Repository(json: json)
    }
    
    private func parseSearchRepositoriesResult(json json: AnyObject) -> SearchRepositoriesResult {
        let jsons = (json as? NSDictionary)?.valueForKey("items") as? [AnyObject]
        return jsons?.map(Repository.init) ?? []
    }
    
    func rx_model<T>(type: T.Type) -> Observable<T> {
        return rx_json
            .map { json in self.parse(json) }
            .map { result in result as! T }
            .observeOn(MainScheduler.instance)
    }
}
```

之前，我们是把所有逻辑放一起，

现在我们把逻辑分解成许多片段,

然后在这些片段里面写自己独有的执行内容,例如:

```swift
extension Github {

    var path: String {
        switch self {
        case let getRepository(user, name):
            return "/repos/\(user)/\(name)"
        case searchRepositories:
            return "/search/repositories"
        }
    }
    
    var parameters: [String: AnyObject]? {
        switch self {
        case getRepository:
            return nil
        case let searchRepositories(text):
            return ["q": text]
        }
    }
}
```

这里的 path 和 parameters 都是片段,

而每种 case (网络请求) 都拥有独特的逻辑.

在 Github 中找到： 

```swift
extension Github {
    ...
    var rx_json: Observable<AnyObject> {...}
    ...
}
```

这个 rx_json 是什么？

先回顾一下网络请求的流程:

**(path, parameters) -> JSON -> Result**

rx_json 就是负责流程的前半段：

**(path, parameters) -> JSON**

先通过不同的参数发起请求，返回一个 JSON.

再来看这段代码： 

```swift
extension Github {
    
    typealias GetRepositoryResult = Repository
    typealias SearchRepositoriesResult = [Repository]
    
    func parse(json: AnyObject) -> Any {
        switch self {
        case getRepository:      return parseGetRepositoryResult(json: json)
        case searchRepositories: return parseSearchRepositoriesResult(json: json)
        }
    }
    
    private func parseGetRepositoryResult(json json: AnyObject) -> GetRepositoryResult {...}
    
    private func parseSearchRepositoriesResult(json json: AnyObject) -> SearchRepositoriesResult {...}
    
    func rx_model<T>(type: T.Type) -> Observable<T> {...}
}
```

这里主要负责流程的后半段:

**JSON -> Result**

将 JSON 解析成 Result，最后发起成功取得 Result 的通知.

```swift
extension Github {
    
    typealias GetRepositoryResult = Repository
    typealias SearchRepositoriesResult = [Repository]
    
    ...
}
```

以上是每种请求对应的结果类型.


```swift
extension Github {
    ...
   func parse(json: AnyObject) -> Any {
        switch self {
        case getRepository:      return parseGetRepositoryResult(json: json)
        case searchRepositories: return parseSearchRepositoriesResult(json: json)
        }
    }
    
    private func parseGetRepositoryResult(json json: AnyObject) -> GetRepositoryResult {...}
    
    private func parseSearchRepositoriesResult(json json: AnyObject) -> SearchRepositoriesResult {...}
    ...
}
```

以上是每种请求对应的解析方法.

而最后的 rx_model : 
	
```swift
extension Github {
    ...
    func rx_model<T>(type: T.Type) -> Observable<T> {...}
}
```

这需要配合使用环境来理解,在 RepositoryTableViewController 的 viewDidLoad 中找到：

```swift
	    ...
        Github.getRepository(user: user, name: name)
            .observeOn(MainScheduler.instance)
            .doOnError { error in print(error) }
            .bindTo(rx_userInterface)
            .addDisposableTo(disposeBag)
        ...
```

将它改为：

```swift
	    ...
        Github.getRepository(user: user, name: name)
            .rx_model(Github.GetRepositoryResult.self)
            .doOnError { error in print(error) }
            .bindTo(rx_userInterface)
            .addDisposableTo(disposeBag)
        ...
```

这里的 rx_model 实际上就是以前的 Observable\<Repository\>,

以前是:

```swift
	    ...
        Github.getRepository(user: user, name: name) -> Observable<Repository>
        ...
```

现在是:

```swift
	    ...
        Github.getRepository(user: user, name: name)
            .rx_model(Github.GetRepositoryResult.self) -> Observable<Repository>
        ...
```
	
需要注意一下这里 Github.GetRepositoryResult == Repository .

那么 rx_model 的功能也可以看得出来:

他就是将解析出来的结果转换成我们传进去的 Type:

```swift
extension Github {
    ...
    func rx_model<T>(type: T.Type) -> Observable<T> {
        return rx_json // 是网络请求返回的 JSON,
            .map { json in self.parse(json) } //将 JSON 用之前声明的 parse 方法解析出来，
            .map { result in result as! T }   //将解析出来的结果转换成外面传进来的 Type.
            .observeOn(MainScheduler.instance)//在主线程接收通知，因为通常是刷新界面这类操作.
    }
}
```

RepositoryTableViewController 中的运行流程:

**(user, name) -> Github.GetRepositoryResult --Bind--> rx_userInterface**

最后，我们在 SearchRepositoriesTableViewController 找到:

```swift
    override func viewDidLoad() {
        super.viewDidLoad()
        ...
        searchBar.rx_text
            ...
            .distinctUntilChanged()
            .flatMapLatest { text in Github.searchRepositories(text: text) }
            .observeOn(MainScheduler.instance)
            .doOnError { error in print(error) }
            .bindTo(tableView.rx_itemsWithCellIdentifier("UITableViewCell")) { row, repository, cell in
                cell.textLabel?.text = repository.name
                cell.detailTextLabel?.text = repository.description
            }
            .addDisposableTo(disposeBag)
    }
```

将其改为:

```swift
    override func viewDidLoad() {
        super.viewDidLoad()
        ...
        searchBar.rx_text
            ...
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
```
RepositoryTableViewController 中的运行流程:

**searchBar.rx_text -> Github.SearchRepositoriesResult --Bind--> tableView.rx_itemsWithCellIdentifier**

## 结尾

此时我们的网络请求模块已经具备很好的扩展能力，

如果需要新增一个请求方法，无非就是在 Github 中多加一个 case,

此时的代码可以在，分支 [Part-3-End](https://github.com/beeth0ven/Networking/tree/Part-3-End) 找到。

Swift 是一个面向协议的编程语言,

[Part 4](https://github.com/beeth0ven/Networking/blob/master/Documents/Part-4.md)，将介绍如何使用协议来优化结构.




