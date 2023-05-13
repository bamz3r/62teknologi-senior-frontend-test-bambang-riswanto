//
//  ApiCall.swift
//  Yelp Demo
//
//  Created by Bambang on 11/05/23.
//

import Alamofire
import SwiftyJSON

struct ApiCall {
    
    static func getClientId() -> String {
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else { return ""}
        guard let clientId: String = infoDictionary["MyClientId"] as? String else { return ""}
        return clientId
    }
    
    static func getHeader() -> HTTPHeaders { // to do : set header if you have a valid authentication key
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else { return [:]}
        guard let apikey: String = infoDictionary["MyApiKey"] as? String else { return [:]}
        let headers: HTTPHeaders = [
            "Accept":"application/json",
            "Authorization": "Bearer \(apikey)"
        ]
        return headers
    }
    
    static func handleError(response: DataResponse<Any>, onerror: @escaping (String?) -> Void) {
        switch response.response?.statusCode {
        case .some(400):
            guard let data = response.data else {
                return
            }
            let json = JSON(data)
            if json["error"].exists() {
                if json["error"]["description"].exists() {
                    onerror(json["error"]["description"].stringValue)
                }
            } else {
                onerror("Bad Request. Message varies depending on failure scenario")
            }
        case .some(401):
            onerror("The API key has either expired or doesn't have the required scopes to query this endpoint.")
        case .some(403):
            guard let data = response.data else {
                return
            }
            let json = JSON(data)
            if json["error"].exists() {
                if json["error"]["description"].exists() {
                    onerror(json["error"]["description"].stringValue)
                }
            } else {
                onerror("The API key provided is not currently able to query this endpoint.")
            }
        case .some(413):
            onerror("The length of the request exceeded the maximum allowed")
        case .some(429):
            onerror("You have either exceeded your daily quota, or have exceeded the queries-per-second limit for this endpoint. Try reducing the rate at which you make queries.")
        case .some(500):
            onerror("Internal Server Error")
        case .some(503):
            onerror("Service unavailable")
        default:
            guard let data = response.data else {
                return
            }
            let json = JSON(data)
            if json["error"].exists() {
                if json["error"]["description"].exists() {
                    onerror(json["error"]["description"].stringValue)
                }
            } else {
                onerror("Unexpected error")
            }
        }
    }
    
    static func getBusinessSearchs(query: String, page: Int, location: String, lat: Double?, lng: Double?, openNow: String?, price: String, sort: String, completion: @escaping ([BusinessModel]?, Int) -> Void, onerror: @escaping (String?) -> Void) {
        let perpage = 20
        let offset = (page * perpage) - perpage
        var results: [BusinessModel] = []
        var parameters: Parameters = [
            "client_id": getClientId(),
            "term": query,
            "limit": perpage,
            "offset": offset,
            "device_platform": "ios",
            "sort_by": sort,
            "radius": 40000, // max 40.000 meters
            //"locale": "en-US"
        ]
        
        if !location.isEmpty {
            parameters["location"] = location
        }
        if lat != 0 && lng != 0 {
            parameters["latitude"] = lat
            parameters["longitude"] = lng
        }
        if openNow != "all" {
            parameters["open_now"] = openNow
        }
        if !price.isEmpty {
            parameters["price"] = price
        }
        print("getBusinessSearchs API called")
        
        Alamofire.request("https://api.yelp.com/v3/businesses/search",
                          method: .get,
                          parameters: parameters,
                          encoding: URLEncoding(destination: .queryString), headers: getHeader())
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    guard let data = response.data else {
                        // No data returned
                        print("empty result")
                        onerror("Empty Result")
                        return
                    }
                    
                    let json = JSON(data)
                    let total_count = json["total"].intValue
                    let lists = json["businesses"]
                    
                    print(json)
                    for (_, subJson) in lists {
                        var item: BusinessModel = BusinessModel(dictionary: subJson)
//                        print(subJson)
                        item.isSkeleton = false
                        results.append(item)
                    }
                    completion(results, total_count)
                case .failure( _):
                    handleError(response: response, onerror: onerror)
                }
        }
    }
    
    static func getBusinessDetail(id: String, completion: @escaping (BusinessModel?) -> Void, onerror: @escaping (String?) -> Void) {
        let parameters: Parameters = [:]
        print("getBusinessDetail API called")
        
        Alamofire.request("https://api.yelp.com/v3/businesses/\(id)",
                          method: .get,
                          parameters: parameters,
                          encoding: URLEncoding(destination: .queryString), headers: getHeader())
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    guard let data = response.data else {
                        // No data returned
                        print("empty result")
                        onerror("Empty Result")
                        return
                    }
                    
                    let json = JSON(data)
                    
                    var item: BusinessModel = BusinessModel(dictionary: json)
                    item.isSkeleton = false
                    completion(item)
                case .failure( _):
                    handleError(response: response, onerror: onerror)
                }
        }
    }
    
    static func getBusinessReviews(id: String, page: Int, completion: @escaping ([ReviewModel]?, Int) -> Void, onerror: @escaping (String?) -> Void) {
        let perpage = 10
        let offset = (page * perpage) - perpage
        var results: [ReviewModel] = []
        let parameters: Parameters = [
            "client_id": getClientId(),
            "limit": perpage,
            "offset": offset,
            "device_platform": "ios",
            "sort_by": "best_match",
            //"locale": "en-US"
        ]
        print("getBusinessReviews API called")
        
        Alamofire.request("https://api.yelp.com/v3/businesses/\(id)/reviews",
                          method: .get,
                          parameters: parameters,
                          encoding: URLEncoding(destination: .queryString), headers: getHeader())
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success:
                    guard let data = response.data else {
                        // No data returned
                        print("empty result")
                        onerror("Empty Result")
                        return
                    }
                    
                    let json = JSON(data)
                    let total_count = json["total"].intValue
                    let lists = json["reviews"]
                    
                    print(json)
                    for (_, subJson) in lists {
                        var item: ReviewModel = ReviewModel(dictionary: subJson)
//                        print(subJson)
                        item.isSkeleton = false
                        results.append(item)
                    }
                    completion(results, total_count)
                case .failure( _):
                    handleError(response: response, onerror: onerror)
                }
        }
    }
    
}
