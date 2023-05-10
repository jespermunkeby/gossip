//
//  encryptionManager.swift
//  Gossip
//
//  Created by abc on 2023-05-10.
//

import Foundation
import CryptoKit

class EncryptionManager {
    static func encrypt(key: SymmetricKey, plaintext: String) throws -> Data {
        let plaintextData = Data(plaintext.utf8)
        let initializationVector = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(plaintextData, using: key, nonce: initializationVector)
        var encryptedData = sealedBox.ciphertext
        encryptedData.append(contentsOf: initializationVector)
        return encryptedData
    }

    static func decrypt(key: SymmetricKey, encryptedData: Data) throws -> String {
        let initializationVector = encryptedData.suffix(12)
        let ciphertext = encryptedData.prefix(encryptedData.count - 12)
        let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: initializationVector), ciphertext: ciphertext, tag: Data())
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        guard let decryptedPlaintext = String(data: decryptedData, encoding: .utf8) else {
            throw DecryptionError.invalidPlaintext
        }
        return decryptedPlaintext
    }
    
    enum DecryptionError: Error {
        case invalidPlaintext
    }
}
