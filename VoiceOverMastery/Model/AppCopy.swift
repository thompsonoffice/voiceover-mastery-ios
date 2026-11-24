import Foundation
import SwiftUI

struct CopySection: Identifiable, Equatable {
    var heading: String
    var paragraphs: [String]
    var id: String { heading }
}

/// First-launch orientation for sighted learners. This is app text, not a chapter.
/// It only repeats the on/off path and the Screen Curtain caution already in the book.
enum OrientationCopy {
    static let sections: [CopySection] = [
        CopySection(
            heading: "About this screen",
            paragraphs: [
                "This screen is an orientation for the Access Mastery app. It is not a chapter of the book, and it does not add gestures or commands.",
                "It repeats the on-and-off path from Chapter 1.1 and a caution about Screen Curtain from Chapter 1.6. The chapters themselves keep the book's wording."
            ]
        ),
        CopySection(
            heading: "Gestures change while VoiceOver is on",
            paragraphs: [
                "While VoiceOver is on, the touches you use every day do different things. A single tap selects an item and speaks its name. It does not open the item. That change is expected.",
                "Chapter 1.1 and Chapter 1.3 describe what changes. If you want ordinary taps back, turn VoiceOver off with the Accessibility Shortcut below."
            ]
        ),
        CopySection(
            heading: "Turn VoiceOver on and off safely",
            paragraphs: [
                "Set the Accessibility Shortcut before you turn VoiceOver on, while ordinary taps still work.",
                "Open the Settings app, then Accessibility, then Accessibility Shortcut, and include VoiceOver. You can also turn VoiceOver on or off at Settings > Accessibility > VoiceOver.",
                "On an iPhone with Face ID, triple-click the side button to turn VoiceOver on or off. On iPhone SE, triple-click the Home button. If the shortcut includes only VoiceOver, that triple-click switches it immediately. If it includes more than one feature, the triple-click opens a list.",
                "You can also ask Siri to turn VoiceOver on or off.",
                "On iPad, use the same Settings path. Chapter 2.1 and Chapter 2.5 describe the iPad shortcut: triple-click the top button on an iPad with Face ID, or triple-click the Home button on an iPad with a Home button."
            ]
        ),
        CopySection(
            heading: "Screen Curtain",
            paragraphs: [
                "Screen Curtain turns the display off while VoiceOver stays on. The screen looks black, which is easy to mistake for a phone that is powered off.",
                "Leave Screen Curtain off until you can turn VoiceOver off with the Accessibility Shortcut without hesitating. Chapter 1.6 explains Screen Curtain, including what changes if Zoom is also on. This orientation does not ask you to turn Screen Curtain on."
            ]
        ),
        CopySection(
            heading: "Using the guide",
            paragraphs: [
                "Choose Continue to open the guide. Each chapter keeps the book's wording. Section headings are marked for VoiceOver's headings rotor.",
                "Progress and bookmarks stay on this device. Nothing is sent anywhere."
            ]
        )
    ]

    static var plainText: String {
        sections.map { section in
            ([section.heading] + section.paragraphs).joined(separator: "\n")
        }.joined(separator: "\n")
    }
}

/// Labels for the in-app practice controls. These controls are real accessibility elements.
/// The paragraphs do not describe a gesture that the chapters do not already contain.
enum PracticeCopy {
    static let sections: [CopySection] = [
        CopySection(
            heading: "About this practice screen",
            paragraphs: [
                "This screen is a practice surface inside Access Mastery. It is not a chapter, and it does not add VoiceOver gestures.",
                "The controls below are a real button, a real slider, and a real list, with labels and hints. Turn VoiceOver on with the Accessibility Shortcut from Chapter 1.1, then try gestures the iPhone chapters already describe, especially Chapter 1.3 and Chapter 1.8.",
                "This screen provides a Practice rotor so you can move among these controls with the rotor. The sample control also has custom actions. Chapter 1.8 explains the rotor and the Actions rotor item. The rotor name and the action names belong to this practice screen.",
                "Screen Curtain is not used here. Leave it off until you want it. Chapter 1.6 explains it."
            ]
        )
    ]

    static var plainText: String {
        sections.map { ([$0.heading] + $0.paragraphs).joined(separator: "\n") }.joined(separator: "\n")
    }
}

enum TextSizeOption: String, CaseIterable, Identifiable {
    case system
    case xSmall
    case small
    case medium
    case large
    case xLarge
    case xxLarge
    case xxxLarge
    case accessibility1
    case accessibility2
    case accessibility3
    case accessibility4
    case accessibility5

    static let storageKey = "voiceovermastery.textSize"
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Use device setting"
        case .xSmall: return "Extra small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large (system default)"
        case .xLarge: return "Extra large"
        case .xxLarge: return "Extra extra large"
        case .xxxLarge: return "Extra extra extra large"
        case .accessibility1: return "Accessibility size 1"
        case .accessibility2: return "Accessibility size 2"
        case .accessibility3: return "Accessibility size 3"
        case .accessibility4: return "Accessibility size 4"
        case .accessibility5: return "Accessibility size 5, largest"
        }
    }

    var dynamicTypeSize: DynamicTypeSize? {
        switch self {
        case .system: return nil
        case .xSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .xLarge
        case .xxLarge: return .xxLarge
        case .xxxLarge: return .xxxLarge
        case .accessibility1: return .accessibility1
        case .accessibility2: return .accessibility2
        case .accessibility3: return .accessibility3
        case .accessibility4: return .accessibility4
        case .accessibility5: return .accessibility5
        }
    }
}

enum StrongContrast {
    static let storageKey = "voiceovermastery.strongContrast"
}

private struct StrongContrastKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var strongContrast: Bool {
        get { self[StrongContrastKey.self] }
        set { self[StrongContrastKey.self] = newValue }
    }
}

struct PolicySection: Identifiable, Hashable {
    var heading: String
    var body: String
    var id: String { heading }
}

enum PrivacyPolicy {
    static let effectiveDate = "November 16, 2026"
    static let sections: [PolicySection] = [
        PolicySection(
            heading: "Summary",
            body: "Access Mastery does not collect, store, share, or sell any personal information. The developer, Hunter Thompson, receives no data from the app."
        ),
        PolicySection(
            heading: "Works offline",
            body: "The guide is included in the app. Access Mastery makes no network requests of its own and works with no internet connection."
        ),
        PolicySection(
            heading: "No accounts, ads, or tracking",
            body: "There are no accounts, sign-ins, analytics, advertising, tracking, or third-party software development kits. There is no purchase link in the app."
        ),
        PolicySection(
            heading: "What stays on your device",
            body: "Your audience choice, reading progress, bookmarks, last-opened chapter, text size, and contrast setting are saved only on your device. They are never sent to the developer or anyone else. Deleting the app deletes them. They may be included in your own device backups, which Apple handles under its privacy policy."
        ),
        PolicySection(
            heading: "Links",
            body: "Some chapters cite Apple documentation. If you open one of those source links, it opens in your browser, and that website's own privacy policy applies."
        ),
        PolicySection(
            heading: "Children",
            body: "Access Mastery collects no data from anyone, including children."
        ),
        PolicySection(
            heading: "Changes",
            body: "If this policy ever changes, the new version will appear in the app and on its web page with a new effective date."
        )
    ]
}
