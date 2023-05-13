//
//  ReviewModel.swift
//  Yelp Demo
//
//  Created by Bambang on 13/05/23.
//

import SwiftyJSON

struct ReviewModel {
    var id: String = ""
    var url: String = ""
    var text: String = ""
    var rating = 0.0
    var time_created: Date = Date()
    var user: UserModel = UserModel()
    
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
        if(dictionary["url"].exists()) {
            url = dictionary["url"].stringValue
        }
        if(dictionary["text"].exists()) {
            text = dictionary["text"].stringValue
        }
        if(dictionary["rating"].exists()) {
            rating = dictionary["rating"].doubleValue
        }
        if(dictionary["time_created"].exists()) {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US") // set locale to reliable US_POSIX
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            time_created = dateFormatter.date(from:dictionary["time_created"].stringValue)!
        }
        if(dictionary["user"].exists()) {
            user = UserModel(dictionary: dictionary["user"])
        }
    }
    
    func isError() -> Bool {
        return !self.error_title.isEmpty || !self.error_message.isEmpty
    }
    
}

