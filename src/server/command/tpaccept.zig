const std = @import("std");

const main = @import("main");
const command = main.server.command;
const Source = command.Source;

pub const description = "Accept a pending teleport request.";
pub const usage = "/tpaccept";

pub const Args = union(enum) {
	@"/tpaccept": struct {},
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
		source.sendMessage("#ff0000You have no pending teleport requests.", .{});
		return;
	};

	const sender = main.server.getUserByIndex(senderIndex) orelse {
		source.sendMessage("#ff0000The player who sent the request is no longer online.", .{});
		prof.tpa_request_from = null;
		return;
	};

	sender.player().back_pos = sender.player().pos;
	sender.player().pos = prof.pos;
	main.network.protocols.genericUpdate.sendTPCoordinates(sender.conn, prof.pos);

	sender.sendMessage("#00ff00Teleport request accepted. Teleporting...", .{});
	source.sendMessage("#00ff00Accepted teleport request from {s}.", .{sender.name});

	prof.tpa_request_from = null;
}
