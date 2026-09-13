const std = @import("std");

pub const Replacement = struct {
	shortcut: []const u8,
	value: []const u8,
};

pub const list = [_]Replacement{
	// --- Expressions & Faces ---
	.{.shortcut = ":joy:", .value = "😂"},
	.{.shortcut = ":rofl:", .value = "🤣"},
	.{.shortcut = ":smile:", .value = "🙂"},
	.{.shortcut = ":grinning:", .value = "😀"},
	.{.shortcut = ":grin:", .value = "😁"},
	.{.shortcut = ":wink:", .value = "😉"},
	.{.shortcut = ":blush:", .value = "😊"},
	.{.shortcut = ":innocent:", .value = "😇"},
	.{.shortcut = ":heart_eyes:", .value = "😍"},
	.{.shortcut = ":star_eyes:", .value = "🤩"},
	.{.shortcut = ":kissing:", .value = "😘"},
	.{.shortcut = ":tongue:", .value = "😜"},
	.{.shortcut = ":sob:", .value = "😭"},
	.{.shortcut = ":cry:", .value = "😢"},
	.{.shortcut = ":skull:", .value = "💀"},
	.{.shortcut = ":clown:", .value = "🤡"},
	.{.shortcut = ":thinking:", .value = "🤔"},
	.{.shortcut = ":shrug:", .value = "🤷"},
	.{.shortcut = ":salute:", .value = "🫡"},
	.{.shortcut = ":nerd:", .value = "🤓"},
	.{.shortcut = ":cool:", .value = "😎"},
	.{.shortcut = ":scream:", .value = "😱"},
	.{.shortcut = ":angry:", .value = "😡"},

	// --- Hearts & Effects ---
	.{.shortcut = ":heart:", .value = "❤️"},
	.{.shortcut = ":broken_heart:", .value = "💔"},
	.{.shortcut = ":fire:", .value = "🔥"},
	.{.shortcut = ":sparkles:", .value = "✨"},
	.{.shortcut = ":star:", .value = "⭐"},
	.{.shortcut = ":collision:", .value = "💥"},
	.{.shortcut = ":hundred:", .value = "💯"},

	// --- Gestures ---
	.{.shortcut = ":thumbsup:", .value = "👍"},
	.{.shortcut = ":thumbsdown:", .value = "👎"},
	.{.shortcut = ":ok:", .value = "👌"},
	.{.shortcut = ":clap:", .value = "👏"},
	.{.shortcut = ":pray:", .value = "🙏"},
	.{.shortcut = ":wave:", .value = "👋"},
	.{.shortcut = ":eyes:", .value = "👀"},

	// --- Gaming & Fantasy ---
	.{.shortcut = ":alien:", .value = "👽"},
	.{.shortcut = ":ghost:", .value = "👻"},
	.{.shortcut = ":robot:", .value = "🤖"},
	.{.shortcut = ":crown:", .value = "👑"},
	.{.shortcut = ":swords:", .value = "⚔️"},
	.{.shortcut = ":shield:", .value = "🛡️"},
	.{.shortcut = ":trophy:", .value = "🏆"},
	.{.shortcut = ":gem:", .value = "💎"},

	// --- Animals & Nature ---
	.{.shortcut = ":snail:", .value = "🐌"},
	.{.shortcut = ":cat:", .value = "🐱"},
	.{.shortcut = ":dog:", .value = "🐶"},
	.{.shortcut = ":fox:", .value = "🦊"},
	.{.shortcut = ":monkey:", .value = "🐵"},
	.{.shortcut = ":snake:", .value = "🐍"},
	.{.shortcut = ":crab:", .value = "🦀"},

	// --- System / UI Utilities ---
	.{.shortcut = ":check:", .value = "✅"},
	.{.shortcut = ":cross:", .value = "❌"},
	.{.shortcut = ":warn:", .value = "⚠️"},
	.{.shortcut = ":info:", .value = "ℹ️"},
	.{.shortcut = ":arrow_up:", .value = "▲"},
	.{.shortcut = ":arrow_down:", .value = "▼"},
};

/// Replaces `:shortcode:` occurrences in `msg` with their emoji using `buffer` as scratch space
/// for the replaced string. Returns a slice into `buffer` (or the original `msg` if nothing
/// needed replacing / the buffer was too small for a given replacement).
pub fn parseEmojis(msg: []const u8, buffer: []u8) []const u8 {
	var result = msg;
	var buf = buffer;

	inline for (list) |pair| {
		if (std.mem.indexOf(u8, result, pair.shortcut) != null) {
			const count = std.mem.replacementSize(u8, result, pair.shortcut, pair.value);
			if (count <= buf.len) {
				_ = std.mem.replace(u8, result, pair.shortcut, pair.value, buf);
				result = buf[0..count];
				buf = buf[count..];
			}
		}
	}
	return result;
}
