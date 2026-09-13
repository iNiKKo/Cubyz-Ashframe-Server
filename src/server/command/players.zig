const std = @import("std");

const main = @import("main");
const command = main.server.command;
const Source = command.Source;

pub const description = "Lists all online players and their IDs.";
pub const usage = "/players";

pub const Args = union(enum) {
	@"/players": struct {},
};

pub fn execute(args: Args, source: Source) void {
	_ = args;
	const userList = main.server.getUserList(main.stackAllocator);
	defer main.stackAllocator.free(userList);

	if (userList.len == 0) {
		source.sendMessage("#ffff00There are no players online.", .{});
		return;
	}

	source.sendMessage("#00ff00--- Online Players ({d}) ---", .{userList.len});
	for (userList) |user| {
		source.sendMessage("#ffffff- {s} #aaaaaa(@{d})", .{user.name, user.playerIndex});
	}
}
