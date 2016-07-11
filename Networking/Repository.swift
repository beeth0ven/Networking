//
//  Repository.swift
//  SeverRequest
//
//  Created by luojie on 16/7/11.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import Foundation

struct Repository {
    var name: String!
    var language: String!
    var description: String!
    var url: String!
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