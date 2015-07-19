//
//  Message.swift
//  hackertracker
//
//  Created by Seth Law on 4/9/15.
//  Copyright (c) 2015 Beezle Labs. All rights reserved.
//

import Foundation
import CoreData

@objc(Message)
class Message: NSManagedObject {

    @NSManaged var date: NSDate
    @NSManaged var msg: String

}
