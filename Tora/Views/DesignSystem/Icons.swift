import SwiftUI

enum ToraIcon {
    static let check       = "checkmark"
    static let checkCircle = "checkmark.circle.fill"
    static let circle      = "circle"
    static let xmark       = "xmark"
    static let clock       = "clock"
    static let building    = "building.2"
    static let tag         = "tag"
    static let slack       = "bubble.left.and.bubble.right"
    static let mail        = "envelope"
    static let settings    = "gearshape"
    static let list        = "list.bullet"
    static let plus        = "plus"
    static let search      = "magnifyingglass"
    static let bell        = "bell"
    static let bolt        = "bolt.fill"
    static let inbox       = "tray"
    static let arrow       = "arrow.right"
    static let chev        = "chevron.right"
    static let chevDown    = "chevron.down"
    static let flag        = "flag"
    static let external    = "arrow.up.right.square"
    static let filter      = "line.3.horizontal.decrease"
    static let sort        = "arrow.up.arrow.down"
    static let user        = "person.crop.circle"
}

struct GlyphView: View {
    enum Variant: String, CaseIterable, Identifiable {
        case mascot
        case bolt
        case rune

        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .mascot: return "Mascot"
            case .bolt:   return "Bolt"
            case .rune:   return "Rune"
            }
        }
    }

    let variant: Variant
    var size: CGFloat = 16

    var body: some View {
        switch variant {
        case .mascot:
            Image("Mascot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        case .bolt:
            Image(systemName: ToraIcon.bolt)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.85, height: size * 0.85)
                .foregroundStyle(.primary)
        case .rune:
            Canvas { ctx, sz in
                let s = min(sz.width, sz.height)
                var path = Path()
                let pad: CGFloat = s * 0.16
                let top = pad
                let bottom = s - pad
                let left = pad
                let right = s - pad
                let mid = s / 2
                path.move(to: CGPoint(x: left, y: top))
                path.addLine(to: CGPoint(x: right, y: top))
                path.move(to: CGPoint(x: mid, y: top))
                path.addLine(to: CGPoint(x: mid, y: bottom))
                path.move(to: CGPoint(x: left + s * 0.1, y: top + s * 0.16))
                path.addLine(to: CGPoint(x: mid, y: top))
                path.addLine(to: CGPoint(x: right - s * 0.1, y: top + s * 0.16))
                ctx.stroke(path, with: .color(.primary), style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
            }
            .frame(width: size, height: size)
        }
    }
}
