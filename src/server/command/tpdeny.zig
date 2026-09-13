const std = @import("std");

const main = @import("main");
const command = main.server.command;
const Source = command.Source;

pub const description = "Decline a pending teleport request.";
pub const usage = "/tpdeny";

pub const Args = union(enum) {
	@"/tpdeny": struct {},
};

pub fn execute(args: Args, source: Source) void {
	_ = args;
	if (source != .user) {
		source.sendMessage("Command cannot be run without a user", .{});
		return;
	}
	const user = source.user;
	const prof = user.player();

	const senderIndex = prof.tpa_request_from orelse {
		source.sendMessage("#e6312cYou have no pending teleport requests.", .{});
		return;
	};

	prof.tpa_request_from = null;

	if (main.server.getUserByIndex(senderIndex)) |sender| {
		sender.sendMessage("#cfcfcf{s} #8a8a8adeclined your teleport request.", .{user.name});
	}
	source.sendMessage("#cfcfcfTeleport request declined.", .{});
}
