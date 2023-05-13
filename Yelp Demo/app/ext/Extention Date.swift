//
//  Extention Date.swift
//  Yelp Demo
//
//  Created by Bambang on 13/05/23.
//
import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
