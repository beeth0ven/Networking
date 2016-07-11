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
}