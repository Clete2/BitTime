import Foundation

public enum Symbol: String, CaseIterable, Codable, Sendable {
    case digits = "1/0"
    case circles = "●/○"
    case rectangles = "▬/▭"
    case squares = "■/□"

    public var platformSupport: [Platform] {
        switch self {
        case .digits:
            return [.macOS, .watchOS, .iOS]
        case .circles:
            return [.macOS, .watchOS, .iOS]
        case .rectangles:
            return [.macOS, .iOS] // Not supported on watchOS
        case .squares:
            return [.macOS, .watchOS, .iOS]
        }
    }
    
    public static var currentPlatform: Platform {
        #if os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(iOS)
        return .iOS
        #else
        return .macOS // Default fallback
        #endif
    }
    
    public static var availableForCurrentPlatform: [Symbol] {
        return allCases.filter { $0.platformSupport.contains(currentPlatform) }
    }
}
