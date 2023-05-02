//
//  MessageModel+CoreDataProperties.swift
//  Gossip
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
