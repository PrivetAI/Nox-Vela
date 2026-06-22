import SwiftUI

final class RadioGameStore: ObservableObject {
    @Published var state: GameState
    @Published var library: [Track]          // all tracks that exist (starter + bought)
    @Published var slots: [Int?]             // assigned track id per slot (nil = empty)
    @Published var selectedCrateTrack: Int?  // currently picked track in crate strip

    private let saveKey = "night_shift_radio_state_v1"

    init() {
        // Load or seed
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(GameState.self, from: data) {
            self.state = decoded
        } else {
            self.state = GameState()
        }
        self.library = []
        self.slots = Array(repeating: nil, count: NightConstants.slotCount)
        self.selectedCrateTrack = nil
        rebuildLibrary()
        if state.ownedTrackIDs.isEmpty {
            // First launch: own all starter tracks
            state.ownedTrackIDs = RadioGameStore.starterLibrary.map { $0.id }
            persist()
        }
    }

    // MARK: - Starter library (10 tracks)

    static let starterLibrary: [Track] = [
        Track(id: 1,  title: "Velvet Hours",      genre: .jazz,    energy: 3),
        Track(id: 2,  title: "Smoke & Brass",     genre: .jazz,    energy: 4),
        Track(id: 3,  title: "Midnight Confession",genre: .soul,   energy: 3),
        Track(id: 4,  title: "Slow Burn",         genre: .soul,    energy: 2),
        Track(id: 5,  title: "Tide Pool",         genre: .ambient, energy: 1),
        Track(id: 6,  title: "Static Dawn",       genre: .ambient, energy: 2),
        Track(id: 7,  title: "Neon Rainfall",     genre: .synth,   energy: 4),
        Track(id: 8,  title: "Porch Light",       genre: .folk,    energy: 2),
        Track(id: 9,  title: "Blue Avenue",       genre: .blues,   energy: 3),
        Track(id: 10, title: "Last Call Lounge",  genre: .lounge,  energy: 2)
    ]

    // Shop catalog — tracks that can be bought (id >= 100). Owned via state.ownedTrackIDs.
    static let shopCatalog: [Track] = [
        Track(id: 101, title: "After Hours Sax",  genre: .jazz,    energy: 2),
        Track(id: 102, title: "Uptown Shuffle",   genre: .jazz,    energy: 5),
        Track(id: 103, title: "Heartline",        genre: .soul,    energy: 4),
        Track(id: 104, title: "Golden Echo",      genre: .soul,    energy: 5),
        Track(id: 105, title: "Drift Chamber",    genre: .ambient, energy: 1),
        Track(id: 106, title: "Aurora Hum",       genre: .ambient, energy: 3),
        Track(id: 107, title: "Pulse Theory",     genre: .synth,   energy: 5),
        Track(id: 108, title: "Glass Circuit",    genre: .synth,   energy: 3),
        Track(id: 109, title: "Cedar Road",       genre: .folk,    energy: 3),
        Track(id: 110, title: "River Lantern",    genre: .folk,    energy: 1),
        Track(id: 111, title: "Crossroads Moan",  genre: .blues,   energy: 4),
        Track(id: 112, title: "Delta Whisper",    genre: .blues,   energy: 2),
        Track(id: 113, title: "Brass Lamp",       genre: .lounge,  energy: 3),
        Track(id: 114, title: "Velvet Booth",     genre: .lounge,  energy: 1),
        Track(id: 115, title: "Moonlit Quartet",  genre: .jazz,    energy: 1),
        Track(id: 116, title: "Embers",           genre: .soul,    energy: 1)
    ]

    static let trackPrice = 18
    static let genrePrices: [Genre: Int] = [
        .synth: 40, .folk: 40, .blues: 50, .lounge: 50
    ]

    private func rebuildLibrary() {
        library = RadioGameStore.starterLibrary + RadioGameStore.shopCatalog
    }

    // MARK: - Lookups

    func track(_ id: Int) -> Track? {
        library.first { $0.id == id }
    }

    var ownedTracks: [Track] {
        library.filter { state.ownedTrackIDs.contains($0.id) }
    }

    // Owned tracks whose genre is unlocked (those usable in the crate)
    var crateTracks: [Track] {
        ownedTracks.filter { state.unlockedGenres.contains($0.genre) }
            .sorted { ($0.genre.rawValue, $0.energy) < ($1.genre.rawValue, $1.energy) }
    }

    func isOwned(_ id: Int) -> Bool { state.ownedTrackIDs.contains(id) }
    func isGenreUnlocked(_ g: Genre) -> Bool { state.unlockedGenres.contains(g) }

    // MARK: - Night target (escalates)

    var currentTarget: Int {
        // Night 0 -> 140, then escalate
        180 + state.nightsAired * 35
    }

    // MARK: - Caller requests (deterministic by night number)

    var callerRequests: [CallerRequest] {
        let unlocked = state.unlockedGenres
        guard !unlocked.isEmpty else { return [] }
        var result: [CallerRequest] = []
        for (idx, slot) in NightConstants.callerSlots.enumerated() {
            // deterministic pseudo-random pick based on night number and slot
            let seed = (state.nightsAired &* 7 &+ slot &* 13 &+ idx &* 5)
            let g = unlocked[abs(seed) % unlocked.count]
            result.append(CallerRequest(slot: slot, genre: g))
        }
        return result
    }

    func callerAt(slot: Int) -> CallerRequest? {
        callerRequests.first { $0.slot == slot }
    }

    // MARK: - Booth interactions

    func assign(slot: Int) {
        guard let picked = selectedCrateTrack else { return }
        slots[slot] = picked
    }

    func clear(slot: Int) {
        slots[slot] = nil
    }

    func clearAll() {
        slots = Array(repeating: nil, count: NightConstants.slotCount)
    }

    func autoFill() {
        // Simple helper: fill empty slots with a sensible owned track near target energy.
        let owned = crateTracks
        guard !owned.isEmpty else { return }
        for i in 0..<slots.count where slots[i] == nil {
            let target = NightConstants.targetEnergy(i)
            let best = owned.min { a, b in
                abs(Double(a.energy) - target) < abs(Double(b.energy) - target)
            }
            slots[i] = best?.id
        }
    }

    // Predicted energy series for the planning curve (nil entries skipped/0)
    func plannedEnergy(_ i: Int) -> Double? {
        guard let id = slots[i], let t = track(id) else { return nil }
        return Double(t.energy)
    }

    var allSlotsFilled: Bool { slots.allSatisfy { $0 != nil } }

    // MARK: - Scoring engine (deterministic)

    func evaluate() -> BroadcastResult {
        var listeners = NightConstants.baseListeners
        var series: [Int] = [listeners]
        var transitions: [TransitionDetail] = []
        var slotDetails: [SlotDetail] = []
        var peak = listeners

        for i in 0..<NightConstants.slotCount {
            let id = slots[i]
            let t = id.flatMap { track($0) }

            // Dead air
            let deadAir = (t == nil)
            if deadAir {
                listeners -= 25
            }

            // Target energy match for this slot
            var targetDelta = 0
            if let t = t {
                let diff = abs(Double(t.energy) - NightConstants.targetEnergy(i))
                if diff < 0.75 { targetDelta = 8 }
                else if diff < 1.5 { targetDelta = 3 }
                else if diff < 2.5 { targetDelta = -4 }
                else { targetDelta = -9 }
                listeners += targetDelta
            }

            // Caller event
            var callerDelta: Int? = nil
            var callerMatched: Bool? = nil
            if let caller = callerAt(slot: i) {
                if let t = t, t.genre == caller.genre {
                    callerDelta = 30
                    callerMatched = true
                } else {
                    callerDelta = -12
                    callerMatched = false
                }
                listeners += callerDelta!
            }

            slotDetails.append(SlotDetail(id: i, targetDelta: targetDelta, deadAir: deadAir,
                                          callerDelta: callerDelta, callerMatched: callerMatched))

            // Transition from previous slot
            if i > 0 {
                let prevT = slots[i-1].flatMap { track($0) }
                var affDelta = 0
                var enDelta = 0
                var note = ""
                if let a = prevT, let b = t {
                    // Same-track-adjacent penalty
                    if a.id == b.id {
                        affDelta = -10
                        note = "Repeat"
                    } else {
                        let aff = Affinity.value(a.genre, b.genre)
                        affDelta = aff * 6
                        // Energy flow
                        let d = abs(a.energy - b.energy)
                        if d <= 1 { enDelta = 6 }
                        else if d == 2 { enDelta = -3 }
                        else { enDelta = -8 }
                        if aff >= 2 { note = "Great blend" }
                        else if aff >= 1 { note = "Smooth" }
                        else if aff == 0 { note = "Neutral" }
                        else { note = "Clash" }
                    }
                } else {
                    note = "Dead air"
                }
                listeners += affDelta + enDelta
                transitions.append(TransitionDetail(id: i, fromSlot: i-1, toSlot: i,
                                                    affinityDelta: affDelta, energyFlowDelta: enDelta, note: note))
            }

            if listeners < 0 { listeners = 0 }
            if listeners > peak { peak = listeners }
            series.append(listeners)
        }

        let target = currentTarget
        let beat = peak >= target
        // Records: scale peak listeners; bonus for beating target
        let baseRecords = max(1, peak / 12)
        let bonus = beat ? 20 + state.nightsAired * 3 : 0

        return BroadcastResult(
            startListeners: NightConstants.baseListeners,
            finalListeners: listeners,
            peakListeners: peak,
            listenerSeries: series,
            transitions: transitions,
            slots: slotDetails,
            recordsEarned: baseRecords + bonus,
            target: target,
            beatTarget: beat,
            bonusRecords: bonus
        )
    }

    // Commit a broadcast result to persistent progress
    func commit(_ result: BroadcastResult) {
        state.records += result.recordsEarned
        state.nightsAired += 1
        state.totalListeners += result.peakListeners
        if result.peakListeners > state.bestNight {
            state.bestNight = result.peakListeners
        }
        persist()
    }

    // MARK: - Shop

    @discardableResult
    func buyTrack(_ id: Int) -> Bool {
        guard !isOwned(id), state.records >= RadioGameStore.trackPrice else { return false }
        state.records -= RadioGameStore.trackPrice
        state.ownedTrackIDs.append(id)
        persist()
        return true
    }

    @discardableResult
    func unlockGenre(_ g: Genre) -> Bool {
        guard !isGenreUnlocked(g), let price = RadioGameStore.genrePrices[g],
              state.records >= price else { return false }
        state.records -= price
        state.unlockedGenres.append(g)
        persist()
        return true
    }

    // MARK: - Reset

    func resetProgress() {
        state = GameState()
        state.ownedTrackIDs = RadioGameStore.starterLibrary.map { $0.id }
        slots = Array(repeating: nil, count: NightConstants.slotCount)
        selectedCrateTrack = nil
        persist()
    }

    // MARK: - Persistence

    func persist() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
}
