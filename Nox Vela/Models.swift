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

// MARK: - Station progression (between-night content)

// A named rank the station climbs as more nights are aired.
struct StationTier: Identifiable {
    var level: Int
    var name: String
    var blurb: String
    var minNights: Int
    var id: Int { level }
}

enum StationLadder {
    static let tiers: [StationTier] = [
        StationTier(level: 0, name: "Pirate Signal",       blurb: "Broadcasting from a back room.",        minNights: 0),
        StationTier(level: 1, name: "Graveyard Shift",     blurb: "A handful of night owls found you.",     minNights: 2),
        StationTier(level: 2, name: "Late Night Local",    blurb: "The neighbourhood tunes in.",            minNights: 4),
        StationTier(level: 3, name: "City Favorite",       blurb: "Cab radios across town stay on your dial.", minNights: 7),
        StationTier(level: 4, name: "Regional Voice",      blurb: "Your overnight feed carries for miles.", minNights: 11),
        StationTier(level: 5, name: "Syndicated",          blurb: "Other stations relay your show.",        minNights: 16),
        StationTier(level: 6, name: "Legendary Frequency", blurb: "A voice the whole coast falls asleep to.", minNights: 22),
    ]

    static func tier(forNights n: Int) -> StationTier {
        tiers.last { n >= $0.minNights } ?? tiers[0]
    }

    static func next(forNights n: Int) -> StationTier? {
        tiers.first { $0.minNights > n }
    }
}

// What a milestone hands you when you reach it.
enum MilestoneReward {
    case records(Int)
    case track(Int)              // gift a track (and unlock its genre if needed)
    case genreTrack(Genre, Int)  // unlock a genre + gift one of its tracks
}

// A scripted unlock that fires once when nightsAired reaches `night`.
struct Milestone {
    var night: Int
    var title: String
    var blurb: String
    var reward: MilestoneReward
}

enum MilestoneCatalog {
    static let all: [Milestone] = [
        Milestone(night: 1,  title: "Word Gets Around", blurb: "Your first night on the dial earns a little buzz.",  reward: .records(15)),
        Milestone(night: 2,  title: "Synth After Dark", blurb: "A caller leaves a reel of synth cuts at the door.",  reward: .genreTrack(.synth, 107)),
        Milestone(night: 3,  title: "Loyal Listeners",  blurb: "Regulars start tuning in on schedule.",              reward: .records(25)),
        Milestone(night: 4,  title: "Campfire Hour",    blurb: "A folk singer mails you a demo tape.",               reward: .genreTrack(.folk, 109)),
        Milestone(night: 5,  title: "The Demo Pile",    blurb: "You dig a soul gem out of the mail pile.",           reward: .track(116)),
        Milestone(night: 6,  title: "Blue Midnight",    blurb: "An old bluesman shares his record with you.",        reward: .genreTrack(.blues, 111)),
        Milestone(night: 8,  title: "Velvet Lounge",    blurb: "A lounge act books a midnight guest spot.",          reward: .genreTrack(.lounge, 113)),
        Milestone(night: 10, title: "Cult Following",   blurb: "Word of your night show spreads across town.",       reward: .records(60)),
        Milestone(night: 13, title: "Tastemaker",       blurb: "A label sends an exclusive soul pressing.",          reward: .track(104)),
        Milestone(night: 16, title: "Going Syndicated", blurb: "Other stations want your overnight feed.",           reward: .records(120)),
        Milestone(night: 20, title: "Night Owl Nation", blurb: "Your signal reaches the whole coast.",               reward: .track(102)),
    ]
}

// A resolved reward shown on the post-broadcast screen.
struct MilestoneAward: Identifiable {
    var id: Int        // night
    var title: String
    var blurb: String
    var detail: String // e.g. "Unlocked Synth + Pulse Theory"
}

// Everything that advanced this night, for the result overlay.
struct NightAdvance {
    var tieredUp: StationTier?       // non-nil when a new tier was reached
    var milestones: [MilestoneAward] // newly claimed milestones this night
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
    var claimedMilestones: [Int] = []          // nights whose milestone reward was granted

    init() {}

    // Decode-safe: missing keys fall back to defaults so adding fields never wipes a save.
    enum CodingKeys: String, CodingKey {
        case records, nightsAired, bestNight, totalListeners
        case ownedTrackIDs, unlockedGenres, nextTrackID, customTrackTitles, claimedMilestones
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        records          = try c.decodeIfPresent(Int.self, forKey: .records) ?? 30
        nightsAired      = try c.decodeIfPresent(Int.self, forKey: .nightsAired) ?? 0
        bestNight        = try c.decodeIfPresent(Int.self, forKey: .bestNight) ?? 0
        totalListeners   = try c.decodeIfPresent(Int.self, forKey: .totalListeners) ?? 0
        ownedTrackIDs    = try c.decodeIfPresent([Int].self, forKey: .ownedTrackIDs) ?? []
        unlockedGenres   = try c.decodeIfPresent([Genre].self, forKey: .unlockedGenres) ?? Genre.starters
        nextTrackID      = try c.decodeIfPresent(Int.self, forKey: .nextTrackID) ?? 1000
        customTrackTitles = try c.decodeIfPresent([Int: String].self, forKey: .customTrackTitles) ?? [:]
        claimedMilestones = try c.decodeIfPresent([Int].self, forKey: .claimedMilestones) ?? []
    }
}
