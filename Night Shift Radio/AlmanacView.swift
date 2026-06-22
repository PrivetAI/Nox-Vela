import SwiftUI

struct AlmanacView: View {
    @ObservedObject var store: RadioGameStore

    var body: some View {
        ZStack {
            RadioTheme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    bigStat
                    statGrid
                    genreProgress
                    affinityCard
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("ALMANAC")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundColor(RadioTheme.textHi)
            }
        }
    }

    private var bigStat: some View {
        VStack(spacing: 6) {
            Text("BEST NIGHT")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(2).foregroundColor(RadioTheme.textDim)
            Text("\(store.state.bestNight)")
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundColor(RadioTheme.amber)
            Text("peak listeners")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(RadioTheme.textMid)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .radioCard(raised: true)
    }

    private var statGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                statCell("Nights Aired", "\(store.state.nightsAired)")
                statCell("Total Listeners", "\(store.state.totalListeners)")
            }
            HStack(spacing: 10) {
                statCell("Tracks Owned", "\(store.ownedTracks.count)")
                statCell("Genres Unlocked", "\(store.state.unlockedGenres.count)/\(Genre.allCases.count)")
            }
        }
    }

    private func statCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(RadioTheme.textHi)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.8).foregroundColor(RadioTheme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .radioCard()
    }

    private var genreProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GENRES")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5).foregroundColor(RadioTheme.textDim)
            ForEach(Genre.allCases) { g in
                let unlocked = store.isGenreUnlocked(g)
                let count = store.ownedTracks.filter { $0.genre == g }.count
                HStack {
                    Circle().fill(unlocked ? RadioTheme.genreColor(g) : RadioTheme.stroke)
                        .frame(width: 10, height: 10)
                    Text(g.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(unlocked ? RadioTheme.textHi : RadioTheme.textDim)
                    Spacer()
                    Text(unlocked ? "\(count) tracks" : "locked")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(RadioTheme.textMid)
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 10).fill(RadioTheme.card))
            }
        }
        .padding(14)
        .radioCard()
    }

    private var affinityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MIXING TIPS")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5).foregroundColor(RadioTheme.textDim)
            tip("Jazz, Blues & Soul blend warmly together.")
            tip("Synth, Ambient & Lounge keep the late hours smooth.")
            tip("Keep energy changes small between songs.")
            tip("Open high-energy, then mellow toward dawn.")
            tip("Match caller requests for a big listener boost.")
        }
        .padding(14)
        .radioCard()
    }

    private func tip(_ s: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(RadioTheme.amber).frame(width: 6, height: 6).padding(.top, 5)
            Text(s)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(RadioTheme.textMid)
            Spacer()
        }
    }
}
