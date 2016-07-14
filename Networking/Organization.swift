//
//  Organization.swift
//  Networking
//
//  Created by luojie on 16/7/14.
//  Copyright © 2016年 LuoJie. All rights reserved.
//

import Foundation

struct Organization {
    var name: String!
    var location: String!
    var blogURL: String!
    var htmlURL: String!
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