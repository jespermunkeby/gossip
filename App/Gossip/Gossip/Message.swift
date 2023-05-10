//
//  Message.swift
//  Gossip
//
//  Created by Jesper Munkeby on 2023-05-03.
//
import Foundation
import CryptoKit

struct Message {
    let content: Data
    let pickupTime: Date
    
    init(data: Data) {
        // deserialize
        self.content = data
        self.pickupTime = Date()
    }
    
    init(messageModel: MessageModel) {
        // deserialize
        self.content = messageModel.content!.data(using: .utf8)!
        self.pickupTime = messageModel.timestamp!
    }

    init(serialized: Data, key: SymmetricKey) {
        // decrypt serialized data
        let decryptedData = try? EncryptionManager.decrypt(key: key, encryptedData: serialized)
        
        // deserialize
        self.content = decryptedData?.data(using: .utf8) ?? Data()
        self.pickupTime = Date()
    }
}

extension Message {
    func serialize() -> Data {
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
