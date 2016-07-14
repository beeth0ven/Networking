# 高级 - Protocol

在 [Part-3](https://github.com/beeth0ven/Networking/blob/master/Documents/Part-3.md) 的结尾中提到:

> 此时我们的网络请求模块已经具备很好的扩展能力，
> 
> 如果需要新增一个请求方法，无非就是在 Github 中多加一个 case

那我们不如就新增一个网络请求试一试:

```swift
enum Github {
    case getRepository(user: String, name: String)
    case searchRepositories(text: String)
    case getOrganization(name: String)  //  通过组织名称获取组织的完整信息
}
```

```swift
extension Github {

    var path: String {
        switch self {
        case let getRepository(user, name):
            return "/repos/\(user)/\(name)"
        case searchRepositories:
            return "/search/repositories"
        case let getOrganization(name):    // 新增
            return "/orgs/\(name)"         // 新增
        }
    }
    
    var parameters: [String: AnyObject]? {
        switch self {
        case getRepository:
            return nil
        case let searchRepositories(text):
            return ["q": text]
        case .getOrganization:            // 新增
            return nil                    // 新增
        }
    }
}
```

```swift
extension Github {
    
    typealias GetRepositoryResult = Repository
    typealias SearchRepositoriesResult = [Repository]
    typealias GetOrganizationResult = Organization    // 新增

    func parse(json: AnyObject) -> Any {
        switch self {
        case getRepository:      return parseGetRepositoryResult(json: json)
        case searchRepositories: return parseSearchRepositoriesResult(json: json)
        case getOrganization:    return parseGetOrganizationResult(json: json)  // 新增
        }
    }
    
    ...
    
    private func parseGetOrganizationResult(json json: AnyObject) -> GetOrganizationResult {  // 新增
        return Organization(json: json)   // 新增
    }                                     // 新增
    
    ...
}
```

这就是新增一种请求，所需要做的事情,

然后我们看一下 Organization 的定义:

```swift
struct Organization {
    var name: String!     // 组织名称
    var location: String! // 位置
    var blogURL: String!  // 博客的链接
    var htmlURL: String!  // 在 Github 上的链接
}

extension Organization {
    
    init(json: AnyObject) {
        
        if let dictionary = json as? [String: AnyObject] {
            
            self.name = dictionary["name"] as? String
            self.location = dictionary["location"] as? String
            self.blogURL = dictionary["blog"] as? String
            self.htmlURL = dictionary["html_url"] as? String
        }
    }
}
```

最后是控制器 OrganizationTableViewController : 

```swift
class OrganizationTableViewController: UITableViewController {
    
    var name = "Apple"
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var blogURLLabel: UILabel!
    @IBOutlet private weak var htmlURLLabel: UILabel!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Github.getOrganization(name: name)
            .rx_model(Github.GetOrganizationResult.self)
            .doOnError { error in print(error) }
            .bindTo(rx_userInterface)
            .addDisposableTo(disposeBag)
        
    }
    
    var rx_userInterface: AnyObserver<Organization> {
        return UIBindingObserver(UIElement: self) {
            repositoryTableViewController, organization in
            repositoryTableViewController.nameLabel.text        = organization.name
            repositoryTableViewController.locationLabel.text    = organization.location
            repositoryTableViewController.blogURLLabel.text     = organization.blogURL
            repositoryTableViewController.htmlURLLabel.text     = organization.htmlURL
            }.asObserver()
    }
}
```

这个控制器和先前的 RepositoryTableViewController 差不多:

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
            .rx_model(Github.GetRepositoryResult.self)
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

只是将请求回来的结果显示出来:

**name -> Observable\<Organization\> --Bind--> AnyObserver\<Organization\>**

比较一下这两个控制器 OrganizationTableViewController **VS** RepositoryTableViewController :

**name -> Observable\<Organization\> --Bind--> AnyObserver\<Organization\>**

**(user, name) -> Observable\<Repository\> --Bind--> AnyObserver\<Repository\>**

他们都是通过参数发起网络请求，然后将返回的结果绑定到 UI 上面去:

```swift
class OrganizationTableViewController: UITableViewController {
    ...
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Github.getOrganization(name: name)
            .rx_model(Github.GetOrganizationResult.self)
            .doOnError { error in print(error) }
            .bindTo(rx_userInterface)
            .addDisposableTo(disposeBag)
    }
    ...
}
```

```swift
class RepositoryTableViewController: UITableViewController {
    ...
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Github.getRepository(user: user, name: name)
            .rx_model(Github.GetRepositoryResult.self)
            .doOnError { error in print(error) }
            .bindTo(rx_userInterface)
            .addDisposableTo(disposeBag)
    }
    ..
}

```

而他们的不同点只是:

* 网络请求的方法不一样
* 网络请求返回的结果类型不一样
* 刷新页面的方式不一样 

现在我们已经掌握了很多重要信息，

我们能不能提炼出可复用的逻辑,

使得整个流程变得更加简单呢？

当然可以.

这里我们需要用到 Swift 另一种类型 - **Protocol**,

先定一个协议用于串连这些零散的逻辑:

```swift
protocol RxGithubViewControllerType {
    associatedtype Model
    var disposeBag: DisposeBag { get set }
    var githubRequest: Github { get }
    var rx_userInterface: AnyObserver<Model> { get }
    func updateUI(with model: Model)
}
```

之前提到过这些控制器的不同点：

> * 网络请求的方法不一样
> * 网络请求返回的结果类型不一样
> * 刷新页面的方式不一样 

这里就有 3 行代码专门处理这些不同点:

```swift
protocol RxGithubViewControllerType {
    associatedtype Model // 网络请求返回的结果类型不一样            
    ...
    var githubRequest: Github { get }  // 网络请求的方法不一样
    ...
    func updateUI(with model: Model) // 刷新页面的方式不一样 
}
```

然后把**相同点**写入到 extension 里面去:

```swift
extension RxGithubViewControllerType where Self: UIViewController {
    
    var rx_userInterface: AnyObserver<Model> {
        return UIBindingObserver(UIElement: self) {
            selfvc, model in
            selfvc.updateUI(with: model)
            }.asObserver()
    }
    
    func setupRx() {
        
        githubRequest
            .rx_model(Model)
            .doOnError { error in print(error) }
            .bindTo(rx_userInterface)
            .addDisposableTo(disposeBag)
    }
}
```

这里注明一下 associatedtype Model 是一个预留的类型，

它相当于是一个 **类型变量**，需要在使用时填充, 例如:

```swift
extension OrganizationTableViewController: RxGithubViewControllerType {
    
    typealias Model = Organization
    
    var githubRequest: Github {
        return Github.getOrganization(name: name)
    }
    
    func updateUI(with model: Model) {
        nameLabel.text        = model.name
        locationLabel.text    = model.location
        blogURLLabel.text     = model.blogURL
        htmlURLLabel.text     = model.htmlURL
    }
}
```

在 OrganizationTableViewController 中就将 Model 填充为 Organization，

在 RepositoryTableViewController 中就将 Model 填充为 Repository:

```swift
extension RepositoryTableViewController: RxGithubViewControllerType {
    
    typealias Model = Repository
    
    var githubRequest: Github {
        return Github.getRepository(user: user, name: name)
    }
    
    func updateUI(with model: Model) {
        nameLabel.text        = model.name
        languageLabel.text    = model.language
        descriptionLabel.text = model.description
        urlLabel.text         = model.url
    }
}
```

而网络请求方法 var githubRequest: Github 和 刷新页面的方法 func updateUI(with model: Model),
 
也需要更具不同的环境来提供不同的执行细节.

这样一来我们写代码就成了 **你问我答**.

根据不同的环境，提供不同的答案， 

至于流程是怎么运作的，我们不需要关心,

因为协议为我们做了一切.

现在给出控制器完整的代码:

```swift
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

extension OrganizationTableViewController: RxGithubViewControllerType {
    
    typealias Model = Organization
    
    var githubRequest: Github {
        return Github.getOrganization(name: name)
    }
    
    func updateUI(with model: Model) {
        nameLabel.text        = model.name
        locationLabel.text    = model.location
        blogURLLabel.text     = model.blogURL
        htmlURLLabel.text     = model.htmlURL
    }
}
```

```swift
class RepositoryTableViewController: UITableViewController {
    
    var user = "beeth0ven", name = "Timer"
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var languageLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var urlLabel: UILabel!
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRx()
    }
}

extension RepositoryTableViewController: RxGithubViewControllerType {
    
    typealias Model = Repository
    
    var githubRequest: Github {
        return Github.getRepository(user: user, name: name)
    }
    
    func updateUI(with model: Model) {
        nameLabel.text        = model.name
        languageLabel.text    = model.language
        descriptionLabel.text = model.description
        urlLabel.text         = model.url
    }
}
```

## 结尾

面向协议是一种新的编程理念，

每个零散的方法可以看作是一个点，而协议就是一条线，

它可以将各种零散的方法串联起来,形成一个逻辑流.

当我们遇到新的问题时，不妨思考一下,

如何使用面向协议的理念来处理这些问题.

你或许会发现一些意外的收获.

此时的代码可以在，分支 [Part-4-End](https://github.com/beeth0ven/Networking/tree/Part-4-End) 找到。




