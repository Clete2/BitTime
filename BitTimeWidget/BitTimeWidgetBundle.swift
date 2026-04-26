import WidgetKit
import SwiftUI

@main
struct BitTimeWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        // Numerical Widgets
        BitTimeNumericalWidget()
        BitTimeNumerical24Widget()
        BitTimeUnixWidget()
        BitTimeISO8601Widget()
        
        // BCD Widgets
        BitTimeBCDCirclesWidget()
        BitTimeBCD24CirclesWidget()
        BitTimeBCDRectanglesWidget()
        BitTimeBCD24RectanglesWidget()
    }
}
