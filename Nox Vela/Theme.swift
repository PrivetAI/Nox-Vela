import SwiftUI

// Warm amber / neon late-night palette. All custom RGB — theme independent.
enum RadioTheme {
    static let bg = Color(red: 0.06, green: 0.05, blue: 0.09)          // near-black indigo
    static let bgDeep = Color(red: 0.03, green: 0.03, blue: 0.06)      // deeper panel
    static let card = Color(red: 0.12, green: 0.10, blue: 0.16)        // card surface
    static let cardHi = Color(red: 0.17, green: 0.14, blue: 0.22)      // raised card
    static let amber = Color(red: 1.0, green: 0.74, blue: 0.30)        // warm amber
    static let amberDeep = Color(red: 0.95, green: 0.55, blue: 0.18)   // deep amber
    static let neon = Color(red: 0.35, green: 0.85, blue: 0.95)        // neon cyan
    static let neonPink = Color(red: 0.95, green: 0.40, blue: 0.70)    // neon magenta
    static let textHi = Color(red: 0.98, green: 0.96, blue: 0.92)      // warm white
    static let textMid = Color(red: 0.78, green: 0.74, blue: 0.72)
    static let textDim = Color(red: 0.50, green: 0.47, blue: 0.52)
    static let good = Color(red: 0.45, green: 0.88, blue: 0.55)        // gain green
    static let bad = Color(red: 0.95, green: 0.42, blue: 0.42)         // loss red
    static let stroke = Color(red: 0.30, green: 0.26, blue: 0.36)

    static func genreColor(_ g: Genre) -> Color {
        switch g {
        case .jazz:    return Color(red: 0.95, green: 0.62, blue: 0.30)
        case .soul:    return Color(red: 0.95, green: 0.42, blue: 0.55)
        case .ambient: return Color(red: 0.40, green: 0.78, blue: 0.92)
        case .synth:   return Color(red: 0.62, green: 0.50, blue: 0.95)
        case .folk:    return Color(red: 0.55, green: 0.82, blue: 0.50)
        case .blues:   return Color(red: 0.40, green: 0.55, blue: 0.92)
        case .lounge:  return Color(red: 0.92, green: 0.78, blue: 0.42)
        }
    }
}

// Reusable card background
struct RadioCard: ViewModifier {
    var raised: Bool = false
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(raised ? RadioTheme.cardHi : RadioTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(RadioTheme.stroke.opacity(0.5), lineWidth: 1)
            )
    }
}

extension View {
    func radioCard(raised: Bool = false) -> some View {
        self.modifier(RadioCard(raised: raised))
    }
}
