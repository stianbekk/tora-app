import Foundation
import CryptoKit

enum HMAC {
    static func sha256(key: String, message: String) -> String {
        let keyData = Data(key.utf8)
        let messageData = Data(message.utf8)
        let mac = CryptoKit.HMAC<SHA256>.authenticationCode(
            for: messageData,
            using: SymmetricKey(data: keyData)
        )
        return mac.map { String(format: "%02x", $0) }.joined()
    }

    static func sha256Hex(_ string: String) -> String {
        let digest = SHA256.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func sha256Hex(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
