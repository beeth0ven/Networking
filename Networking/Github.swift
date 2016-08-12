//
//  GithubServer.swift
//  SeverRequest
//
//  Created by luojie on 16/7/10.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import RxCocoa

struct Github: HttpRequestType {
    
    static var baseURLString: String { return "https://api.github.com" }
    
    static let getRepository: (user: String, name: String) -> Observable<Repository> = Github.createRequest(
        method: .GET,
        toPath: { user, name in "/repos/\(user)/\(name)" },
        parse: Repository.init
    )
    
    static let searchRepositories: (text: String) -> Observable<[Repository]> = Github.createRequest(
        method: .GET,
        toPath: { _ in "/search/repositories" },
        toParameters: { text in ["q": text] },
        parse: { json in
            let jsons = (json as? NSDictionary)?.valueForKey("items") as? [AnyObject]
            return jsons?.map(Repository.init) ?? []
        }
    )
    
    static let getOrganization: (name: String) -> Observable<Organization> = Github.createRequest(
        method: .GET,
        toPath: { name in "/orgs/\(name)" },
        parse: Organization.init
    )
    
    static let newRepository: (user: String, name: String) -> Observable<Void> = Github.createRequest(
        method: .POST,
        toPath: { _ in "/repos/new" },
        toParameters: { user, name in ["user": user, "name": name] }
    )
}


