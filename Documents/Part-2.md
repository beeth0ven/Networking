# 中级 - RxSwift

在 [Part-1](https://github.com/beeth0ven/Networking/blob/master/Documents/Part-1.md) 中提到了，网络请求的特点：

> 实际上从服务器取值比本地取值多了两个特征：

> 1. 异步
> 2. 可能失败

在处理这两个特征上，有一个能手，

他就是 [RxSwift](https://github.com/ReactiveX/RxSwift),

他是基于响应式编程的理念而产生的。

现在还是以对 [Github](https://developer.github.com/v3/) 做网络请求为例。

先不管代码的执行细节，我们看下构建方法：
	
* 首先在 Github.swift 找到：

```swift
    static func getRepository(user
        user: String, name: String,
        didGet: (Repository) -> Void,
        didFail: (ErrorType) -> Void) {
        
        let baseURLString = "https://api.github.com"
        let path = "/repos/\(user)/\(name)"
        let url = NSURL(string: baseURLString + path)!
        
        Alamofire
            .request(.GET, url)
            .responseJSON { response in
                switch response.result {
                case .Success(let json):
                    let repository = Repository(json: json)
                    dispatch_async(dispatch_get_main_queue(), {
                        didGet(repository)
                    })
                case .Failure(let error):
                    dispatch_async(dispatch_get_main_queue(), {
                        didFail(error)
                    })
                }
        }
    }
```

将它改为：

```swift
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
```

* 然后在 RepositoryTableViewController.swift 找到

```swift
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Github.getRepository(user: user, name: name,
                didGet: { repo in self.repository = repo },
                didFail: { error in print(error) }
        )
    }
```

将它改为：

```swift
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Github.getRepository(user: user, name: name)
            .observeOn(MainScheduler.instance)
            .doOnNext { [unowned self] repo in self.repository = repo }
            .subscribeError { error in print(error) }
            .addDisposableTo(disposeBag)

    }
```
    
先放慢脚步看下 Github.getRepository 方法：

以前：

```swift
    static func getRepository(user
        user: String, name: String,
        didGet: (Repository) -> Void,
        didFail: (ErrorType) -> Void) { ... }
```

现在：

```swift
    static func getRepository(user user: String, name: String) -> Observable<Repository> { ... }
```

这里有一个非常特别的类型 **Observable\<Repository\>**，

根据字面意思理解，它是： 可观测的 Repository。

根据声明环境猜测，它可以取代 didGet: (Repository) -> Void，

以及 didFail: (ErrorType) -> Void .

再来看下它是怎么取代 didGet 和 didFail，

在 RepositoryTableViewController 中：

以前：

```swift
       Github.getRepository(user: user, name: name,
                didGet: { repo in self.repository = repo },
                didFail: { error in print(error) }
        )
```

现在：

```swift
        Github.getRepository(user: user, name: name)
            .observeOn(MainScheduler.instance)
            .doOnNext { [unowned self] repo in self.repository = repo }
            .subscribeError { error in print(error) }
            .addDisposableTo(disposeBag)
```

大概猜到了.

**Observable\<Repository\>** 实际上就是 [KVO](https://developer.apple.com/library/prerelease/content/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html)，

它是一个可以被观测的 Repository

当 Repository 的值更新时，就会通知收听者，

此时就会执行取值成功的回调：

```swift
        Github.getRepository(user: user, name: name)
            ...
            .doOnNext { [unowned self] repo in self.repository = repo }
            ...
```

同理，当取得 Repository 失败时，

会发起另外一个取值失败的通知，

此时就会执行取值失败的回调：

```swift
        Github.getRepository(user: user, name: name)
            ...
            .subscribeError { error in print(error) }
            ...
```

再来看下我们是怎么创建 **Observable\<Repository\>** 的，

在 Github.swift 中：

以前：

```swift
    static func getRepository(user
        user: String, name: String,
        didGet: (Repository) -> Void,
        didFail: (ErrorType) -> Void) {
        
        let baseURLString = "https://api.github.com"
        let path = "/repos/\(user)/\(name)"
        let url = NSURL(string: baseURLString + path)!
        
        Alamofire
            .request(.GET, url)
            .responseJSON { response in
                switch response.result {
                case .Success(let json):
                    let repository = Repository(json: json)
                    dispatch_async(dispatch_get_main_queue(), {
                        didGet(repository)
                    })
                case .Failure(let error):
                    dispatch_async(dispatch_get_main_queue(), {
                        didFail(error)
                    })
                }
        }
    }
```

现在：

```swift
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
```

创建 **Observable\<Repository\>** 只需要用到 Observable.create 方法，

然后我们把之前的代码全部搬到 closure 里面去了,

```swift
    static func getRepository(user user: String, name: String) -> Observable<Repository> {
        ...
                    switch response.result {
                    case .Success(let json):
                        ...
                        observer.onNext(repository)
                        ...
                    case .Failure(let error):
                        observer.onError(error)
                    }
        ...
    }
```

这里的 observer.onNext(repository) 实际上就是通知收听者,值已经更新.

这里的 observer.onError(error) 实际上就是通知收听者,取值失败.

最后还有一段代码，不确定是做什么的： 

```swift
    static func getRepository(user user: String, name: String) -> Observable<Repository> {
        return Observable.create { observer -> Disposable in
            ...
            return AnonymousDisposable {
                request.cancel()
            }
        }
    }
```

实际上在 RepositoryTableViewController 中也有一段相关的代码，不知道是做什么的:

```swift
class RepositoryTableViewController: UITableViewController {
    ...
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Github.getRepository(user: user, name: name)
            ...
            .addDisposableTo(disposeBag)
    }
    ...
}
```

这与我们常用的接收通知的方法很相像，

在开始收听通知的时候先用 addObserver,

在结束收听时用 removeObserver,

这里其实是一样的，而且更加简单.

addDisposableTo(disposeBag) 就是 addObserver，

当 self.disposeBag 被释放时就是 removeObserver

而 ：

```swift
    static func getRepository(user user: String, name: String) -> Observable<Repository> {
        return Observable.create { observer -> Disposable in
            ...
            return AnonymousDisposable {
                request.cancel()
            }
        }
    }
```

中 request.cancel() 就是在 removeObserver 时运行的代码，

我们走出代码，想象一下这样的情景，

当我们出去旅游时，路经一个偏僻的郊区，

我们正在看新闻，可是这里没有 4G 网络，

只能用 2G 上网，网速非常慢，

等了 2 分钟页面还没刷出来，

于是就退出该页面，然后去玩单机游戏。

此时当我们退出页面时，网络请求还没有结束，

它任然在消耗网络资源，

事实上我们希望在退出页面后，直接取消网络请求.

而以上代码就正好就实现了这种需求。

当退出页面时 RepositoryTableViewController 即将被释放，

然后 RepositoryTableViewController.disposeBag 被释放，

然后 request.cancel() 

流程：

**RepositoryTableViewController.deinit() -> disposeBag.deinit() -> request.cancel()**

### 搜索 Repository  

目前 Github 中只有一种请求，就是通过 用户名 和 库名 取得 Repository:

```swift
    static func getRepository(user user: String, name: String) -> Observable<Repository> { ... }
```

现在新增一个通过关键字搜索 Repository 的网络请求方法:

```swift
    static func searchRepositories(text text: String) -> Observable<[Repository]> { ... }
```

同时新增一个与之相关的 ViewController:

```swift
class SearchRepositoriesTableViewController: UITableViewController {
    
    private var repositories = [Repository]() {
        didSet { tableView.reloadData() }
    }
    
    @IBOutlet private weak var searchBar: UISearchBar!

    ...
}
```

这里就是就是通过 searchBar.text 来发起网络请求，

然后取得 [Repository]，

最后刷新列表：

**searchBar.text -> [Repository] -> tableView.reloadData()**

我们看下，执行的细节:

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

在 Github.searchRepositories 中有一行代码比较难理解:

```swift
let repositories = jsons?.map(Repository.init) ?? []
```

它的功能相当于:

```swift
var repositories = [Repository]()

for json in jsons ?? [] {
    
    let repository = Repository(json: json)
    repositories.append(repository)
}
```

在 SearchRepositoriesTableViewController 我们重点看一下这几行代码：

```swift
class SearchRepositoriesTableViewController: UITableViewController {
    ...
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.rx_text
            .filter { text in !text.isEmpty }
            .throttle(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { text in Github.searchRepositories(text: text) }
            ...
    }
    
    ...
}
```

首先 searchBar.rx_text,

它实际上就是一个可被观测的 String，

当用户修改输入框的内容时，

他就会发起通知,

而 .filter { text in !text.isEmpty } 

意思是忽略掉 text 为空的值，

.throttle(0.5, scheduler: MainScheduler.instance)

意思是当输入文本间隔小于 0.5 秒时，也无需发起通知

.distinctUntilChanged()

意思是忽略掉相同的值.

最后 .flatMapLatest { text in Github.searchRepositories(text: text) }

这个是通过 text 返回一个 [Repository]:

**text -> [Repository]**

然后我们在收听 [Repository] 更新的通知，从而刷新列表:

**text -> [Repository] -> tableView.reloadData()**

## 结尾

这就是用 [RxSwift](https://github.com/ReactiveX/RxSwift) 做网络请求最基本的形态，

此时的代码可以在，分支 [Part-2-End](https://github.com/beeth0ven/Networking/tree/Part-2-End) 找到。

RxSwift 有一套独特的方式来刷新界面.

[Part 3](https://github.com/beeth0ven/Networking/blob/master/Documents/Part-3.md)，将介绍如何使用这种方式，

以及如何优化网络请求的结构！


