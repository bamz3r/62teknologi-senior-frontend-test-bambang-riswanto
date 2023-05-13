//
//  MyTools.swift
//  Yelp Demo
//
//  Created by Bambang on 12/05/23.
//

import Foundation

struct MyTools {
    static func getNumShortString(num: Int) -> String {
        var result = ""
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSize = 3
        numberFormatter.maximumFractionDigits = 1
        
        if num < 1000 {
            result = "\(num)"
        } else if num < 1000000 {
            let r: Double = Double.init(num)/1000
            result = "\(numberFormatter.string(from: NSNumber(value: r)) ?? "0")K"
        } else if num < 1000000000 {
            let r: Double = Double.init(num)/1000000
            result = "\(numberFormatter.string(from: NSNumber(value: r)) ?? "0")M"
        }
        return result
    }
    
    static func getDoubleString(num: Double, fractionDigit: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSize = 3
        numberFormatter.maximumFractionDigits = fractionDigit
        
        return numberFormatter.string(from: NSNumber(value: num)) ?? ""
    }
}
