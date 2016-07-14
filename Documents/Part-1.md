# 基础

目前有大量 App 都需要进行网络请求，这里讨论一下如何优化网络请求。

我们用 [Github](https://developer.github.com/v3/) 作为服务器，然后用 [Alamofire](https://github.com/Alamofire/Alamofire) 作为网络请求框架。

对 Github 发起请求，然后取得 Repository (代码库)。

先看一下我们的 Model ： 

```swift
struct Repository {
    var name: String! 			// 库的名称
    var language: String!		// 汇编语言
    var description: String!	// 描述
    var url: String!			// 链接地址
}
```

然后看一下我们的 ViewController : 
	
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        repository = Github.getRepository(user: user, name: name)
    }
    
    func updateUI() {
        nameLabel.text        = repository.name
        languageLabel.text    = repository.language
        descriptionLabel.text = repository.description
        urlLabel.text         = repository.url
    }
}
```

这里先假设服务器在本地，可以直接取得 Repository ： 

```swift
struct Github {
    static func getRepository(user user: String, name: String) -> Repository {
        var repo = Repository()
        repo.name = "Timer"
        repo.language = "Swift"
        repo.description = "Closure based timer"
        repo.url = "https://github.com/beeth0ven/Timer"
        return repo
    }
}
```

这里的流程是这样的：

**(user, name) -> Repository -> updateUI**

在 RepositoryTableViewController 的 viewDidLoad() 方法里，

通过 Github 用户名和 repo 名，取得 Repository,

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    
    repository = Github.getRepository(user: user, name: name)
}
```
当得到 Repository 后， 刷新界面.

```swift
private var repository: Repository! {
    didSet { updateUI() }
}
```

如果是从服务器取得 Repository 那流程会是这样：

**(user, name) -> JSON -> Repository -> updateUI**

我们多比较一下本地取值和服务器取值，可以发现，

实际上服务器请求取值比本地多了两个特征：

1. 异步
2. 可能失败

本地取值立即就可以返回，而服务器则需要花更多时间。

另外如果无法连接互联网，那么服务器就不能返回结果,

这样请求就会失败.

不过要处理这两个特征其实并不难：

```swift
struct Github {
    static func getRepository(user user: String, name: String) -> Repository {
        ...
    }
}
```
改为：

```swift
struct Github {
    static func getRepository(user user: String, name: String,
        didGet: (Repository) -> Void,
        didFail: (ErrorType) -> Void) {
        ...
    }
}
```

异步，只需要声明一个  didGet: (Repository) -> Void 的 closure.

失败，只需要声明一个  didFail: (ErrorType) -> Void 的 closure.


那么该方法的详细执行内容是什么：

```swift
struct Github {
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
}

extension Repository {
    init(json: AnyObject) {
        
        if let dictionary = json as? [String: AnyObject] {
            
            self.name = dictionary["name"] as? String
            self.language = dictionary["language"] as? String
            self.description = dictionary["description"] as? String
            self.url = dictionary["html_url"] as? String
        }
    }
}
```

使用时，也需要进行微调。

在 RepositoryTableViewController 的 viewDidLoad() 方法需要进行修改：

```swift
    ...
    repository = Github.getRepository(user: user, name: name)
    ...
```

改为：

```swift
    ...
    Github.getRepository(user: user, name: name,
        didGet: { repo in self.repository = repo },
        didFail: { error in print(error) }
    ...
```
## 结尾

这就是网络请求最基本的形态，其实他和本地取值区别并不大。

此时的代码可以在，分支 [Part-1-End](https://github.com/beeth0ven/Networking/tree/Part-1-End) 找到。

[Part 2](https://github.com/beeth0ven/Networking/blob/master/Documents/Part-2.md)，将介绍如何使用 RxSwift 来实现网络请求，

将响应式编程融入到网络请求中！


	

