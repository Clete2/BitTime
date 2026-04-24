import SwiftUI
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#else
import UIKit
#endif

public extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

public struct ConditionalGlowModifier: ViewModifier {
    public let hasGlow: Bool
    public let color: PlatformColor
    
    public init(hasGlow: Bool, color: PlatformColor) {
        self.hasGlow = hasGlow
        self.color = color
    }
    
    public func body(content: Content) -> some View {
        if hasGlow {
            content.shadow(color: Color(color), radius: 3)
        } else {
            content
        }
    }
}