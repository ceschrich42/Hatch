//
//  Task.swift
//  PLC
//
//  Created by Connor Eschrich on 6/28/18.
//  Copyright © 2018 Chris Chou. All rights reserved.
//

import UIKit

class Task{
    //MARK: Properties
    var title: String
    var description: String
    var tag: String
    var startTime: String
    var endTime: String
    var location: String
    var timestamp: TimeInterval
    var id: String
    var createdBy: String
    var ranking: Int
    var timeMilliseconds: TimeInterval
    var endTimeMilliseconds: TimeInterval
    var amounts: Dictionary<String, Int>
    var usersLikedAmount: Int
    var category: String
    
    //MARK: Initialization
    
    init?(title: String, description: String, tag: String, startTime: String, endTime: String, location: String, timestamp: TimeInterval, id: String, createdBy: String, ranking: Int, timeMilliseconds: TimeInterval, endTimeMilliseconds: TimeInterval, amounts: Dictionary<String, Int>, usersLikedAmount: Int, category: String) {
        
        // The title must not be empty
        guard !title.isEmpty else {
            return nil
        }
        
        
        // Initialize stored properties.
        self.title = title
        self.description = description
        self.tag = tag
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
        self.timestamp = timestamp
        self.id = id
        self.createdBy = createdBy
        self.ranking = ranking
        self.timeMilliseconds = timeMilliseconds
        self.endTimeMilliseconds = endTimeMilliseconds
        self.amounts = amounts
        self.usersLikedAmount = usersLikedAmount
        self.category = category
    }
}
