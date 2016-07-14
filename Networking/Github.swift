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

enum Github {
    case getRepository(user: String, name: String)
    case searchRepositories(text: String)
    case getOrganization(name: String)
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
        case let getOrganization(name):
            return "/orgs/\(name)"
        }
    }
    
    var parameters: [String: AnyObject]? {
        switch self {
        case getRepository:
            return nil
        case let searchRepositories(text):
            return ["q": text]
        case .getOrganization:
            return nil
        }
    }
}

extension Github {
    
    typealias GetRepositoryResult = Repository
    typealias SearchRepositoriesResult = [Repository]
    typealias GetOrganizationResult = Organization

    func parse(json: AnyObject) -> Any {
        switch self {
        case getRepository:      return parseGetRepositoryResult(json: json)
        case searchRepositories: return parseSearchRepositoriesResult(json: json)
        case getOrganization:    return parseGetOrganizationResult(json: json)
        }
    }
    
    private func parseGetRepositoryResult(json json: AnyObject) -> GetRepositoryResult {
        return Repository(json: json)
    }
    
    private func parseSearchRepositoriesResult(json json: AnyObject) -> SearchRepositoriesResult {
        let jsons = (json as? NSDictionary)?.valueForKey("items") as? [AnyObject]
        return jsons?.map(Repository.init) ?? []
    }
    
    private func parseGetOrganizationResult(json json: AnyObject) -> GetOrganizationResult {
        return Organization(json: json)
    }
    
    func rx_model<T>(type: T.Type) -> Observable<T> {
        return rx_json
            .map { json in self.parse(json) }
            .map { result in result as! T }
            .observeOn(MainScheduler.instance)
    }
}

