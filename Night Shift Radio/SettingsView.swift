import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: RadioGameStore
    @State private var showPrivacy = false
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            RadioTheme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    howToCard
                    privacyCard
                    resetCard
                    aboutCard
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("SETTINGS")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundColor(RadioTheme.textHi)
            }
        }
        .sheet(isPresented: $showPrivacy) {
            RadioWebPanel(urlString: "https://example.com")
        }
        .alert(isPresented: $showResetConfirm) {
            Alert(
                title: Text("Reset Progress?"),
                message: Text("This erases your records, nights aired, and bought tracks. This cannot be undone."),
                primaryButton: .destructive(Text("Reset")) { store.resetProgress() },
                secondaryButton: .cancel()
            )
        }
    }

    private var howToCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOW TO PLAY")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5).foregroundColor(RadioTheme.textDim)
            Text("You host the late-night shift. Plan a 12-slot playlist from midnight to dawn: pick a track from your crate, then tap a time slot to place it. Tap a filled slot to clear it.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(RadioTheme.textMid)
            Text("When you go on air, your set is scored: related genres and gentle energy changes win listeners, clashes and dead air lose them. Follow the descending mood curve and answer caller requests for bonuses. Spend the Records you earn on new tracks and genres.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(RadioTheme.textMid)
        }
        .padding(14)
        .radioCard()
    }

    private var privacyCard: some View {
        Button(action: { showPrivacy = true }) {
            HStack {
                Text("Privacy Policy")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(RadioTheme.textHi)
                Spacer()
                ChevronIcon(size: 16, color: RadioTheme.textDim)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .radioCard()
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var resetCard: some View {
        Button(action: { showResetConfirm = true }) {
            HStack {
                Text("Reset Progress")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(RadioTheme.bad)
                Spacer()
                ChevronIcon(size: 16, color: RadioTheme.bad.opacity(0.7))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .radioCard()
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var aboutCard: some View {
        VStack(spacing: 6) {
            OnAirIcon(size: 54)
            Text("Night Shift Radio")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(RadioTheme.textHi)
            Text("Version 1.0")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(RadioTheme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .radioCard()
    }
}

struct ChevronIcon: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, s in
            var p = Path()
            p.move(to: CGPoint(x: s.width*0.35, y: s.height*0.2))
            p.addLine(to: CGPoint(x: s.width*0.65, y: s.height*0.5))
            p.addLine(to: CGPoint(x: s.width*0.35, y: s.height*0.8))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: s.width*0.12, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}
