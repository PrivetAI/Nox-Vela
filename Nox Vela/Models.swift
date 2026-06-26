import SwiftUI

// MARK: - Genre

enum Genre: String, Codable, CaseIterable, Identifiable {
    case jazz = "Jazz"
    case soul = "Soul"
    case ambient = "Ambient"
    case synth = "Synth"
    case folk = "Folk"
    case blues = "Blues"
    case lounge = "Lounge"

    var id: String { rawValue }

    // Genres unlocked from the very start
    static let starters: [Genre] = [.jazz, .soul, .ambient]
}

// MARK: - Track

struct Track: Codable, Identifiable, Equatable {
    var id: Int
    var title: String
    var genre: Genre
    var energy: Int   // 1...5

    static func == (a: Track, b: Track) -> Bool { a.id == b.id }
}

// MARK: - Genre affinity matrix (symmetric, -2 ... +2)
// Positive = blends well, negative = clash.

enum Affinity {
    // Returns a symmetric affinity value between two genres.
    static func value(_ a: Genre, _ b: Genre) -> Int {
        if a == b { return 1 } // same genre is a gentle, safe blend
        let key = pair(a, b)
        return table[key] ?? 0
    }

    private static func pair(_ a: Genre, _ b: Genre) -> String {
        let s = [a.rawValue, b.rawValue].sorted()
        return s[0] + "|" + s[1]
    }

    // Define one direction; pair() normalizes order.
    private static let table: [String: Int] = {
        var t: [String: Int] = [:]
        func set(_ a: Genre, _ b: Genre, _ v: Int) {
            let s = [a.rawValue, b.rawValue].sorted()
            t[s[0] + "|" + s[1]] = v
        }
        // Warm acoustic family: Jazz / Blues / Soul / Folk
        set(.jazz, .blues, 2)
        set(.blues, .soul, 2)
        set(.jazz, .soul, 2)
        set(.blues, .folk, 1)
        set(.folk, .soul, 1)
        set(.jazz, .folk, 1)
        // Electronic / mellow family: Synth / Ambient / Lounge
        set(.synth, .ambient, 2)
        set(.ambient, .lounge, 2)
        set(.synth, .lounge, 1)
        // Bridges
        set(.jazz, .lounge, 1)
        set(.soul, .lounge, 1)
        set(.ambient, .folk, 1)
        // Clashes across families
        set(.synth, .blues, -2)
        set(.synth, .jazz, -1)
        set(.synth, .folk, -2)
        set(.synth, .soul, -1)
        set(.ambient, .blues, -1)
        set(.ambient, .jazz, -1)
        set(.ambient, .soul, -1)
        set(.lounge, .blues, -1)
        set(.lounge, .folk, -1)
        return t
    }()
}

// MARK: - Night structure

enum NightConstants {
    static let slotCount = 12
    static let baseListeners = 100
    static let callerSlots = [3, 6, 9] // 0-indexed slot indices with caller events

    // Slot time labels: Midnight (slot 0) -> 6 AM (slot 11), 30-min steps.
    static func slotLabel(_ i: Int) -> String {
        // 12 slots across 6 hours => 30 min each, starting at 00:00
        let totalMinutes = i * 30
        let hour = totalMinutes / 60
        let minute = totalMinutes % 60
        let mm = minute == 0 ? "00" : "30"
        let hh = hour
        let display: String
        if hh == 0 { display = "12:\(mm) AM" }
        else { display = "\(hh):\(mm) AM" }
        return display
    }

    // Target energy curve: descends across the night (high early, mellow late).
    // Returns a value in 1...5 (as Double) for each slot.
    static func targetEnergy(_ i: Int) -> Double {
        let t = Double(i) / Double(slotCount - 1) // 0...1
        // Start ~4.6, end ~1.4
        return 4.6 - 3.2 * t
    }
}

// MARK: - Caller request (generated deterministically per night number)

struct CallerRequest: Codable, Identifiable {
    var slot: Int
    var genre: Genre
    var id: Int { slot }
}

// MARK: - Transition scoring detail (for the result overlay)

struct TransitionDetail: Identifiable {
    var id: Int            // index of the transition (from slot id-1 to id)
    var fromSlot: Int
    var toSlot: Int
    var affinityDelta: Int
    var energyFlowDelta: Int
    var note: String
}

struct SlotDetail: Identifiable {
    var id: Int            // slot index
    var targetDelta: Int   // gain/loss vs target energy curve
    var deadAir: Bool
    var callerDelta: Int?  // nil if no caller at this slot
    var callerMatched: Bool?
}

struct BroadcastResult {
    var startListeners: Int
    var finalListeners: Int
    var peakListeners: Int
    var listenerSeries: [Int]      // cumulative listener count after each slot (length slotCount+1)
    var transitions: [TransitionDetail]
    var slots: [SlotDetail]
    var recordsEarned: Int
    var target: Int
    var beatTarget: Bool
    var bonusRecords: Int
}

// MARK: - Persistent progress

struct GameState: Codable {
    var records: Int = 30
    var nightsAired: Int = 0
    var bestNight: Int = 0
    var totalListeners: Int = 0
    var ownedTrackIDs: [Int] = []
    var unlockedGenres: [Genre] = Genre.starters
    var nextTrackID: Int = 1000
    var customTrackTitles: [Int: String] = [:] // for shop-bought tracks
}
