//
//  User.swift
//  Yelp Demo
//
//  Created by Bambang on 13/05/23.
//

import SwiftyJSON

struct UserModel {
    var id: String = ""
    var name: String = ""
    var image_url: String = ""
    var profile_url: String = ""
    
    var error_title: String = ""
    var error_message: String = ""
    public var isSkeleton = true
    
    init() {
    }
    
    init(error_title: String, error_message: String) {
        self.error_title = error_title
        self.error_message = error_message
    }
    
    init(dictionary: JSON) {
        id = dictionary["id"].stringValue
        if(dictionary["name"].exists()) {
            name = dictionary["name"].stringValue
        }
        if(dictionary["image_url"].exists()) {
            image_url = dictionary["image_url"].stringValue
        }
        if(dictionary["profile_url"].exists()) {
            profile_url = dictionary["profile_url"].stringValue
        }
    }
    
    func isError() -> Bool {
        return !self.error_title.isEmpty || !self.error_message.isEmpty
    }
    
}

