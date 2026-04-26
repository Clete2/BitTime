//
//  AppIntent.swift
//  BitTimeWidget (macOS)
//
//  This file MUST live inside the widget extension target so that
//  Xcode's `appintentsmetadataprocessor` can extract the intent AND
//  its parameter AppEnum, emitting `Metadata.appintents` into the
//  appex's Resources bundle. Without metadata for both the intent
//  and the AppEnum, WidgetKit cannot render the widget configuration
//  picker (parameter shows no options).
//

import AppIntents
import WidgetKit
import BitTimeCore

@available(macOS 14.0, *)
public enum WidgetThemeOption: String, CaseIterable, AppEnum {
    case defaultTheme = "Default"
    case terminalGreen = "Terminal Green"
    case terminalAmber = "Terminal Amber"
    case terminalBlue = "Terminal Blue"
    case neonPink = "Neon Pink"
    case electricPurple = "Electric Purple"

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Theme"

    public static var caseDisplayRepresentations: [WidgetThemeOption: DisplayRepresentation] = [
        .defaultTheme: "Default",
        .terminalGreen: "Terminal Green",
        .terminalAmber: "Terminal Amber",
        .terminalBlue: "Terminal Blue",
        .neonPink: "Neon Pink",
        .electricPurple: "Electric Purple"
    ]
}

@available(macOS 14.0, *)
public struct BitTimeWidgetConfigurationIntent: BitTimeThemeProvidingIntent {
    public static var title: LocalizedStringResource = "BitTime Theme"
    public static var description = IntentDescription("Choose the theme for this widget.")

    @Parameter(title: "Theme", default: .defaultTheme)
    public var theme: WidgetThemeOption

    public init() {}

    public var resolvedTheme: Theme {
        resolveWidgetTheme(forKey: theme.rawValue)
    }
}
