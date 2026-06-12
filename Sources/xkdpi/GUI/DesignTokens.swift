import AppKit

/// デザイントークン: 色・余白・フォント・レイアウト定数を一元管理
enum DesignTokens {

    // MARK: - Colors

    enum Colors {
        /// サイドバー選択行の背景
        static var sidebarSelection: NSColor {
            NSColor.controlAccentColor.withAlphaComponent(0.20)
        }
        /// カードボーダー
        static var cardBorder: NSColor { .separatorColor }
        /// Hz バッジ背景（彩度抑制: 0.85 → 0.35）
        static var hzBadgeBackground: NSColor {
            NSColor.tertiaryLabelColor.withAlphaComponent(0.35)
        }
        /// Hz バッジ文字色
        static var hzBadgeText: NSColor { .secondaryLabelColor }
        /// Recommended バッジ背景
        static var recommendedBadge: NSColor {
            NSColor.systemOrange.withAlphaComponent(0.90)
        }
        /// セクション見出し
        static var sectionHeader: NSColor { .secondaryLabelColor }
        /// 補助テキスト
        static var auxiliary: NSColor { .tertiaryLabelColor }
        /// 種別ピル（内蔵）
        static var typePillBuiltin: NSColor {
            NSColor.systemBlue.withAlphaComponent(0.85)
        }
        /// 種別ピル（外部）
        static var typePillExternal: NSColor {
            NSColor.systemGray.withAlphaComponent(0.85)
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let sectionGap: CGFloat = 20
        static let itemGap: CGFloat = 8
        static let cardPadding: CGFloat = 12
        static let panePadding: CGFloat = 20
        static let sidebarRowHeight: CGFloat = 56
    }

    // MARK: - Typography

    enum Typography {
        static var title: NSFont { .boldSystemFont(ofSize: 20) }
        static var displayName: NSFont { .boldSystemFont(ofSize: 16) }
        static var heroResolution: NSFont { .systemFont(ofSize: 28, weight: .light) }
        static var cardResolution: NSFont { .systemFont(ofSize: 14, weight: .semibold) }
        static var sectionHeader: NSFont { .boldSystemFont(ofSize: 12) }
        static var body: NSFont { .systemFont(ofSize: 13) }
        static var badge: NSFont { .monospacedDigitSystemFont(ofSize: 10, weight: .semibold) }
        static var auxiliary: NSFont { .systemFont(ofSize: 11) }
    }

    // MARK: - Layout

    enum Layout {
        static let sidebarWidth: CGFloat = 200
        static let sidebarMinWidth: CGFloat = 160
        static let sidebarMaxWidth: CGFloat = 260
        static let detailMinWidth: CGFloat = 340
        static let windowWidth: CGFloat = 640
        static let windowHeight: CGFloat = 600
        static let windowMinWidth: CGFloat = 500
        static let windowMinHeight: CGFloat = 400
        static let cardCornerRadius: CGFloat = 8
        static let heroCornerRadius: CGFloat = 12
    }
}
