import SwiftUI

struct CrateView: View {
    @ObservedObject var store: RadioGameStore
    @State private var mode = 0 // 0 = shop, 1 = library

    var body: some View {
        ZStack {
            RadioTheme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    recordsHeader
                    segmented
                    if mode == 0 {
                        genreUnlockSection
                        trackShopSection
                    } else {
                        librarySection
                    }
                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("THE CRATE")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundColor(RadioTheme.textHi)
            }
        }
    }

    private var recordsHeader: some View {
        HStack {
            HStack(spacing: 8) {
                RecordPip(size: 22)
                Text("\(store.state.records) Records")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(RadioTheme.textHi)
            }
            Spacer()
        }
        .padding(14)
        .radioCard()
    }

    private var segmented: some View {
        HStack(spacing: 0) {
            segButton("Shop", 0)
            segButton("Library", 1)
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 12).fill(RadioTheme.bgDeep))
    }

    private func segButton(_ label: String, _ idx: Int) -> some View {
        Button(action: { mode = idx }) {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(mode == idx ? RadioTheme.bgDeep : RadioTheme.textMid)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 9)
                    .fill(mode == idx ? RadioTheme.amber : Color.clear))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Genre unlocks

    private var genreUnlockSection: some View {
        let locked = Genre.allCases.filter { !store.isGenreUnlocked($0) }
        return Group {
            if !locked.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("UNLOCK GENRES")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.5).foregroundColor(RadioTheme.textDim)
                    ForEach(locked) { g in
                        let price = RadioGameStore.genrePrices[g] ?? 0
                        HStack {
                            GenreTag(genre: g)
                            Text("Adds \(g.rawValue) tracks to your crate")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(RadioTheme.textMid)
                            Spacer()
                            buyButton(price: price, enabled: store.state.records >= price) {
                                store.unlockGenre(g)
                            }
                        }
                        .padding(12)
                        .radioCard()
                    }
                }
            }
        }
    }

    // MARK: - Track shop

    private var trackShopSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BUY TRACKS")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5).foregroundColor(RadioTheme.textDim)
            ForEach(RadioGameStore.shopCatalog) { t in
                let owned = store.isOwned(t.id)
                let genreLocked = !store.isGenreUnlocked(t.genre)
                HStack(spacing: 10) {
                    Rectangle().fill(RadioTheme.genreColor(t.genre)).frame(width: 4).cornerRadius(2)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(t.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(RadioTheme.textHi)
                        HStack(spacing: 8) {
                            GenreTag(genre: t.genre)
                            EnergyDots(energy: t.energy, color: RadioTheme.genreColor(t.genre))
                        }
                    }
                    Spacer()
                    if owned {
                        Text("OWNED")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(RadioTheme.good)
                    } else if genreLocked {
                        Text("LOCKED")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(RadioTheme.textDim)
                    } else {
                        buyButton(price: RadioGameStore.trackPrice,
                                  enabled: store.state.records >= RadioGameStore.trackPrice) {
                            store.buyTrack(t.id)
                        }
                    }
                }
                .padding(12)
                .radioCard()
            }
        }
    }

    // MARK: - Library

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Genre.allCases) { g in
                let tracks = store.ownedTracks.filter { $0.genre == g }
                if !tracks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            GenreTag(genre: g)
                            if !store.isGenreUnlocked(g) {
                                Text("locked")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(RadioTheme.textDim)
                            }
                            Spacer()
                            Text("\(tracks.count)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(RadioTheme.textDim)
                        }
                        ForEach(tracks) { t in
                            HStack {
                                Text(t.title)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(RadioTheme.textHi)
                                Spacer()
                                EnergyDots(energy: t.energy, color: RadioTheme.genreColor(g))
                            }
                            .padding(.horizontal, 12).padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 10).fill(RadioTheme.card))
                        }
                    }
                }
            }
        }
    }

    private func buyButton(price: Int, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { if enabled { action() } }) {
            HStack(spacing: 5) {
                RecordPip(size: 13)
                Text("\(price)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(enabled ? RadioTheme.bgDeep : RadioTheme.textDim)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(enabled ? RadioTheme.amber : RadioTheme.cardHi))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!enabled)
    }
}
