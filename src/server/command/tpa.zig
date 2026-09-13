const std = @import("std");

const main = @import("main");
const command = main.server.command;
const Source = command.Source;
const User = main.server.User;

pub const description = "Request to teleport to another player.";
pub const usage = "/tpa <player>";

pub const Args = union(enum) {
	@"/tpa <target>": struct {target: []const u8},
};

/// Strips Cubyz color codes (§#rrggbb) from a name so fuzzy matching works on the visible text.
fn cleanColorCodes(allocator: std.mem.Allocator, name: []const u8) []const u8 {
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

fn findTarget(targetStr: []const u8, source: Source) ?*User {
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
	_ = source;
	if (partialMatches != 1) return null;
	return result;
}

pub fn execute(args: Args, source: Source) void {
	if (source != .user) {
		source.sendMessage("Command cannot be run without a user", .{});
		return;
	}
	const user = source.user;
	const targetStr = args.@"/tpa <target>".target;

	const target = findTarget(targetStr, source) orelse {
		source.sendMessage("#ff0000Player '{s}' not found or offline.", .{targetStr});
		return;
	};

	if (target.playerIndex == user.playerIndex) {
		source.sendMessage("#ff0000You cannot teleport to yourself!", .{});
		return;
	}

	target.player().tpa_request_from = user.playerIndex;
	source.sendMessage("#00ff00Teleport request sent to {s}.", .{target.name});
	target.sendMessage("#ffff00{s} wants to teleport to you. Type #00ff00/tpaccept #ffff00to accept.", .{user.name});
}
