//
//  Data.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/17.
//

import Foundation
import Firebase

struct User: Decodable {
    var name: String
    var signUpTime: Date
    var userID: String
    var email: String
    var follow: [String] // userID
    var blackList: [String] // userID
    init(dic: [String: Any]) {
        self.name = dic["name"] as? String ?? ""
        self.signUpTime = Timestamp.dateValue(dic["signUpTime"] as? Timestamp ?? Timestamp())()
        self.userID = dic["userID"] as? String ?? ""
        self.email = dic["email"] as? String ?? ""
        self.follow = dic["follow"] as? [String] ?? []
        self.blackList = dic["blackList"] as? [String] ?? []
    }
}

struct Post: Decodable {
    var title: String
    var createdTime: Date
    var id: String
    var userID: String
    var content: String
    var importMusic: String?
    var duration: TimeInterval?
    var tag: String
    var like: Int
    var report: [Report]?
    
    init(dic: [String: Any]) {
        self.title = dic["title"] as? String ?? ""
        self.createdTime = Timestamp.dateValue(dic["createdTime"] as? Timestamp ?? Timestamp())()
        self.id = dic["id"] as? String ?? ""
        self.userID = dic["userID"] as? String ?? ""
        self.content = dic["content"] as? String ?? ""
        self.importMusic = dic["importMusic"] as? String ?? ""
        self.duration = dic["duration"] as? TimeInterval ?? TimeInterval()
        self.tag = dic["tag"] as? String ?? ""
        self.like = dic["like"] as? Int ?? 0
        self.report = dic["Report"] as? [Report] ?? [Report]()
    }
}

struct Report: Decodable {
    var reportType: ReportType
    var detail: String
}

enum ReportType: Decodable {
    case spam, insult, mistakeInfo, violence, revealIdentity, other
}

