import UIKit

/// Bundled picture-symbol set (professional AAC symbols, e.g. Mulberry — CC BY-SA 4.0).
///
/// Symbols are stored in the asset catalog under names like `sym_apple` (PDF vectors, so they stay
/// crisp at every grid size). This type is the lookup/search surface used by the tiles and the symbol
/// picker. In Phase 1 the catalog may be empty — `exists` simply returns false and tiles fall back to
/// emoji, so the app works before any symbols are bundled.
enum SymbolLibrary {
    /// Prefix every bundled symbol asset shares.
    static let assetPrefix = "sym_"

    /// True when a bundled symbol asset with this exact name is present in the app.
    static func exists(_ name: String) -> Bool {
        guard name.hasPrefix(assetPrefix) else { return false }
        return UIImage(named: name) != nil
    }

    /// All bundled symbol asset names (ARASAAC pictograms, CC BY-NC-SA). Single source of truth for
    /// the picker and search.
    static let allNames: [String] = [
        "sym_a", "sym_again", "sym_and", "sym_angry", "sym_apple", "sym_arm", "sym_baby", "sym_bad",
        "sym_ball", "sym_banana", "sym_bed", "sym_big", "sym_biscuit", "sym_blocks", "sym_book",
        "sym_bread", "sym_brother", "sym_bubbles", "sym_build", "sym_but", "sym_bye", "sym_calm",
        "sym_can", "sym_car", "sym_cheese", "sym_clean", "sym_cold", "sym_cracker", "sym_dad", "sym_dirty",
        "sym_do", "sym_doll", "sym_done", "sym_drink", "sym_ears", "sym_eat", "sym_egg", "sym_excited",
        "sym_eyes", "sym_fast", "sym_finished", "sym_foot", "sym_friend", "sym_give", "sym_glue", "sym_go",
        "sym_good", "sym_grandma", "sym_grandpa", "sym_hair", "sym_hand", "sym_happy", "sym_hard",
        "sym_hat", "sym_head", "sym_hello", "sym_help", "sym_home", "sym_hot", "sym_how", "sym_hurt",
        "sym_i", "sym_in", "sym_it", "sym_jacket", "sym_juice", "sym_jump", "sym_leg", "sym_like",
        "sym_listen", "sym_little", "sym_look", "sym_loud", "sym_make", "sym_me", "sym_milk", "sym_more",
        "sym_mouth", "sym_mum", "sym_music", "sym_my", "sym_my_turn", "sym_no", "sym_nose", "sym_not",
        "sym_off", "sym_on", "sym_open", "sym_outside", "sym_pants", "sym_paper", "sym_park", "sym_pasta",
        "sym_pencil", "sym_play", "sym_please", "sym_put", "sym_puzzle", "sym_quiet", "sym_read",
        "sym_rice", "sym_run", "sym_sad", "sym_scared", "sym_school", "sym_scissors", "sym_shirt",
        "sym_shoes", "sym_shop", "sym_sick", "sym_sister", "sym_sit", "sym_sleep", "sym_slide", "sym_slow",
        "sym_smoothie", "sym_snack", "sym_socks", "sym_soft", "sym_sorry", "sym_stop", "sym_swing",
        "sym_tea", "sym_teacher", "sym_thank_you", "sym_the", "sym_throw", "sym_tired", "sym_to",
        "sym_toilet", "sym_tummy", "sym_turn", "sym_up", "sym_want", "sym_wash", "sym_water", "sym_what",
        "sym_when", "sym_where", "sym_who", "sym_why", "sym_with", "sym_yes", "sym_you", "sym_your_turn",
        "sym_yucky", "sym_yummy"
    ]

    /// Best symbol asset name for a word label, or nil if none is bundled. Phase 2 fills the map.
    static func suggestedSymbol(for label: String) -> String? {
        let key = assetPrefix + label.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
        return exists(key) ? key : nil
    }

    /// Display word for a symbol asset name (drops the `sym_` prefix, underscores → spaces).
    static func label(for name: String) -> String {
        String(name.dropFirst(assetPrefix.count)).replacingOccurrences(of: "_", with: " ")
    }

    /// Names matching a search query (case-insensitive substring on the part after the prefix).
    static func search(_ query: String) -> [String] {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return allNames }
        return allNames.filter { label(for: $0).lowercased().contains(q) }
    }
}
