import SwiftUI

// Custom Canvas/Shape icons (no SF Symbols, no emoji).

struct BoothIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, s in
            // Microphone icon
            let cx = s.width / 2
            let capW = s.width * 0.42
            let capH = s.height * 0.50
            let capRect = CGRect(x: cx - capW/2, y: s.height * 0.08, width: capW, height: capH)
            ctx.fill(Path(roundedRect: capRect, cornerRadius: capW/2), with: .color(color))
            // grille lines
            for i in 1..<3 {
                let y = capRect.minY + capRect.height * CGFloat(i) / 3
                var p = Path(); p.move(to: CGPoint(x: capRect.minX, y: y)); p.addLine(to: CGPoint(x: capRect.maxX, y: y))
                ctx.stroke(p, with: .color(RadioTheme.bg.opacity(0.5)), lineWidth: s.width * 0.03)
            }
            // arc stand
            let arc = Path { p in
                p.addArc(center: CGPoint(x: cx, y: s.height * 0.45),
                         radius: s.width * 0.34, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
            }
            ctx.stroke(arc, with: .color(color), lineWidth: s.width * 0.06)
            // post + base
            var post = Path(); post.move(to: CGPoint(x: cx, y: s.height * 0.70)); post.addLine(to: CGPoint(x: cx, y: s.height * 0.90))
            ctx.stroke(post, with: .color(color), lineWidth: s.width * 0.06)
            var base = Path(); base.move(to: CGPoint(x: cx - s.width*0.18, y: s.height*0.92)); base.addLine(to: CGPoint(x: cx + s.width*0.18, y: s.height*0.92))
            ctx.stroke(base, with: .color(color), lineWidth: s.width * 0.06)
        }
        .frame(width: size, height: size)
    }
}

struct CrateIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, s in
            // Vinyl crate: box with two records peeking
            let box = CGRect(x: s.width*0.12, y: s.height*0.40, width: s.width*0.76, height: s.height*0.48)
            ctx.stroke(Path(roundedRect: box, cornerRadius: s.width*0.06), with: .color(color), lineWidth: s.width*0.06)
            // two record tops
            for (i, off) in [0.30, 0.55].enumerated() {
                let cy = s.height * CGFloat(off)
                let r = s.width * 0.16
                let cx = s.width * (i == 0 ? 0.40 : 0.60)
                ctx.stroke(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r*2, height: r*2)),
                           with: .color(color.opacity(0.9)), lineWidth: s.width*0.035)
                ctx.fill(Path(ellipseIn: CGRect(x: cx - r*0.2, y: cy - r*0.2, width: r*0.4, height: r*0.4)),
                         with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}

struct AlmanacIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, s in
            // Bar chart icon
            let base = s.height * 0.85
            let heights: [CGFloat] = [0.35, 0.60, 0.45, 0.78]
            let bw = s.width * 0.15
            let gap = (s.width * 0.7 - bw * 4) / 3
            for (i, h) in heights.enumerated() {
                let x = s.width * 0.15 + CGFloat(i) * (bw + gap)
                let top = base - s.height * h
                let rect = CGRect(x: x, y: top, width: bw, height: base - top)
                ctx.fill(Path(roundedRect: rect, cornerRadius: bw*0.3), with: .color(color))
            }
            var axis = Path(); axis.move(to: CGPoint(x: s.width*0.10, y: base)); axis.addLine(to: CGPoint(x: s.width*0.92, y: base))
            ctx.stroke(axis, with: .color(color.opacity(0.7)), lineWidth: s.width*0.04)
        }
        .frame(width: size, height: size)
    }
}

struct SettingsIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, s in
            // Slider knobs (equalizer settings)
            let rows = 3
            for i in 0..<rows {
                let y = s.height * (0.25 + CGFloat(i) * 0.25)
                var line = Path(); line.move(to: CGPoint(x: s.width*0.15, y: y)); line.addLine(to: CGPoint(x: s.width*0.85, y: y))
                ctx.stroke(line, with: .color(color.opacity(0.6)), lineWidth: s.width*0.04)
                let knobX = s.width * [0.65, 0.35, 0.55][i]
                let r = s.width * 0.09
                ctx.fill(Path(ellipseIn: CGRect(x: knobX - r, y: y - r, width: r*2, height: r*2)), with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}

// Small genre dot / energy indicator
struct EnergyDots: View {
    var energy: Int
    var color: Color
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(i < energy ? color : RadioTheme.stroke.opacity(0.5))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// Records currency pip
struct RecordPip: View {
    var size: CGFloat = 16
    var body: some View {
        Canvas { ctx, s in
            let c = CGPoint(x: s.width/2, y: s.height/2)
            let r = min(s.width, s.height)/2
            ctx.fill(Path(ellipseIn: CGRect(x: c.x-r, y: c.y-r, width: r*2, height: r*2)),
                     with: .color(RadioTheme.bgDeep))
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x-r*0.95, y: c.y-r*0.95, width: r*1.9, height: r*1.9)),
                       with: .color(RadioTheme.amber), lineWidth: r*0.12)
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x-r*0.55, y: c.y-r*0.55, width: r*1.1, height: r*1.1)),
                       with: .color(RadioTheme.amber.opacity(0.6)), lineWidth: r*0.08)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x-r*0.16, y: c.y-r*0.16, width: r*0.32, height: r*0.32)),
                     with: .color(RadioTheme.amber))
        }
        .frame(width: size, height: size)
    }
}
