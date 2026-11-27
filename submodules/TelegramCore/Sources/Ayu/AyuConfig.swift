import Foundation

/// Local-only switches for the "ghost mode" and "keep deleted messages" features.
/// Values live in UserDefaults and never leave the device.
public enum AyuConfig {
    private static let defaults = UserDefaults.standard

    private enum Key: String {
        case dontSendReadReceipts = "ayu.dontSendReadReceipts"
        case dontSendTyping = "ayu.dontSendTyping"
        case dontSendOnline = "ayu.dontSendOnline"
        case dontReadStories = "ayu.dontReadStories"
        case keepDeletedMessages = "ayu.keepDeletedMessages"
        case keepSecretChatMessages = "ayu.keepSecretChatMessages"
        case dontSendScreenshotNotifications = "ayu.dontSendScreenshotNotifications"
        case disableAds = "ayu.disableAds"
        case localPremium = "ayu.localPremium"
        case keepSelfDestructingMedia = "ayu.keepSelfDestructingMedia"
        case allowScreenshots = "ayu.allowScreenshots"
    }

    private static func get(_ key: Key) -> Bool {
        return defaults.bool(forKey: key.rawValue)
    }

    private static func set(_ key: Key, _ value: Bool) {
        defaults.set(value, forKey: key.rawValue)
    }

    /// Do not tell the server that messages were read (no double check mark for the sender).
    public static var dontSendReadReceipts: Bool {
        get { return get(.dontSendReadReceipts) }
        set { set(.dontSendReadReceipts, newValue) }
    }

    /// Do not send "typing...", "recording voice..." and similar activities.
    public static var dontSendTyping: Bool {
        get { return get(.dontSendTyping) }
        set { set(.dontSendTyping, newValue) }
    }

    /// Never report "online" to the server: the account stays offline for everyone else.
    public static var dontSendOnline: Bool {
        get { return get(.dontSendOnline) }
        set { set(.dontSendOnline, newValue) }
    }

    /// Do not mark stories as viewed on the server.
    public static var dontReadStories: Bool {
        get { return get(.dontReadStories) }
        set { set(.dontReadStories, newValue) }
    }

    /// Keep messages locally when the other side deletes them on the server.
    public static var keepDeletedMessages: Bool {
        get { return get(.keepDeletedMessages) }
        set { set(.keepDeletedMessages, newValue) }
    }

    /// Also keep messages of secret chats (remote deletes and self-destruct timers).
    public static var keepSecretChatMessages: Bool {
        get { return get(.keepSecretChatMessages) }
        set { set(.keepSecretChatMessages, newValue) }
    }
    
    /// Do not tell the other side about screenshots taken in secret chats.
    public static var dontSendScreenshotNotifications: Bool {
        get { return get(.dontSendScreenshotNotifications) }
        set { set(.dontSendScreenshotNotifications, newValue) }
    }
    
    /// Do not request sponsored messages (ads in channels).
    public static var disableAds: Bool {
        get { return get(.disableAds) }
        set { set(.disableAds, newValue) }
    }
    
    /// Unlock Premium-gated interface features locally. The server still treats the account as non-Premium.
    public static var localPremium: Bool {
        get { return get(.localPremium) }
        set { set(.localPremium, newValue) }
    }
    
    /// Keep view-once / self-destructing photos, videos and round videos instead of turning them into "expired" stubs.
    public static var keepSelfDestructingMedia: Bool {
        get { return get(.keepSelfDestructingMedia) }
        set { set(.keepSelfDestructingMedia, newValue) }
    }
    
    /// Allow normal screenshots and screen recording where the app normally blanks the screen (secret chats, protected content).
    public static var allowScreenshots: Bool {
        get { return get(.allowScreenshots) }
        set { set(.allowScreenshots, newValue) }
    }
    
    /// Convenience for the settings screen: turns all ghost switches on or off at once.
    public static var isGhostModeFullyEnabled: Bool {
        return dontSendReadReceipts && dontSendTyping && dontSendOnline && dontReadStories
    }

    public static func setGhostMode(_ value: Bool) {
        dontSendReadReceipts = value
        dontSendTyping = value
        dontSendOnline = value
        dontReadStories = value
    }
}
