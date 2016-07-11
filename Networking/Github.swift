//
//  GithubServer.swift
//  SeverRequest
//
//  Created by luojie on 16/7/10.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import Foundation
import Alamofire

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