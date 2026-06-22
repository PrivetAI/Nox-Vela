import SwiftUI

struct BoothView: View {
    @ObservedObject var store: RadioGameStore
    @State private var result: BroadcastResult? = nil
    @State private var showResult = false

    var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size
            ZStack {
                RadioTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerBar
                        curveCard(screenSize)
                        callerCard
                        slotList
                        broadcastButton
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                // Result overlay (NOT a nested NavigationLink — per pitfall)
                if showResult, let r = result {
                    BroadcastResultOverlay(result: r, store: store, screenSize: screenSize) {
                        // Next night
                        store.commit(r)
                        store.clearAll()
                        store.selectedCrateTrack = nil
                        withAnimation { showResult = false }
                        result = nil
                    }
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("THE BOOTH")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundColor(RadioTheme.textHi)
                }
            }
        }
    }

    // MARK: - Header (records + target + crate strip)

    private var headerBar: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    RecordPip(size: 18)
                    Text("\(store.state.records)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(RadioTheme.textHi)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Night \(store.state.nightsAired + 1)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(RadioTheme.amber)
                    Text("Target \(store.currentTarget) listeners")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(RadioTheme.textDim)
                }
            }
            crateStrip
        }
        .padding(14)
        .radioCard()
    }

    private var crateStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("CRATE")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(RadioTheme.textDim)
                Spacer()
                Button(action: { store.autoFill() }) {
                    Text("Auto-fill")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(RadioTheme.neon)
                }
                Button(action: { store.clearAll() }) {
                    Text("Clear")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(RadioTheme.bad.opacity(0.9))
                }
                .padding(.leading, 10)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.crateTracks) { t in
                        crateChip(t)
                    }
                    if store.crateTracks.isEmpty {
                        Text("No tracks unlocked.")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(RadioTheme.textDim)
                            .padding(.vertical, 14)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func crateChip(_ t: Track) -> some View {
        let selected = store.selectedCrateTrack == t.id
        return Button(action: {
            store.selectedCrateTrack = (selected ? nil : t.id)
        }) {
            VStack(alignment: .leading, spacing: 5) {
                Text(t.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(RadioTheme.textHi)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    GenreTag(genre: t.genre)
                    EnergyDots(energy: t.energy, color: RadioTheme.genreColor(t.genre))
                }
            }
            .padding(10)
            .frame(width: 150, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? RadioTheme.genreColor(t.genre).opacity(0.22) : RadioTheme.cardHi)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? RadioTheme.genreColor(t.genre) : RadioTheme.stroke.opacity(0.5),
                            lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Curve card

    private func curveCard(_ screenSize: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                legendDot(RadioTheme.neon, "Your set")
                legendDot(RadioTheme.amber, "Target mood")
            }
            EnergyCurveGraph(planned: (0..<NightConstants.slotCount).map { store.plannedEnergy($0) },
                             screenSize: screenSize)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(14)
        .radioCard()
    }

    private func legendDot(_ c: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(c).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(RadioTheme.textMid)
        }
    }

    // MARK: - Caller card

    private var callerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CALLER REQUESTS")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundColor(RadioTheme.textDim)
            HStack(spacing: 8) {
                ForEach(store.callerRequests) { req in
                    let filled = store.slots[req.slot].flatMap { store.track($0) }
                    let matched = filled?.genre == req.genre
                    HStack(spacing: 6) {
                        Text(NightConstants.slotLabel(req.slot))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(RadioTheme.textDim)
                        GenreTag(genre: req.genre)
                        if filled != nil {
                            Circle()
                                .fill(matched ? RadioTheme.good : RadioTheme.bad)
                                .frame(width: 7, height: 7)
                        }
                    }
                    .padding(.horizontal, 9).padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 9).fill(RadioTheme.cardHi))
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .radioCard()
    }

    // MARK: - Slot list

    private var slotList: some View {
        VStack(spacing: 8) {
            ForEach(0..<NightConstants.slotCount, id: \.self) { i in
                SlotRow(
                    index: i,
                    track: store.slots[i].flatMap { store.track($0) },
                    caller: store.callerAt(slot: i),
                    hasSelection: store.selectedCrateTrack != nil,
                    onTap: { handleSlotTap(i) }
                )
            }
        }
    }

    private func handleSlotTap(_ i: Int) {
        if store.slots[i] != nil {
            // tapping a filled slot clears it (or replaces if a track is picked)
            if store.selectedCrateTrack != nil {
                store.assign(slot: i)
            } else {
                store.clear(slot: i)
            }
        } else {
            store.assign(slot: i)
        }
    }

    // MARK: - Broadcast

    private var broadcastButton: some View {
        Button(action: broadcast) {
            HStack {
                Spacer()
                Text("GO ON AIR")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundColor(RadioTheme.bgDeep)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [RadioTheme.amber, RadioTheme.amberDeep],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: RadioTheme.amber.opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func broadcast() {
        let r = store.evaluate()
        result = r
        withAnimation(.easeInOut(duration: 0.35)) { showResult = true }
    }
}

// MARK: - Slot row

struct SlotRow: View {
    var index: Int
    var track: Track?
    var caller: CallerRequest?
    var hasSelection: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // time label
                VStack(spacing: 2) {
                    Text(NightConstants.slotLabel(index))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(RadioTheme.amber.opacity(0.9))
                    if caller != nil {
                        Circle().fill(RadioTheme.neonPink).frame(width: 5, height: 5)
                    }
                }
                .frame(width: 62)

                // content
                if let t = track {
                    Rectangle()
                        .fill(RadioTheme.genreColor(t.genre))
                        .frame(width: 4)
                        .cornerRadius(2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(t.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(RadioTheme.textHi)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            GenreTag(genre: t.genre)
                            EnergyDots(energy: t.energy, color: RadioTheme.genreColor(t.genre))
                        }
                    }
                    Spacer()
                } else {
                    Rectangle().fill(RadioTheme.stroke.opacity(0.4)).frame(width: 4).cornerRadius(2)
                    Text(hasSelection ? "Tap to place track" : "— empty (dead air) —")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(hasSelection ? RadioTheme.neon.opacity(0.9) : RadioTheme.textDim)
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(track == nil ? RadioTheme.card.opacity(0.6) : RadioTheme.cardHi)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(caller != nil ? RadioTheme.neonPink.opacity(0.5) : RadioTheme.stroke.opacity(0.4),
                            lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Genre tag

struct GenreTag: View {
    var genre: Genre
    var body: some View {
        Text(genre.rawValue.uppercased())
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(0.5)
            .foregroundColor(RadioTheme.genreColor(genre))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 5).fill(RadioTheme.genreColor(genre).opacity(0.18)))
    }
}
