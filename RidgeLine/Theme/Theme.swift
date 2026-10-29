import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

/// Warm-daylight national-park palette. Light only: readable in direct mountain sun.
enum RL {
    static let canvas = Color(hex: 0xF4EFE6)   // Warm Sandstone
    static let card = Color(hex: 0xFFFDF9)     // Parchment
    static let border = Color(hex: 0xE2D9C8)
    static let pine = Color(hex: 0x2D5A3C)     // Forest Pine Green
    static let blaze = Color(hex: 0xC85A32)    // Terracotta Trail Blaze
    static let ink = Color(hex: 0x1C2826)      // primary text
    static let slate = Color(hex: 0x5A6561)    // secondary text

    // Supporting earth tones for map markers and tints (all warm, all light-mode).
    static let umber = Color(hex: 0x7A4B2A)
    static let ochre = Color(hex: 0x8C6D1F)
    static let pineTint = Color(hex: 0xE3EDE5)
    static let blazeTint = Color(hex: 0xF7E3D9)

    static func font(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    static func color(for kind: PlaceKind) -> Color {
        switch kind {
        case .origin: return slate
        case .trailhead: return pine
        case .summit: return umber
        case .landmark: return ochre
        case .camp: return blaze
        case .town: return slate
        }
    }
}

enum Appearance {
    static func apply() {
        let ink = UIColor(RL.ink)

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(RL.canvas)
        nav.shadowColor = UIColor(RL.border)
        let rounded: (CGFloat, UIFont.Weight) -> UIFont = { size, weight in
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            if let d = base.fontDescriptor.withDesign(.rounded) { return UIFont(descriptor: d, size: size) }
            return base
        }
        nav.titleTextAttributes = [.foregroundColor: ink, .font: rounded(17, .bold)]
        nav.largeTitleTextAttributes = [.foregroundColor: ink, .font: rounded(32, .bold)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(RL.card)
        tab.shadowColor = UIColor(RL.border)
        let selected = UIColor(RL.pine), normal = UIColor(RL.slate)
        for item in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            item.selected.iconColor = selected
            item.selected.titleTextAttributes = [.foregroundColor: selected]
            item.normal.iconColor = normal
            item.normal.titleTextAttributes = [.foregroundColor: normal]
        }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}

// MARK: - Card & text helpers

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RL.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(RL.border, lineWidth: 1))
    }
}

extension View {
    func rlCard(padding: CGFloat = 16) -> some View { modifier(CardStyle(padding: padding)) }

    /// Standard screen scaffolding: sandstone canvas behind a scroll view.
    func rlScreen() -> some View {
        self
            .background(RL.canvas.ignoresSafeArea())
            .toolbarBackground(RL.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = RL.pine
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RL.font(.subheadline, .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(tint.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = RL.pine
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RL.font(.subheadline, .bold))
            .foregroundStyle(tint)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(configuration.isPressed ? RL.pineTint : RL.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(tint.opacity(0.5), lineWidth: 1.5))
    }
}
