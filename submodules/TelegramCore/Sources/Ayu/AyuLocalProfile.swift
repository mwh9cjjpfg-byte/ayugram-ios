import Foundation
import Postbox

/// Local-only profile decoration for the user's own accounts (emoji status, name/profile colors).
/// Nothing here is ever sent to the server; other people never see it.
public enum AyuLocalProfile {
    private static let defaults = UserDefaults.standard
    private static let ownIdsKey = "ayu.ownPeerIds"
    private static let emojiStatusKey = "ayu.local.emojiStatusFileId"
    private static let nameColorKey = "ayu.local.nameColor"
    private static let nameEmojiKey = "ayu.local.nameBackgroundEmojiId"
    private static let profileColorKey = "ayu.local.profileColor"
    private static let profileEmojiKey = "ayu.local.profileBackgroundEmojiId"
    
    public static func registerOwnPeerId(_ id: PeerId) {
        let value = NSNumber(value: id.id._internalGetInt64Value())
        var ids = (defaults.array(forKey: ownIdsKey) as? [NSNumber]) ?? []
        if !ids.contains(value) {
            ids.append(value)
            defaults.set(ids, forKey: ownIdsKey)
        }
    }
    
    private static func isOwn(_ id: PeerId) -> Bool {
        guard AyuConfig.localPremium, id.namespace == Namespaces.Peer.CloudUser else {
            return false
        }
        let value = NSNumber(value: id.id._internalGetInt64Value())
        let ids = (defaults.array(forKey: ownIdsKey) as? [NSNumber]) ?? []
        return ids.contains(value)
    }
    
    public static func setEmojiStatus(fileId: Int64?) {
        defaults.set(fileId.flatMap { NSNumber(value: $0) }, forKey: emojiStatusKey)
    }
    
    public static func setColors(nameColor: Int32?, nameBackgroundEmojiId: Int64?, profileColor: Int32?, profileBackgroundEmojiId: Int64?) {
        defaults.set(nameColor.flatMap { NSNumber(value: $0) }, forKey: nameColorKey)
        defaults.set(nameBackgroundEmojiId.flatMap { NSNumber(value: $0) }, forKey: nameEmojiKey)
        defaults.set(profileColor.flatMap { NSNumber(value: $0) }, forKey: profileColorKey)
        defaults.set(profileBackgroundEmojiId.flatMap { NSNumber(value: $0) }, forKey: profileEmojiKey)
    }
    
    static func flags(_ flags: UserInfoFlags, for id: PeerId) -> UserInfoFlags {
        if isOwn(id) {
            var result = flags
            result.insert(.isPremium)
            return result
        }
        return flags
    }
    
    static func emojiStatus(_ current: PeerEmojiStatus?, for id: PeerId) -> PeerEmojiStatus? {
        if isOwn(id), let number = defaults.object(forKey: emojiStatusKey) as? NSNumber {
            return PeerEmojiStatus(content: .emoji(fileId: number.int64Value), expirationDate: nil)
        }
        return current
    }
    
    static func nameColor(_ current: PeerColor?, for id: PeerId) -> PeerColor? {
        if isOwn(id), let number = defaults.object(forKey: nameColorKey) as? NSNumber {
            return .preset(PeerNameColor(rawValue: number.int32Value))
        }
        return current
    }
    
    static func backgroundEmojiId(_ current: Int64?, for id: PeerId) -> Int64? {
        if isOwn(id), defaults.object(forKey: nameColorKey) != nil {
            return (defaults.object(forKey: nameEmojiKey) as? NSNumber)?.int64Value
        }
        return current
    }
    
    static func profileColor(_ current: PeerNameColor?, for id: PeerId) -> PeerNameColor? {
        if isOwn(id), let number = defaults.object(forKey: profileColorKey) as? NSNumber {
            return PeerNameColor(rawValue: number.int32Value)
        }
        return current
    }
    
    static func profileBackgroundEmojiId(_ current: Int64?, for id: PeerId) -> Int64? {
        if isOwn(id), defaults.object(forKey: profileColorKey) != nil {
            return (defaults.object(forKey: profileEmojiKey) as? NSNumber)?.int64Value
        }
        return current
    }
}
