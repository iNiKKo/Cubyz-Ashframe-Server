const std = @import("std");

const main = @import("main");
const command = main.server.command;
const Source = command.Source;
const User = main.server.User;

/// Strips Cubyz color codes (§#rrggbb) from a name so fuzzy matching works on the visible text.
pub fn cleanColorCodes(allocator: std.mem.Allocator, name: []const u8) []const u8 {
	var result: std.ArrayList(u8) = .empty;
	errdefer result.deinit(allocator);

	var i: usize = 0;
	while (i < name.len) {
		if (std.mem.startsWith(u8, name[i..], "§")) {
			i += 1;
			if (i < name.len and name[i] == '#') {
				i += 7;
			}
			continue;
		}
		result.append(allocator, name[i]) catch {};
		i += 1;
	}
	return result.toOwnedSlice(allocator) catch name;
}

/// Resolves a `@<playerIndex>` or fuzzy/partial player-name string to an online user.
/// Name matching ignores color codes and case; an ambiguous partial match (more than
/// one player) returns null rather than guessing.
pub fn findTargetByNameOrIndex(targetStr: []const u8) ?*User {
	if (std.ascii.startsWithIgnoreCase(targetStr, "@")) {
		const cleanIndexStr = std.mem.trim(u8, targetStr[1..], &std.ascii.whitespace);
		const index = std.fmt.parseInt(usize, cleanIndexStr, 10) catch return null;
		return main.server.getUserByIndex(index);
	}

	const userList = main.server.getUserList(main.stackAllocator);
	defer main.stackAllocator.free(userList);

	const cleanTarget = cleanColorCodes(main.stackAllocator.allocator, targetStr);
	defer main.stackAllocator.allocator.free(cleanTarget);

	// Pass 1: exact name match (ignoring color codes/case).
	for (userList) |u| {
		const cleanUserName = cleanColorCodes(main.stackAllocator.allocator, u.name);
		defer main.stackAllocator.allocator.free(cleanUserName);

		if (std.ascii.eqlIgnoreCase(cleanUserName, cleanTarget)) return u;
	}

	// Pass 2: unique substring match.
	var result: ?*User = null;
	var partialMatches: usize = 0;
	for (userList) |u| {
		const cleanUserName = cleanColorCodes(main.stackAllocator.allocator, u.name);
		defer main.stackAllocator.allocator.free(cleanUserName);

		if (std.ascii.indexOfIgnoreCase(cleanUserName, cleanTarget) != null) {
			partialMatches += 1;
			result = u;
		}
	}
	if (partialMatches != 1) return null;
	return result;
}
