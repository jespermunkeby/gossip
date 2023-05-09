//
//  Message.swift
//  Gossip
//
//  Created by Jesper Munkeby on 2023-05-03.
//
import Foundation


/*
 
import CryptoKit

let keyString = "myPredefinedKey"

// Derive a 256-bit key from the predefined key string
let keyData = keyString.data(using: .utf8)!
let key = SymmetricKey(data: SHA256.hash(data: keyData))

func encryptAES(data: String, key: SymmetricKey) -> Data? {
    guard let data = data.data(using: .utf8) else { return nil }

    do {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined
    } catch {
        print("Encryption error: \(error.localizedDescription)")
        return nil
    }
}

func decryptAES(encryptedData: Data, key: SymmetricKey) -> String? {
    do {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8)
    } catch {
        print("Decryption error: \(error.localizedDescription)")
        return nil
    }
}
 
 */


struct Message {
    let content: Data
    let pickupTime: Date
    
    init(data: Data){
        //deserialize
        self.content = data
        self.pickupTime = Date()
    }
    
    init(messageModel: MessageModel){
        //deserialize
        self.content = messageModel.content!.data(using: .utf8)!
        self.pickupTime = messageModel.timestamp!
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
