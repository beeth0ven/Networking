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
    
    static func request<Input, Output>(
        inputType inputType: Input.Type,
        outputType: Output.Type,
        method: Alamofire.Method,
        toPath: (Input) -> String,
        toParameters: ((Input) -> [String: AnyObject]?)? = nil,
        parse: (AnyObject) -> Output
        ) -> Input -> Observable<Output> {
        
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
}

struct Git: HttpRequestType {
    
    static var baseURLString = "https://api.github.com"
    
    static let getRepository = Git.request(
        inputType: (user: String, name: String).self,
        outputType: Repository.self,
        method: .GET,
        toPath: { (user: String, name: String) in "/repos/\(user)/\(name)" },
        parse: Repository.init
    )
    
    static let searchRepositories = Git.request(
        inputType: String.self,
        outputType: [Repository].self,
        method: .GET,
        toPath: { _ in "/search/repositories" },
        toParameters: { text in ["q": text] },
        parse: { json in (json as? [AnyObject])?.map(Repository.init) ?? [] }
    )
    
    static let getOrganization = Git.request(
        inputType: String.self,
        outputType: Organization.self,
        method: .GET,
        toPath: { name in "/orgs/\(name)" },
        parse: Organization.init
    )

    static let newRepository = Git.request(
        inputType: (user: String, name: String).self,
        outputType: Void.self,
        method: .POST,
        toPath: { _ in "/repos/new" },
        parse: { _ in }
    )
}

func gitTest() {
    let getRepository = Git.getRepository((user: "", name: ""))
    let searchRepositories = Git.searchRepositories("")
    let getOrganization = Git.getOrganization("")
    let newRepository = Git.newRepository((user: "", name: ""))
}
