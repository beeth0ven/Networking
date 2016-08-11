//
//  HttpRequest.swift
//  Networking
//
//  Created by luojie on 16/8/11.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import RxCocoa

protocol HttpRequestType {
    static var baseURLString: String { get }
}

extension HttpRequestType {
    
    static func createRequest<Input, Output>(method
        method: Alamofire.Method,
        toPath: (Input) -> String,
        toParameters: ((Input) -> [String: AnyObject]?)? = nil,
        parse: (AnyObject) -> Output
        ) -> (Input -> Observable<Output>) {
        
        return { input in
            
            return Observable.create { observer -> Disposable in
                
                let url = NSURL(string: baseURLString + toPath(input))!
                
                let request =  Alamofire
                    .request(method, url, parameters: toParameters?(input), encoding: .URL)
                    .responseJSON { response in
                        switch response.result {
                        case .Success(let json):
                            let output = parse(json)
                            observer.onNext(output)
                            observer.onCompleted()
                        case .Failure(let error):
                            observer.onError(error)
                        }
                }
                
                return AnonymousDisposable {
                    request.cancel()
                }
                
            }.observeOn(MainScheduler.instance)
        }
    }
    
    static func createRequest<Input>(method
        method: Alamofire.Method,
        toPath: (Input) -> String,
        toParameters: ((Input) -> [String: AnyObject]?)? = nil
        )  -> (Input -> Observable<Void>)  {
        
        return createRequest(
            method: method,
            toPath: toPath,
            toParameters: toParameters,
            parse: { _ in }
        )
    }
}

struct Git: HttpRequestType {
    
    static var baseURLString: String { return "https://api.github.com" }
    
    static let getRepository: (user: String, name: String) -> Observable<Repository> = Git.createRequest(
        method: .GET,
        toPath: { user, name in "/repos/\(user)/\(name)" },
        parse: Repository.init
    )
    
    static let searchRepositories: (text: String) -> Observable<[Repository]> = Git.createRequest(
        method: .GET,
        toPath: { _ in "/search/repositories" },
        toParameters: { text in ["q": text] },
        parse: { json in
            let jsons = (json as? NSDictionary)?.valueForKey("items") as? [AnyObject]
            return jsons?.map(Repository.init) ?? []
        }
    )
    
    static let getOrganization: (name: String) -> Observable<Organization> = Git.createRequest(
        method: .GET,
        toPath: { name in "/orgs/\(name)" },
        parse: Organization.init
    )

    static let newRepository: (user: String, name: String) -> Observable<Void> = Git.createRequest(
        method: .POST,
        toPath: { _ in "/repos/new" },
        toParameters: { user, name in ["user": user, "name": name] }
    )
}

func gitTest() {
    let getRepository = Git.getRepository(user: "", name: "")
    let searchRepositories = Git.searchRepositories(text: "")
    let getOrganization = Git.getOrganization(name: "")
    let newRepository = Git.newRepository(user: "", name: "")
}
