import AppIntents
import WidgetKit
import Foundation

// MARK: - Per-extension intent contract
//
// NOTE on per-extension intent / AppEnum registration:
// Apple's widget metadata extractor (`appintentsmetadataprocessor`) only sees
// AppIntent / AppEnum types that are compiled into the *extension target*
// itself. Types that live only in a linked framework are NOT picked up, and
// any `AppIntentConfiguration`-based widget whose intent (or its parameter
// enums) is not present in the extension's `Metadata.appintents` will fail
// to render the configuration UI properly (e.g. picker shows no options) or
// fail to render at all (blank tile).
//
// Therefore both the `WidgetConfigurationIntent` struct
// (`BitTimeWidgetConfigurationIntent`) AND its `WidgetThemeOption` AppEnum
// are defined per-extension in `BitTimeWidget/AppIntent.swift` and
// `BitTimeiOSWidget/AppIntent.swift`. They conform to / use the
// non-AppIntents helpers below so the shared widget factory in this
// framework can drive them generically.

/// Protocol that the per-extension `WidgetConfigurationIntent` types conform to
/// so the shared `UnifiedWidgetFactory` / `BitTimeWidgetProvider` can read the
/// user's chosen theme without itself owning any AppIntents-registered types
/// (which must live in the extension target for AppIntents metadata extraction).
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public protocol BitTimeThemeProvidingIntent: WidgetConfigurationIntent {
    /// Resolves the user's selection into a concrete `Theme`.
    var resolvedTheme: Theme { get }
    init()
}

/// Shared resolver used by the per-extension intents to map their
/// `WidgetThemeOption` raw value into a concrete `Theme`.
/// Centralised here so all extensions share the same mapping logic.
///
/// Each widget owns its own theme selection. The `.custom` theme is
/// intentionally not exposed in the open-source build because reading
/// the user's chosen colour requires the App Groups entitlement, which
/// requires a paid Apple Developer Program membership to sign.
public func resolveWidgetTheme(forKey rawValue: String) -> Theme {
    switch rawValue {
    case "Default":
        return .default
    case "Terminal Green":
        return .terminalGreen
    case "Terminal Amber":
        return .terminalAmber
    case "Terminal Blue":
        return .terminalBlue
    case "Neon Pink":
        return .neonPink
    case "Electric Purple":
        return .electricPurple
    default:
        return .default
    }
}
