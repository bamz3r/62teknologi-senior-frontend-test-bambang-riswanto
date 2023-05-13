//
//  BusinessModel.swift
//  Yelp Demo
//
//  Created by Bambang on 11/05/23.
//

import SwiftyJSON

struct BusinessModel {
    var id: String = ""
    var alias: String = ""
    var name: String = "                          "
    var image_url: String = ""
    var is_closed = false
    var url: String = ""
    var rating = 0.0
    var review_count = 0
    
    var photos: [String] = []
    
    var price = "       "
    var address = "                          "
    var category = "                          "
    
    var latitude = 0.0
    var longitude = 0.0
    var distance = 0.0
    
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
        if(dictionary["url"].exists()) {
            url = dictionary["url"].stringValue
        }
        if(dictionary["rating"].exists()) {
            rating = dictionary["rating"].doubleValue
        }
        if(dictionary["review_count"].exists()) {
            review_count = dictionary["review_count"].intValue
        }
        if(dictionary["price"].exists()) {
            price = dictionary["price"].stringValue
        }
        if(dictionary["location"].exists()) {
            var tmp_address = ""
            if(dictionary["location"]["address1"].exists() && !dictionary["location"]["address1"].stringValue.isEmpty) {
                tmp_address += dictionary["location"]["address1"].stringValue
            }
            if(dictionary["location"]["address2"].exists() && !dictionary["location"]["address2"].stringValue.isEmpty) {
                tmp_address += ", " + dictionary["location"]["address2"].stringValue
            }
            if(dictionary["location"]["address3"].exists() && !dictionary["location"]["address3"].stringValue.isEmpty) {
                tmp_address += ", " + dictionary["location"]["address3"].stringValue
            }
            address = tmp_address
        }
        if(dictionary["categories"].exists()) {
            var tmp_category = ""
            let categories = dictionary["categories"].arrayValue
            var i = 0
            for item in categories {
                tmp_category += (i > 0 ? ", " : "") + item["title"].stringValue
                i += 1
            }
            category = tmp_category
        }
        if(dictionary["coordinates"].exists()) {
            if(dictionary["coordinates"]["latitude"].exists()) {
                latitude = dictionary["coordinates"]["latitude"].doubleValue
            }
            if(dictionary["coordinates"]["logitude"].exists()) {
                longitude = dictionary["coordinates"]["longitude"].doubleValue
            }
        }
        if(dictionary["distance"].exists()) {
            distance = dictionary["distance"].doubleValue
        }
        
        if(dictionary["photos"].exists()) {
            let subitems = dictionary["photos"].arrayValue
            for item in subitems {
                photos.append(item.stringValue)
            }
        }
    }
    
    func isError() -> Bool {
        return !self.error_title.isEmpty || !self.error_message.isEmpty
    }
    
}
