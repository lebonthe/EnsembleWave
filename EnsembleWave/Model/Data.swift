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
    var userBlackList: [String] // userID
    init(dic: [String: Any]) {
        self.name = dic["name"] as? String ?? ""
        self.signUpTime = Timestamp.dateValue(dic["signUpTime"] as? Timestamp ?? Timestamp())()
        self.userID = dic["userID"] as? String ?? ""
        self.email = dic["email"] as? String ?? ""
        self.follow = dic["follow"] as? [String] ?? []
        self.userBlackList = dic["userBlackList"] as? [String] ?? []
    }
}

struct Post: Decodable {
    var title: String
    var createdTime: Date
    var id: String
    var userID: String
    var videoURL: String
    var content: String
    var importMusic: String?
    var duration: TimeInterval?
    var tag: String
    var whoLike: [String]
    var reply: [ReplayContent]
    var report: [Report]
    
    init(dic: [String: Any]) {
        self.title = dic["title"] as? String ?? ""
        self.createdTime = Timestamp.dateValue(dic["createdTime"] as? Timestamp ?? Timestamp())()
        self.id = dic["id"] as? String ?? ""
        self.userID = dic["userID"] as? String ?? ""
        self.videoURL = dic["videoURL"] as? String ?? ""
        self.content = dic["content"] as? String ?? ""
        self.importMusic = dic["importMusic"] as? String ?? ""
        self.duration = dic["duration"] as? TimeInterval ?? TimeInterval()
        self.tag = dic["tag"] as? String ?? ""
        self.whoLike = dic["whoLike"] as? [String] ?? []
        self.reply = dic["replay"] as? [ReplayContent] ?? []
        self.report = dic["Report"] as? [Report] ?? []
    }
}

struct Report: Decodable {
    var reportType: ReportType
    var detail: String
}

enum ReportType: Decodable {
    case spam, insult, mistakeInfo, violence, revealIdentity, other
}

struct ReplayContent: Decodable {
    var userID: String
    var replayContent: String
    var replayTime: Date
    
    init(dic: [String: Any]) {
        self.userID = dic["userID"] as? String ?? ""
        self.replayContent = dic["replayContent"] as? String ?? ""
        self.replayTime = Timestamp.dateValue(dic["replayTime"] as? Timestamp ?? Timestamp())()
    }
}