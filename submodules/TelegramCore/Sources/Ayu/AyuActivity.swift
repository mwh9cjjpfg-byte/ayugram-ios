import Foundation
import Postbox

/// Local record of when a person last did something visible in a chat with you
/// (wrote a message, started typing, read your message). Nothing is requested from the server.
public enum AyuActivity {
    private static let key = "ayu.chatActivity"
    
    public static func record(_ peerId: PeerId, timestamp: Int32? = nil) {
        guard peerId.namespace == Namespaces.Peer.CloudUser else {
            return
        }
        let value = timestamp ?? Int32(Date().timeIntervalSince1970)
        let id = String(peerId.id._internalGetInt64Value())
        var dict = (UserDefaults.standard.dictionary(forKey: key) as? [String: Int32]) ?? [:]
        if let current = dict[id], current >= value {
            return
        }
        dict[id] = value
        UserDefaults.standard.set(dict, forKey: key)
    }
    
    public static func lastActivity(_ peerId: PeerId) -> Int32? {
        let id = String(peerId.id._internalGetInt64Value())
        let dict = (UserDefaults.standard.dictionary(forKey: key) as? [String: Int32]) ?? [:]
        return dict[id]
    }
}
