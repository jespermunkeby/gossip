//
//  Message.swift
//  Gossip
//
//  Created by Jesper Munkeby on 2023-05-03.
//
import Foundation
import CoreLocation

struct Message {
    let content: Data
    let pickupTime: Date
    let location: CLLocationCoordinate2D
    
    init(data: Data){
        //deserialize
        self.content = data
        self.pickupTime = Date()
        self.location = MapManager.shared.getCurrentLocation()
    }
    
    init(messageModel: MessageModel){
        //deserialize
        self.content = messageModel.content!.data(using: .utf8)!
        self.pickupTime = messageModel.timestamp!
        self.location = CLLocationCoordinate2D(latitude: messageModel.latitude, longitude: messageModel.longitude)
    }
    
    
}

extension Message {
    func serialize() -> Data{
        return self.content
    }
}

extension Message: Equatable {
    static func ==(lhs: Message, rhs: Message) -> Bool {
        return lhs.content == rhs.content
    }
}

extension Message: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
    }
}
