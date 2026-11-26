import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

private struct AyuSettingsSnapshot: Equatable {
    var dontSendReadReceipts: Bool
    var dontSendTyping: Bool
    var dontSendOnline: Bool
    var dontReadStories: Bool
    var keepDeletedMessages: Bool
    var keepSecretChatMessages: Bool
    var dontSendScreenshotNotifications: Bool
    var disableAds: Bool
    var localPremium: Bool

    static func current() -> AyuSettingsSnapshot {
        return AyuSettingsSnapshot(
            dontSendReadReceipts: AyuConfig.dontSendReadReceipts,
            dontSendTyping: AyuConfig.dontSendTyping,
            dontSendOnline: AyuConfig.dontSendOnline,
            dontReadStories: AyuConfig.dontReadStories,
            keepDeletedMessages: AyuConfig.keepDeletedMessages,
            keepSecretChatMessages: AyuConfig.keepSecretChatMessages,
            dontSendScreenshotNotifications: AyuConfig.dontSendScreenshotNotifications,
            disableAds: AyuConfig.disableAds,
            localPremium: AyuConfig.localPremium
        )
    }
}

private final class AyuSettingsArguments {
    let toggle: (AyuSettingsToggle, Bool) -> Void
    let setGhostMode: (Bool) -> Void

    init(toggle: @escaping (AyuSettingsToggle, Bool) -> Void, setGhostMode: @escaping (Bool) -> Void) {
        self.toggle = toggle
        self.setGhostMode = setGhostMode
    }
}

private enum AyuSettingsToggle {
    case readReceipts
    case typing
    case online
    case stories
    case keepDeleted
    case keepSecret
    case screenshots
    case ads
    case localPremium
}

private enum AyuSettingsSection: Int32 {
    case ghost
    case messages
    case secret
    case other
}

private enum AyuSettingsEntry: ItemListNodeEntry {
    case ghostHeader
    case ghostAll(Bool)
    case readReceipts(Bool)
    case typing(Bool)
    case online(Bool)
    case stories(Bool)
    case ghostFooter

    case messagesHeader
    case keepDeleted(Bool)
    case messagesFooter

    case secretHeader
    case keepSecret(Bool)
    case screenshots(Bool)
    case secretFooter

    case otherHeader
    case ads(Bool)
    case localPremium(Bool)
    case otherFooter

    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .ghostAll, .readReceipts, .typing, .online, .stories, .ghostFooter:
            return AyuSettingsSection.ghost.rawValue
        case .messagesHeader, .keepDeleted, .messagesFooter:
            return AyuSettingsSection.messages.rawValue
        case .secretHeader, .keepSecret, .screenshots, .secretFooter:
            return AyuSettingsSection.secret.rawValue
        case .otherHeader, .ads, .localPremium, .otherFooter:
            return AyuSettingsSection.other.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .ghostHeader:
            return 0
        case .ghostAll:
            return 1
        case .readReceipts:
            return 2
        case .typing:
            return 3
        case .online:
            return 4
        case .stories:
            return 5
        case .ghostFooter:
            return 6
        case .messagesHeader:
            return 7
        case .keepDeleted:
            return 8
        case .messagesFooter:
            return 9
        case .secretHeader:
            return 10
        case .keepSecret:
            return 11
        case .screenshots:
            return 12
        case .secretFooter:
            return 13
        case .otherHeader:
            return 14
        case .ads:
            return 15
        case .localPremium:
            return 16
        case .otherFooter:
            return 17
        }
    }

    static func <(lhs: AyuSettingsEntry, rhs: AyuSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuSettingsArguments
        switch self {
        case .ghostHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "GHOST MODE", sectionId: self.section)
        case let .ghostAll(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Ghost mode (all)", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.setGhostMode(value)
            })
        case let .readReceipts(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Don't send read receipts", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(.readReceipts, value)
            })
        case let .typing(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Don't send typing status", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(.typing, value)
            })
        case let .online(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Don't send online status", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(.online, value)
            })
        case let .stories(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Don't mark stories as viewed", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(.stories, value)
            })
        case .ghostFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Chats you open stay marked as read on this device only. The sender will not see that you read their messages."), sectionId: self.section)
        case .messagesHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "MESSAGES", sectionId: self.section)
        case let .keepDeleted(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Keep deleted messages", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(.keepDeleted, value)
            })
        case .messagesFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Messages deleted by other people stay in the chat on this device (private chats, groups and channels)."), sectionId: self.section)
        case .secretHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "SECRET CHATS", sectionId: self.section)
        case let .keepSecret(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Keep secret chat messages", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(.keepSecret, value)
            })
        case let .screenshots(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Hide screenshot notifications", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(.screenshots, value)
            })
        case .secretFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Keeping messages ignores remote deletion and self-destruct timers in secret chats. It needs \"Keep deleted messages\" to be on."), sectionId: self.section)
        case .otherHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "OTHER", sectionId: self.section)
        case let .ads(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Disable ads", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(.ads, value)
            })
        case let .localPremium(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Local Premium", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.toggle(.localPremium, value)
            })
        case .otherFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Local Premium only unlocks Premium options in the interface on this device. Features that need the server (larger uploads, voice-to-text, premium emoji in sent messages) still require a real subscription. Restart the app after changing it."), sectionId: self.section)
        }
    }
}

private func ayuSettingsEntries(snapshot: AyuSettingsSnapshot) -> [AyuSettingsEntry] {
    var entries: [AyuSettingsEntry] = []

    let allGhost = snapshot.dontSendReadReceipts && snapshot.dontSendTyping && snapshot.dontSendOnline && snapshot.dontReadStories

    entries.append(.ghostHeader)
    entries.append(.ghostAll(allGhost))
    entries.append(.readReceipts(snapshot.dontSendReadReceipts))
    entries.append(.typing(snapshot.dontSendTyping))
    entries.append(.online(snapshot.dontSendOnline))
    entries.append(.stories(snapshot.dontReadStories))
    entries.append(.ghostFooter)

    entries.append(.messagesHeader)
    entries.append(.keepDeleted(snapshot.keepDeletedMessages))
    entries.append(.messagesFooter)

    entries.append(.secretHeader)
    entries.append(.keepSecret(snapshot.keepSecretChatMessages))
    entries.append(.screenshots(snapshot.dontSendScreenshotNotifications))
    entries.append(.secretFooter)

    entries.append(.otherHeader)
    entries.append(.ads(snapshot.disableAds))
    entries.append(.localPremium(snapshot.localPremium))
    entries.append(.otherFooter)

    return entries
}

public func ayuSettingsController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(AyuSettingsSnapshot.current(), ignoreRepeated: true)

    let arguments = AyuSettingsArguments(
        toggle: { toggle, value in
            switch toggle {
            case .readReceipts:
                AyuConfig.dontSendReadReceipts = value
            case .typing:
                AyuConfig.dontSendTyping = value
            case .online:
                AyuConfig.dontSendOnline = value
            case .stories:
                AyuConfig.dontReadStories = value
            case .keepDeleted:
                AyuConfig.keepDeletedMessages = value
            case .keepSecret:
                AyuConfig.keepSecretChatMessages = value
            case .screenshots:
                AyuConfig.dontSendScreenshotNotifications = value
            case .ads:
                AyuConfig.disableAds = value
            case .localPremium:
                AyuConfig.localPremium = value
            }
            statePromise.set(AyuSettingsSnapshot.current())
        },
        setGhostMode: { value in
            AyuConfig.setGhostMode(value)
            statePromise.set(AyuSettingsSnapshot.current())
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> map { presentationData, snapshot -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("AyuGram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: ayuSettingsEntries(snapshot: snapshot), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
