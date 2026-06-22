import SwiftUI

struct BroadcastResultOverlay: View {
    let result: BroadcastResult
    @ObservedObject var store: RadioGameStore
    var screenSize: CGSize
    var onNext: () -> Void

    @State private var reveal: CGFloat = 0
    @State private var showBreakdown = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()
                .onTapGesture { } // block taps to background

            ScrollView {
                VStack(spacing: 18) {
                    // Title
                    VStack(spacing: 4) {
                        Text(result.beatTarget ? "HIT THE TARGET" : "OFF AIR")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundColor(result.beatTarget ? RadioTheme.good : RadioTheme.amber)
                        Text(result.beatTarget ? "The night's audience tuned in." : "A quieter night on the dial.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(RadioTheme.textDim)
                    }
                    .padding(.top, 20)

                    // Listener curve
                    VStack(spacing: 10) {
                        HStack {
                            statBig("Peak", "\(result.peakListeners)")
                            Spacer()
                            statBig("Final", "\(result.finalListeners)")
                            Spacer()
                            statBig("Target", "\(result.target)")
                        }
                        ListenerCurveGraph(series: result.listenerSeries, target: result.target,
                                           progress: reveal, screenSize: screenSize)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(16)
                    .radioCard(raised: true)

                    // Records earned
                    HStack(spacing: 10) {
                        RecordPip(size: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("+\(result.recordsEarned) Records")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundColor(RadioTheme.amber)
                            if result.bonusRecords > 0 {
                                Text("includes +\(result.bonusRecords) target bonus")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(RadioTheme.good)
                            }
                        }
                        Spacer()
                    }
                    .padding(16)
                    .radioCard()

                    // Breakdown toggle
                    Button(action: { withAnimation { showBreakdown.toggle() } }) {
                        HStack {
                            Text(showBreakdown ? "Hide breakdown" : "Show transition breakdown")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(RadioTheme.neon)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if showBreakdown {
                        breakdown
                    }

                    // Next
                    Button(action: onNext) {
                        HStack {
                            Spacer()
                            Text("NEXT NIGHT")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .tracking(2)
                                .foregroundColor(RadioTheme.bgDeep)
                            Spacer()
                        }
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 14)
                            .fill(LinearGradient(colors: [RadioTheme.amber, RadioTheme.amberDeep],
                                                 startPoint: .leading, endPoint: .trailing)))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.3)) { reveal = 1 }
        }
    }

    private func statBig(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(RadioTheme.textHi)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundColor(RadioTheme.textDim)
        }
    }

    private var breakdown: some View {
        VStack(spacing: 8) {
            // Slot-level (dead air, caller, target)
            ForEach(result.slots) { s in
                if s.deadAir || s.callerDelta != nil || s.targetDelta != 0 {
                    HStack(spacing: 8) {
                        Text(NightConstants.slotLabel(s.id))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(RadioTheme.amber.opacity(0.9))
                            .frame(width: 64, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            if s.deadAir {
                                deltaRow("Dead air", -25)
                            }
                            if s.targetDelta != 0 {
                                deltaRow(s.targetDelta > 0 ? "Good mood fit" : "Off the mood curve", s.targetDelta)
                            }
                            if let cd = s.callerDelta {
                                deltaRow(s.callerMatched == true ? "Caller request matched" : "Caller request missed", cd)
                            }
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(RadioTheme.card))
                }
            }
            // Transitions
            ForEach(result.transitions) { t in
                let total = t.affinityDelta + t.energyFlowDelta
                HStack(spacing: 8) {
                    Text("\(NightConstants.slotLabel(t.fromSlot).prefix(5))→")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(RadioTheme.textDim)
                        .frame(width: 64, alignment: .leading)
                    Text(t.note)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(RadioTheme.textMid)
                    Spacer()
                    Text(signed(total))
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(total >= 0 ? RadioTheme.good : RadioTheme.bad)
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(RadioTheme.card.opacity(0.7)))
            }
        }
    }

    private func deltaRow(_ label: String, _ v: Int) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(RadioTheme.textMid)
            Spacer()
            Text(signed(v))
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(v >= 0 ? RadioTheme.good : RadioTheme.bad)
        }
    }

    private func signed(_ v: Int) -> String { v >= 0 ? "+\(v)" : "\(v)" }
}
