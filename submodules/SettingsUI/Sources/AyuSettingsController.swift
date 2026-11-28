import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import PromptUI

private enum AyuSettingsToggle {
    case readReceipts
    case typing
    case online
    case stories
    case keepDeleted
    case keepSecret
    case screenshotNotices
    case ads
    case localPremium
    case keepMedia
    case allowShots
    case bypassCopyProtection
    case chatActivity
}

private enum AyuSettingsInput {
    case deletedMark
    case editedMark
    case filterUserIds
    case filterRegex
}

private enum AyuSettingsAction {
    case ticTacToe
}

private struct AyuSettingsSnapshot: Equatable {
    var values: [Bool]
    var deletedMark: String
    var editedMark: String
    var filterUserIds: String
    var filterRegex: String
    
    static func current() -> AyuSettingsSnapshot {
        return AyuSettingsSnapshot(
            values: [
                AyuConfig.dontSendReadReceipts,
                AyuConfig.dontSendTyping,
                AyuConfig.dontSendOnline,
                AyuConfig.dontReadStories,
                AyuConfig.keepDeletedMessages,
                AyuConfig.keepSecretChatMessages,
                AyuConfig.dontSendScreenshotNotifications,
                AyuConfig.disableAds,
                AyuConfig.localPremium,
                AyuConfig.keepSelfDestructingMedia,
                AyuConfig.allowScreenshots,
                AyuConfig.bypassCopyProtection,
                AyuConfig.showChatActivity
            ],
            deletedMark: AyuConfig.deletedMark,
            editedMark: AyuConfig.editedMark ?? "",
            filterUserIds: AyuConfig.filterUserIds,
            filterRegex: AyuConfig.filterRegex
        )
    }
}

private final class AyuSettingsArguments {
    let toggle: (AyuSettingsToggle, Bool) -> Void
    let setGhostMode: (Bool) -> Void
    let edit: (AyuSettingsInput) -> Void
    let perform: (AyuSettingsAction) -> Void
    
    init(toggle: @escaping (AyuSettingsToggle, Bool) -> Void, setGhostMode: @escaping (Bool) -> Void, edit: @escaping (AyuSettingsInput) -> Void, perform: @escaping (AyuSettingsAction) -> Void) {
        self.toggle = toggle
        self.setGhostMode = setGhostMode
        self.edit = edit
        self.perform = perform
    }
}

private enum AyuSettingsEntry: ItemListNodeEntry {
    case header(Int32, Int32, String)
    case ghostAll(Int32, Int32, Bool)
    case toggle(Int32, Int32, String, AyuSettingsToggle, Bool)
    case input(Int32, Int32, String, String, AyuSettingsInput)
    case action(Int32, Int32, String, AyuSettingsAction)
    case footer(Int32, Int32, String)
    
    var section: ItemListSectionId {
        switch self {
        case let .header(_, section, _), let .ghostAll(_, section, _), let .toggle(_, section, _, _, _), let .input(_, section, _, _, _), let .action(_, section, _, _), let .footer(_, section, _):
            return section
        }
    }
    
    var stableId: Int32 {
        switch self {
        case let .header(id, _, _), let .ghostAll(id, _, _), let .toggle(id, _, _, _, _), let .input(id, _, _, _, _), let .action(id, _, _, _), let .footer(id, _, _):
            return id
        }
    }
    
    static func ==(lhs: AyuSettingsEntry, rhs: AyuSettingsEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.header(a, b, c), .header(d, e, f)):
            return a == d && b == e && c == f
        case let (.ghostAll(a, b, c), .ghostAll(d, e, f)):
            return a == d && b == e && c == f
        case let (.toggle(a, b, c, _, e), .toggle(f, g, h, _, j)):
            return a == f && b == g && c == h && e == j
        case let (.input(a, b, c, d, _), .input(e, f, g, h, _)):
            return a == e && b == f && c == g && d == h
        case let (.action(a, b, c, _), .action(d, e, f, _)):
            return a == d && b == e && c == f
        case let (.footer(a, b, c), .footer(d, e, f)):
            return a == d && b == e && c == f
        default:
            return false
        }
    }
    
    static func <(lhs: AyuSettingsEntry, rhs: AyuSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuSettingsArguments
        switch self {
        case let .header(_, section, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .ghostAll(_, section, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Режим призрака (всё сразу)", value: value, sectionId: section, style: .blocks, updated: { value in
                arguments.setGhostMode(value)
            })
        case let .toggle(_, section, title, toggle, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: section, style: .blocks, updated: { value in
                arguments.toggle(toggle, value)
            })
        case let .input(_, section, title, label, input):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: label, sectionId: section, style: .blocks, action: {
                arguments.edit(input)
            })
        case let .action(_, section, title, action):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: "", sectionId: section, style: .blocks, action: {
                arguments.perform(action)
            })
        case let .footer(_, section, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
        }
    }
}

private func ayuSettingsEntries(snapshot: AyuSettingsSnapshot) -> [AyuSettingsEntry] {
    let v = snapshot.values
    var entries: [AyuSettingsEntry] = []
    
    let allGhost = v[0] && v[1] && v[2] && v[3]
    entries.append(.header(0, 0, "РЕЖИМ ПРИЗРАКА"))
    entries.append(.ghostAll(1, 0, allGhost))
    entries.append(.toggle(2, 0, "Не отправлять отметку о прочтении", .readReceipts, v[0]))
    entries.append(.toggle(3, 0, "Не показывать, что я печатаю", .typing, v[1]))
    entries.append(.toggle(4, 0, "Не показывать, что я в сети", .online, v[2]))
    entries.append(.toggle(5, 0, "Не отмечать истории просмотренными", .stories, v[3]))
    entries.append(.footer(6, 0, "Чаты остаются прочитанными только на этом устройстве. Отправитель не увидит, что ты прочитал сообщение или посмотрел историю."))
    
    entries.append(.header(10, 1, "СООБЩЕНИЯ"))
    entries.append(.toggle(11, 1, "Сохранять удалённые сообщения", .keepDeleted, v[4]))
    entries.append(.input(12, 1, "Пометка «удалено»", snapshot.deletedMark.isEmpty ? "нет" : snapshot.deletedMark, .deletedMark))
    entries.append(.input(13, 1, "Пометка «изменено»", snapshot.editedMark.isEmpty ? "стандартная" : snapshot.editedMark, .editedMark))
    entries.append(.footer(14, 1, "Сообщения, которые удалили другие, остаются в чате на этом устройстве (личные чаты, группы и каналы). У изменённых сообщений в меню появляется «История правок»."))
    
    entries.append(.header(20, 2, "СЕКРЕТНЫЕ ЧАТЫ"))
    entries.append(.toggle(21, 2, "Сохранять сообщения секретных чатов", .keepSecret, v[5]))
    entries.append(.toggle(22, 2, "Скрывать уведомления о скриншотах", .screenshotNotices, v[6]))
    entries.append(.footer(23, 2, "Сохранение игнорирует удаление и таймеры самоуничтожения в секретных чатах. Нужен включённый пункт «Сохранять удалённые сообщения»."))
    
    entries.append(.header(30, 3, "СГОРАЮЩИЕ МЕДИА И СКРИНШОТЫ"))
    entries.append(.toggle(31, 3, "Сохранять сгорающие медиа", .keepMedia, v[9]))
    entries.append(.toggle(32, 3, "Разрешить скриншоты везде", .allowShots, v[10]))
    entries.append(.toggle(33, 3, "Пересылка и сохранение из защищённых чатов", .bypassCopyProtection, v[11]))
    entries.append(.footer(34, 3, "Фото, видео и кружки «на один просмотр» остаются после открытия. Открой медиа один раз, чтобы оно скачалось. Последний пункт снимает запрет пересылки, поставленный владельцем канала или группы. Применяй на свою ответственность. После изменения перезапусти приложение."))
    
    entries.append(.header(40, 4, "ПРОЧЕЕ"))
    entries.append(.toggle(41, 4, "Отключить рекламу", .ads, v[7]))
    entries.append(.toggle(42, 4, "Показывать активность в чате", .chatActivity, v[12]))
    entries.append(.footer(43, 4, "Активность в чате: рядом со статусом собеседника показывается, когда он последний раз написал, начал печатать или прочитал твоё сообщение именно в вашем чате. Показывает только то, что человек сам сделал в вашем чате."))
    
    entries.append(.header(50, 5, "ЛОКАЛЬНЫЙ PREMIUM"))
    entries.append(.toggle(51, 5, "Локальный Premium", .localPremium, v[8]))
    entries.append(.footer(52, 5, "Включает Premium-интерфейс только на этом устройстве: эмодзи, реакции, стикеры, эмодзи-статус и цвета профиля. Статус и цвета ставятся обычным способом (Настройки → Изменить профиль), но их видишь только ты. Отправленные Premium-эмодзи и реакции у других выглядят обычными. Чтобы вернуть кнопку покупки Premium, выключи этот пункт и перезапусти приложение."))
    
    entries.append(.header(60, 6, "ФИЛЬТРЫ"))
    entries.append(.input(61, 6, "Скрывать сообщения от (ID)", snapshot.filterUserIds.isEmpty ? "нет" : snapshot.filterUserIds, .filterUserIds))
    entries.append(.input(62, 6, "Скрывать по слову (regex)", snapshot.filterRegex.isEmpty ? "нет" : snapshot.filterRegex, .filterRegex))
    entries.append(.footer(63, 6, "Сообщения скрываются только у тебя на устройстве. ID пользователей через запятую. В поле regex можно писать слова через | , например: реклама|скидка."))
    
    entries.append(.header(70, 7, "ИГРЫ"))
    entries.append(.action(71, 7, "Крестики-нолики", .ticTacToe))
    
    return entries
}

public func ayuSettingsController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(AyuSettingsSnapshot.current(), ignoreRepeated: true)
    var presentControllerImpl: ((ViewController) -> Void)?
    var pushControllerImpl: ((ViewController) -> Void)?
    
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
            case .screenshotNotices:
                AyuConfig.dontSendScreenshotNotifications = value
            case .ads:
                AyuConfig.disableAds = value
            case .localPremium:
                AyuConfig.localPremium = value
            case .keepMedia:
                AyuConfig.keepSelfDestructingMedia = value
            case .allowShots:
                AyuConfig.allowScreenshots = value
            case .bypassCopyProtection:
                AyuConfig.bypassCopyProtection = value
            case .chatActivity:
                AyuConfig.showChatActivity = value
            }
            statePromise.set(AyuSettingsSnapshot.current())
        },
        setGhostMode: { value in
            AyuConfig.setGhostMode(value)
            statePromise.set(AyuSettingsSnapshot.current())
        },
        edit: { input in
            let title: String
            let value: String
            switch input {
            case .deletedMark:
                title = "Пометка «удалено»"
                value = AyuConfig.deletedMark
            case .editedMark:
                title = "Пометка «изменено» (пусто = стандартная)"
                value = AyuConfig.editedMark ?? ""
            case .filterUserIds:
                title = "ID пользователей через запятую"
                value = AyuConfig.filterUserIds
            case .filterRegex:
                title = "Регулярное выражение"
                value = AyuConfig.filterRegex
            }
            presentControllerImpl?(promptController(context: context, text: title, value: value, apply: { result in
                guard let result = result else {
                    return
                }
                let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
                switch input {
                case .deletedMark:
                    AyuConfig.deletedMark = trimmed
                case .editedMark:
                    AyuConfig.editedMark = trimmed.isEmpty ? nil : trimmed
                case .filterUserIds:
                    AyuConfig.filterUserIds = trimmed
                case .filterRegex:
                    AyuConfig.filterRegex = trimmed
                }
                statePromise.set(AyuSettingsSnapshot.current())
            }))
        },
        perform: { action in
            switch action {
            case .ticTacToe:
                pushControllerImpl?(AyuTicTacToeController(context: context))
            }
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
    
    let controller = ItemListController(context: context, state: signal)
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    return controller
}
