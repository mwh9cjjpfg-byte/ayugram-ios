import Foundation
import Postbox

/// Previous versions of an edited message, oldest first ("edit history").
public final class AyuEditHistoryMessageAttribute: MessageAttribute {
    public let texts: [String]
    public let dates: [Int32]
    
    public init(texts: [String], dates: [Int32]) {
        self.texts = texts
        self.dates = dates
    }
    
    required public init(decoder: PostboxDecoder) {
        self.texts = decoder.decodeStringArrayForKey("t")
        self.dates = decoder.decodeInt32ArrayForKey("d")
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeStringArray(self.texts, forKey: "t")
        encoder.encodeInt32Array(self.dates, forKey: "d")
    }
}

/// Returns the updated message with the previous text appended to its edit history.
func ayuAppendingEditHistory(updated: StoreMessage, previous: Message) -> StoreMessage {
    if previous.text.isEmpty || previous.text == updated.text {
        return updated
    }
    var texts: [String] = []
    var dates: [Int32] = []
    for attribute in previous.attributes {
        if let attribute = attribute as? AyuEditHistoryMessageAttribute {
            texts = attribute.texts
            dates = attribute.dates
        }
    }
    var previousDate = previous.timestamp
    for attribute in previous.attributes {
        if let attribute = attribute as? EditedMessageAttribute {
            previousDate = attribute.date
        }
    }
    texts.append(previous.text)
    dates.append(previousDate)
    if texts.count > 30 {
        texts.removeFirst(texts.count - 30)
        dates.removeFirst(dates.count - 30)
    }
    var attributes = updated.attributes.filter { !($0 is AyuEditHistoryMessageAttribute) }
    attributes.append(AyuEditHistoryMessageAttribute(texts: texts, dates: dates))
    return updated.withUpdatedAttributes(attributes)
}
