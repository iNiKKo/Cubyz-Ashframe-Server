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
		source.sendMessage("#e6312cYou have no pending teleport requests.", .{});
		return;
	};

	const sender = main.server.getUserByIndex(senderIndex) orelse {
		source.sendMessage("#e6312cThe player who sent the request is no longer online.", .{});
		prof.tpa_request_from = null;
		return;
	};

	sender.player().back_pos = sender.player().pos;
	sender.player().pos = prof.pos;
	main.network.protocols.genericUpdate.sendTPCoordinates(sender.conn, prof.pos);

	sender.sendMessage("#cfcfcfTeleport request accepted. Teleporting...", .{});
	source.sendMessage("#cfcfcfAccepted teleport request from #e6312c{s}#cfcfcf.", .{sender.name});

	prof.tpa_request_from = null;
}
