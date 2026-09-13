const std = @import("std");

const main = @import("main");
const command = main.server.command;
const Source = command.Source;

pub const description = "Toggle your Away From Keyboard status.";
pub const usage = "/afk";

pub const Args = union(enum) {
	@"/afk": struct {},
};

pub fn execute(args: Args, source: Source) void {
	_ = args;
	if (source != .user) {
		source.sendMessage("Command cannot be run without a user", .{});
		return;
	}
	const user = source.user;
	const prof = user.player();
	prof.is_afk = !prof.is_afk;
	prof.still_time = 0.0;

	if (prof.is_afk) {
		main.server.sendMessage("{s}§#8a8a8a is now AFK", .{user.name});
	} else {
		main.server.sendMessage("{s}§#cfcfcf is no longer AFK", .{user.name});
	}
}
