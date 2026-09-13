const std = @import("std");

const main = @import("main");
const command = main.server.command;
const Source = command.Source;

pub const description = "Manage, list, and teleport to your saved home locations.";
pub const usage =
	\\/home <name>
	\\/home add <name>
	\\/home remove <name>
	\\/home list
	\\/home spawn <name>
;

const MAX_HOMES = 3;

pub const Args = union(enum) {
	@"/home <action> <name>": struct {action: enum {add, remove, spawn}, name: []const u8},
	@"/home list": struct {action: enum {list}},
	@"/home <name>": struct {name: []const u8},
};

pub fn execute(args: Args, source: Source) void {
	if (source != .user) {
		source.sendMessage("Command cannot be run without a user", .{});
		return;
	}
	const user = source.user;
	const prof = user.player();

	switch (args) {
		.@"/home list" => {
			var listMsg: main.List(u8) = .empty;
			defer listMsg.deinit(main.stackAllocator);

			listMsg.appendSlice(main.stackAllocator, "#00ff00Your Saved Homes:");

			var count: usize = 0;
			for (prof.home_names, 0..) |optName, i| {
				if (optName) |hn| {
					if (prof.home_pos[i] != null) {
						count += 1;
						listMsg.append(main.stackAllocator, '\n');
						listMsg.appendSlice(main.stackAllocator, " - ");
						listMsg.appendSlice(main.stackAllocator, hn);
					}
				}
			}

			if (count == 0) {
				source.sendMessage("#ff0000You do not have any homes saved yet.", .{});
			} else {
				source.sendMessage("{s}", .{listMsg.items});
			}
		},
		.@"/home <action> <name>" => |params| switch (params.action) {
			.add => {
				const name = params.name;
				if (std.mem.eql(u8, name, "list") or std.mem.eql(u8, name, "add") or std.mem.eql(u8, name, "remove") or std.mem.eql(u8, name, "spawn")) {
					source.sendMessage("#ff0000Error: You cannot name a home '{s}'.", .{name});
					return;
				}

				var existingSlot: ?usize = null;
				var emptySlot: ?usize = null;
				for (prof.home_names, 0..) |optName, i| {
					if (optName) |hn| {
						if (std.mem.eql(u8, hn, name)) {
							existingSlot = i;
							break;
						}
					} else if (emptySlot == null) {
						emptySlot = i;
					}
				}

				if (existingSlot) |slot| {
					prof.home_pos[slot] = prof.pos;
					source.sendMessage("#00ff00Home '{s}' updated to current position!", .{name});
				} else if (emptySlot) |slot| {
					prof.home_pos[slot] = prof.pos;
					prof.home_names[slot] = main.globalAllocator.dupe(u8, name);
					source.sendMessage("#00ff00Home '{s}' saved! ({}/{} slots filled).", .{name, slot + 1, MAX_HOMES});
				} else {
					source.sendMessage("#ff0000Error: You have hit the limit of {} homes maximum. Remove one first.", .{MAX_HOMES});
				}
			},
			.remove => {
				const name = params.name;
				var foundSlot: ?usize = null;
				for (prof.home_names, 0..) |optName, i| {
					if (optName) |hn| {
						if (std.mem.eql(u8, hn, name)) {
							foundSlot = i;
							break;
						}
					}
				}

				if (foundSlot) |slot| {
					prof.home_pos[slot] = null;
					if (prof.home_names[slot]) |oldStr| {
						main.globalAllocator.free(oldStr);
					}
					prof.home_names[slot] = null;
					source.sendMessage("#00ff00Home '{s}' has been successfully removed.", .{name});
				} else {
					source.sendMessage("#ff0000No home matching '{s}' was found.", .{name});
				}
			},
			.spawn => {
				const name = params.name;
				var foundSlot: ?usize = null;
				for (prof.home_names, 0..) |optName, i| {
					if (optName) |hn| {
						if (std.mem.eql(u8, hn, name)) {
							foundSlot = i;
							break;
						}
					}
				}

				if (foundSlot) |slot| {
					if (prof.home_pos[slot] != null) {
						prof.spawn_home_index = slot;
						source.sendMessage("#00ff00Set home '{s}' as your active respawn point on death!", .{name});
					} else {
						source.sendMessage("#ff0000Error: Home '{s}' has no coordinates set.", .{name});
					}
				} else {
					source.sendMessage("#ff0000No home matching '{s}' was found.", .{name});
				}
			},
		},
		.@"/home <name>" => |params| {
			const name = params.name;
			var targetSlot: ?usize = null;
			for (prof.home_names, 0..) |optName, i| {
				if (optName) |hn| {
					if (std.mem.eql(u8, hn, name)) {
						targetSlot = i;
						break;
					}
				}
			}

			if (targetSlot) |slot| {
				if (prof.home_pos[slot]) |hp| {
					prof.back_pos = prof.pos;
					main.network.protocols.genericUpdate.sendTPCoordinates(user.conn, hp);
					source.sendMessage("#00ff00Teleporting to home '{s}'...", .{name});
					return;
				}
			}

			source.sendMessage("#ff0000Home '{s}' does not exist.", .{name});
		},
	}
}
