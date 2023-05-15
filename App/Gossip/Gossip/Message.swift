//
//  Message.swift
//  Gossip
//
//  Created by Jesper Munkeby on 2023-05-03.
//
import Foundation
import CoreLocation
import CryptoKit

let keyString = "xoxoGossip"

// Derive a 256-bit key from the predefined key string
let keyData = keyString.data(using: .utf8)!
let key = SymmetricKey(data: SHA256.hash(data: keyData))

func encryptAES(data: Data, key: SymmetricKey) -> Data? {
    do {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined
    } catch {
        print("Encryption error: \(error.localizedDescription)")
        return nil
    }
}

func decryptAES(encryptedData: Data, key: SymmetricKey) -> Data? {
    do {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return decryptedData
    } catch {
        print("Decryption error: \(error.localizedDescription)")
        return nil
    }
}

struct Message {
    let content: Data
    let pickupTime: Date
    let location: CLLocationCoordinate2D
    
    init(data: Data) throws {
        //deserialize
        guard let decryptedData = decryptAES(encryptedData: data, key: key) else {
            throw NSError(domain: "Decryption failed", code: 1, userInfo: nil)
        }
        self.content = decryptedData
        self.pickupTime = Date()
        self.location = MapManager.shared.getDeviceCurrentLocation() ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
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
        return encryptAES(data: self.content, key: key)!
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
