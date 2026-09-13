const std = @import("std");

const main = @import("main");
const command = main.server.command;
const Source = command.Source;
const files = main.files;

pub const description = "Check your playtime.";
pub const usage =
	\\/playtime
	\\/playtime list
;

pub const Args = union(enum) {
	@"/playtime list": struct {action: enum {list}},
	@"/playtime": struct {},
};

const LeaderboardEntry = struct {
	name: []const u8,
	playtime: u64,

	fn compare(_: void, a: LeaderboardEntry, b: LeaderboardEntry) bool {
		return a.playtime > b.playtime;
	}
};

fn getLivePlaytime(prof: *main.server.Entity) u64 {
	const cur: i64 = @intCast(@divTrunc(main.timestamp().toNanoseconds(), 1000000000));
	const session = if (cur > prof.login_time) cur - prof.login_time else 0;
	return prof.playtime + @as(u64, @intCast(session));
}

pub fn execute(args: Args, source: Source) void {
	switch (args) {
		.@"/playtime" => {
			if (source != .user) {
				source.sendMessage("Command cannot be run without a user", .{});
				return;
			}
			const total = getLivePlaytime(source.user.player());
			source.sendMessage("#00ff00Your total playtime: #ffff00{}h {}m", .{total/3600, (total%3600)/60});
		},
		.@"/playtime list" => {
			const world = main.server.world orelse {
				source.sendMessage("#ff0000No world is currently loaded.", .{});
				return;
			};

			source.sendMessage("#ffff00- Server Playtime Leaderboard -", .{});

			var leaderList: main.List(LeaderboardEntry) = .empty;
			defer {
				for (leaderList.items) |e| main.stackAllocator.free(e.name);
				leaderList.deinit(main.stackAllocator);
			}

			world.saveAllPlayers() catch |err| {
				std.log.err("Error while saving players for /playtime list: {s}", .{@errorName(err)});
			};

			const playerDirPath = main.stackAllocator.print("saves/{s}/players", .{world.path});
			defer main.stackAllocator.free(playerDirPath);

			var playerDir = files.cubyzDir().openIterableDir(playerDirPath) catch {
				source.sendMessage("#ff0000Could not read player data.", .{});
				return;
			};
			defer playerDir.close();

			var iterator = playerDir.iterate();
			while (iterator.next(main.io) catch null) |file| {
				if (file.kind != .file or !std.mem.endsWith(u8, file.name, ".zon")) continue;

				const path = main.stackAllocator.print("saves/{s}/players/{s}", .{world.path, file.name});
				defer main.stackAllocator.free(path);

				const playerData = files.cubyzDir().readToZon(main.stackAllocator, path) catch continue;
				defer playerData.deinit(main.stackAllocator);

				const name = playerData.get([]const u8, "name") orelse "Unknown Player";
				const entityZon = playerData.getChildOrNull("entity") orelse continue;
				var accumulated = entityZon.get(u64, "playtime") orelse 0;

				const userList = main.server.getUserList(main.stackAllocator);
				defer main.stackAllocator.free(userList);
				for (userList) |u| {
					if (std.mem.eql(u8, u.name, name)) {
						accumulated = getLivePlaytime(u.player());
						break;
					}
				}

				leaderList.append(main.stackAllocator, .{.name = main.stackAllocator.dupe(u8, name), .playtime = accumulated});
			}

			std.mem.sort(LeaderboardEntry, leaderList.items, {}, LeaderboardEntry.compare);

			const displayCount = @min(@as(usize, 10), leaderList.items.len);
			for (0..displayCount) |i| {
				const entry = leaderList.items[i];
				source.sendMessage("#00ff00{}. #ffff00{s} §#00ff00- {}h {}m", .{i + 1, entry.name, entry.playtime/3600, (entry.playtime%3600)/60});
			}
		},
	}
}
