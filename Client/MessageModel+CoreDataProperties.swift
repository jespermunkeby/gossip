//
//  MessageModel+CoreDataProperties.swift
//  CoreBluetoothLESample
//
//  Created by abc on 2023-04-25.
//  Copyright © 2023 Apple. All rights reserved.
//
//

import Foundation
import CoreData


extension MessageModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageModel> {
        return NSFetchRequest<MessageModel>(entityName: "MessageModel")
    }

    @NSManaged public var content: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var title: String?

}

extension MessageModel : Identifiable {

}
