import Foundation
import Postbox

/// Marks a message that was deleted on the server but kept locally ("keep deleted messages").
public final class AyuDeletedMessageAttribute: MessageAttribute {
    public let deletionTimestamp: Int32

    public init(deletionTimestamp: Int32) {
        self.deletionTimestamp = deletionTimestamp
    }

    required public init(decoder: PostboxDecoder) {
        self.deletionTimestamp = decoder.decodeInt32ForKey("ts", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.deletionTimestamp, forKey: "ts")
    }
}

extension Message {
    public var isAyuDeleted: Bool {
        return self.attributes.contains(where: { $0 is AyuDeletedMessageAttribute })
    }
}

/// Instead of removing the messages, tags them with `AyuDeletedMessageAttribute`.
/// The caller decides whether secret chats are included.
func ayuKeepMessagesInsteadOfDeleting(transaction: Transaction, ids: [MessageId]) {
    let timestamp = Int32(Date().timeIntervalSince1970)
    for id in ids {
        transaction.updateMessage(id, update: { currentMessage in
            if currentMessage.attributes.contains(where: { $0 is AyuDeletedMessageAttribute }) {
                return .skip
            }
            let storeForwardInfo = currentMessage.forwardInfo.flatMap(StoreMessageForwardInfo.init)
            var attributes = currentMessage.attributes
            attributes.append(AyuDeletedMessageAttribute(deletionTimestamp: timestamp))
            return .update(StoreMessage(id: currentMessage.id, customStableId: nil, globallyUniqueId: currentMessage.globallyUniqueId, groupingKey: currentMessage.groupingKey, threadId: currentMessage.threadId, timestamp: currentMessage.timestamp, flags: StoreMessageFlags(currentMessage.flags), tags: currentMessage.tags, globalTags: currentMessage.globalTags, localTags: currentMessage.localTags, forwardInfo: storeForwardInfo, authorId: currentMessage.author?.id, text: currentMessage.text, attributes: attributes, media: currentMessage.media))
        })
    }
}
