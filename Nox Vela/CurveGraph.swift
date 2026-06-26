import SwiftUI

// Energy planning curve: planned energy vs. target curve. Drawn with Canvas.
// Anchors math to parent-passed screenSize (see swiftui_canvas_size_pitfall).
struct EnergyCurveGraph: View {
    var planned: [Double?]      // length slotCount, nil for empty
    var screenSize: CGSize      // parent geometry width

    private let pad: CGFloat = 14

    var body: some View {
        let w = max(screenSize.width - 60, 100) // card inner width (outer .padding 16 + card .padding 14 per side)
        let h: CGFloat = 96
        Canvas { ctx, _ in
            let plotW = w - pad * 2
            let plotH = h - pad * 2
            let n = NightConstants.slotCount
            func x(_ i: Int) -> CGFloat { pad + plotW * CGFloat(i) / CGFloat(n - 1) }
            func y(_ e: Double) -> CGFloat {
                // energy 1...5 -> bottom...top
                let t = (e - 1) / 4
                return pad + plotH * (1 - CGFloat(t))
            }

            // gridlines
            for lvl in 1...5 {
                let yy = y(Double(lvl))
                var p = Path(); p.move(to: CGPoint(x: pad, y: yy)); p.addLine(to: CGPoint(x: w - pad, y: yy))
                ctx.stroke(p, with: .color(RadioTheme.stroke.opacity(0.25)), lineWidth: 1)
            }

            // target curve (descending) — dashed amber
            var target = Path()
            for i in 0..<n {
                let pt = CGPoint(x: x(i), y: y(NightConstants.targetEnergy(i)))
                if i == 0 { target.move(to: pt) } else { target.addLine(to: pt) }
            }
            ctx.stroke(target, with: .color(RadioTheme.amber.opacity(0.55)),
                       style: StrokeStyle(lineWidth: 2, dash: [5, 4]))

            // planned curve — neon, segments only between consecutive filled slots
            for i in 0..<(n - 1) {
                if let a = planned[i], let b = planned[i+1] {
                    var seg = Path()
                    seg.move(to: CGPoint(x: x(i), y: y(a)))
                    seg.addLine(to: CGPoint(x: x(i+1), y: y(b)))
                    ctx.stroke(seg, with: .color(RadioTheme.neon), lineWidth: 2.5)
                }
            }
            // planned points
            for i in 0..<n {
                if let e = planned[i] {
                    let r: CGFloat = 3.5
                    ctx.fill(Path(ellipseIn: CGRect(x: x(i)-r, y: y(e)-r, width: r*2, height: r*2)),
                             with: .color(RadioTheme.neon))
                }
            }
        }
        .frame(width: w, height: h)
    }
}

// Animated listener curve for the result overlay.
struct ListenerCurveGraph: View {
    var series: [Int]
    var target: Int
    var progress: CGFloat   // 0...1 reveal animation
    var screenSize: CGSize

    private let pad: CGFloat = 18

    var body: some View {
        let w = max(screenSize.width - 64, 100)
        let h: CGFloat = 140
        let maxV = max(series.max() ?? 100, target, 1)
        Canvas { ctx, _ in
            let plotW = w - pad * 2
            let plotH = h - pad * 2
            let n = series.count
            func x(_ i: Int) -> CGFloat { pad + plotW * CGFloat(i) / CGFloat(max(n - 1, 1)) }
            func y(_ v: Int) -> CGFloat {
                let t = Double(v) / Double(maxV)
                return pad + plotH * (1 - CGFloat(t))
            }

            // target line
            let ty = y(target)
            var tline = Path(); tline.move(to: CGPoint(x: pad, y: ty)); tline.addLine(to: CGPoint(x: w - pad, y: ty))
            ctx.stroke(tline, with: .color(RadioTheme.neonPink.opacity(0.6)),
                       style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))

            // how many points to reveal
            let revealCount = max(2, Int(ceil(CGFloat(n) * progress)))
            let count = min(revealCount, n)

            // area fill
            var area = Path()
            area.move(to: CGPoint(x: x(0), y: h - pad))
            for i in 0..<count { area.addLine(to: CGPoint(x: x(i), y: y(series[i]))) }
            area.addLine(to: CGPoint(x: x(count - 1), y: h - pad))
            area.closeSubpath()
            ctx.fill(area, with: .linearGradient(
                Gradient(colors: [RadioTheme.amber.opacity(0.35), RadioTheme.amber.opacity(0.02)]),
                startPoint: CGPoint(x: 0, y: pad), endPoint: CGPoint(x: 0, y: h - pad)))

            // line
            var line = Path()
            for i in 0..<count {
                let pt = CGPoint(x: x(i), y: y(series[i]))
                if i == 0 { line.move(to: pt) } else { line.addLine(to: pt) }
            }
            ctx.stroke(line, with: .color(RadioTheme.amber), lineWidth: 3)

            // leading dot
            if count > 0 {
                let li = count - 1
                let r: CGFloat = 5
                ctx.fill(Path(ellipseIn: CGRect(x: x(li)-r, y: y(series[li])-r, width: r*2, height: r*2)),
                         with: .color(RadioTheme.textHi))
            }
        }
        .frame(width: w, height: h)
    }
}
