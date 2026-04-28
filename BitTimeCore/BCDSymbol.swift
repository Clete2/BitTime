import Foundation

public enum Platform {
    case macOS
    case watchOS
    case iOS
}

public enum BCDSymbol: String, CaseIterable, Codable, Sendable {
    case circles = "●/○"
    case rectangles = "▬/▭"
    case squares = "■/□"
    
    public var filledSymbol: String {
        switch self {
        case .circles: return "●"
        case .rectangles: return "▬"
        case .squares: return "■"
        }
    }
    
    public var emptySymbol: String {
        switch self {
        case .circles: return "○"
        case .rectangles: return "▭"
        case .squares: return "□"
        }
    }
    
    public var formatting: BCDFormatting {
        switch self {
        case .circles:
            return BCDFormatting(
                regular: BCDSizeConfiguration(
                    fontSize: 8.0,
                    lineSpacing: 2.0,
                    lineHeightMultiplier: 0.6,
                    baselineOffset: -8.5,
                    fontName: "Menlo"
                ),
                large: BCDSizeConfiguration(
                    fontSize: 10.0,
                    lineSpacing: 2.0,
                    lineHeightMultiplier: 0.65,
                    baselineOffset: -11.0,
                    fontName: "Menlo"
                )
            )
        case .rectangles:
            return BCDFormatting(
                regular: BCDSizeConfiguration(
                    fontSize: 14.0,
                    lineSpacing: -5.0,
                    lineHeightMultiplier: 0.4,
                    baselineOffset: -9.5,
                    fontName: "Menlo"
                ),
                large: BCDSizeConfiguration(
                    fontSize: 16.0,
                    lineSpacing: -4.0,
                    lineHeightMultiplier: 0.45,
                    baselineOffset: -10.5,
                    fontName: "Menlo"
                )
            )
        case .squares:
            return BCDFormatting(
                regular: BCDSizeConfiguration(
                    fontSize: 8.0,
                    lineSpacing: 1.0,
                    lineHeightMultiplier: 0.6,
                    baselineOffset: -8.5,
                    fontName: "Menlo"
                ),
                large: BCDSizeConfiguration(
                    fontSize: 10.0,
                    lineSpacing: 2.0,
                    lineHeightMultiplier: 0.65,
                    baselineOffset: -11.0,
                    fontName: "Menlo"
                )
            )
        }
    }
    
    public var platformSupport: [Platform] {
        switch self {
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
    
    public static var availableForCurrentPlatform: [BCDSymbol] {
        return allCases.filter { $0.platformSupport.contains(currentPlatform) }
    }
}

public struct BCDSizeConfiguration {
    public let fontSize: CGFloat
    public let lineSpacing: CGFloat
    public let lineHeightMultiplier: CGFloat
    public let baselineOffset: CGFloat
    public let fontName: String
    
    public init(fontSize: CGFloat, lineSpacing: CGFloat, lineHeightMultiplier: CGFloat, baselineOffset: CGFloat, fontName: String) {
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.lineHeightMultiplier = lineHeightMultiplier
        self.baselineOffset = baselineOffset
        self.fontName = fontName
    }
}

public struct BCDFormatting {
    public let regular: BCDSizeConfiguration
    public let large: BCDSizeConfiguration
    
    public init(regular: BCDSizeConfiguration, large: BCDSizeConfiguration) {
        self.regular = regular
        self.large = large
    }
    
    public func configuration(forLargeSize isLarge: Bool) -> BCDSizeConfiguration {
        return isLarge ? large : regular
    }
}
