import SwiftUI

struct RadioLoadingScreen: View {
    @State private var pulse = false
    @State private var wavePhase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size
            ZStack {
                RadioTheme.bg.ignoresSafeArea()
                RadialGradient(
                    gradient: Gradient(colors: [RadioTheme.amber.opacity(0.18), .clear]),
                    center: .center, startRadius: 10, endRadius: max(screenSize.width, screenSize.height) * 0.7
                ).ignoresSafeArea()

                VStack(spacing: 28) {
                    // Glowing on-air dial icon
                    OnAirIcon(size: min(screenSize.width * 0.34, 150))
                        .scaleEffect(pulse ? 1.05 : 0.95)
                        .shadow(color: RadioTheme.amber.opacity(0.5), radius: 24)

                    Text("NOX VELA")
                        .font(.system(size: min(screenSize.width * 0.066, 28), weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundColor(RadioTheme.textHi)

                    Text("Tuning the late-night airwaves...")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(RadioTheme.textDim)

                    // Animated equalizer bars
                    Canvas { ctx, size in
                        let bars = 9
                        let gap: CGFloat = 6
                        let bw = (size.width - gap * CGFloat(bars - 1)) / CGFloat(bars)
                        for i in 0..<bars {
                            let p = (sin(Double(wavePhase) + Double(i) * 0.7) + 1) / 2
                            let h = CGFloat(0.25 + p * 0.75) * size.height
                            let x = CGFloat(i) * (bw + gap)
                            let rect = CGRect(x: x, y: size.height - h, width: bw, height: h)
                            ctx.fill(Path(roundedRect: rect, cornerRadius: bw / 2),
                                     with: .color(RadioTheme.amber.opacity(0.85)))
                        }
                    }
                    .frame(width: min(screenSize.width * 0.5, 220), height: 40)
                }
                .frame(width: screenSize.width)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                wavePhase += 0.22
            }
        }
    }
}

// Reusable "on-air" glowing dial icon drawn from shapes/canvas.
struct OnAirIcon: View {
    var size: CGFloat
    var color: Color = RadioTheme.amber

    var body: some View {
        Canvas { ctx, csize in
            let c = CGPoint(x: csize.width / 2, y: csize.height / 2)
            let r = min(csize.width, csize.height) / 2

            // Outer ring
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r * 0.92, y: c.y - r * 0.92,
                                              width: r * 1.84, height: r * 1.84)),
                       with: .color(color.opacity(0.85)), lineWidth: r * 0.10)

            // Arc ticks around the dial
            let ticks = 12
            for i in 0..<ticks {
                let a = Double(i) / Double(ticks) * 2 * .pi
                let inner = r * 0.66
                let outer = r * 0.80
                let p1 = CGPoint(x: c.x + CGFloat(cos(a)) * inner, y: c.y + CGFloat(sin(a)) * inner)
                let p2 = CGPoint(x: c.x + CGFloat(cos(a)) * outer, y: c.y + CGFloat(sin(a)) * outer)
                var p = Path(); p.move(to: p1); p.addLine(to: p2)
                ctx.stroke(p, with: .color(color.opacity(0.5)), lineWidth: r * 0.04)
            }

            // Pointer needle
            let needleAngle = -0.7
            let np = CGPoint(x: c.x + CGFloat(cos(needleAngle)) * r * 0.58,
                             y: c.y + CGFloat(sin(needleAngle)) * r * 0.58)
            var needle = Path(); needle.move(to: c); needle.addLine(to: np)
            ctx.stroke(needle, with: .color(RadioTheme.neonPink), lineWidth: r * 0.07)

            // Center hub
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.14, y: c.y - r * 0.14,
                                            width: r * 0.28, height: r * 0.28)),
                     with: .color(color))
        }
        .frame(width: size, height: size)
    }
}
