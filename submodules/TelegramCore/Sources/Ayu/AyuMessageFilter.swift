import Foundation
import Postbox
import SwiftSignalKit

private final class AyuFilterCache {
    var pattern: String = ""
    var regex: NSRegularExpression?
    var userIdsSource: String = ""
    var userIds: Set<Int64> = []
}

private let ayuFilterCache = Atomic(value: AyuFilterCache())

/// Local-only message filter: hides messages from chosen user ids and messages matching a regular expression.
public func ayuShouldHideMessage(_ message: Message) -> Bool {
    let userIdsSource = AyuConfig.filterUserIds
    let pattern = AyuConfig.filterRegex
    if userIdsSource.isEmpty && pattern.isEmpty {
        return false
    }
    if !message.flags.contains(.Incoming) {
        return false
    }
    return ayuFilterCache.with { cache -> Bool in
        if cache.userIdsSource != userIdsSource {
            cache.userIdsSource = userIdsSource
            var ids = Set<Int64>()
            for part in userIdsSource.components(separatedBy: CharacterSet(charactersIn: ", \n\t;")) {
                if let value = Int64(part) {
                    ids.insert(value)
                }
            }
            cache.userIds = ids
        }
        if cache.pattern != pattern {
            cache.pattern = pattern
            cache.regex = pattern.isEmpty ? nil : (try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]))
        }
        if let author = message.author, cache.userIds.contains(author.id.id._internalGetInt64Value()) {
            return true
        }
        if let regex = cache.regex, !message.text.isEmpty {
            let range = NSRange(message.text.startIndex ..< message.text.endIndex, in: message.text)
            if regex.firstMatch(in: message.text, options: [], range: range) != nil {
                return true
            }
        }
        return false
    }
}
