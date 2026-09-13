const std = @import("std");

const main = @import("main");
const command = main.server.command;
const Source = command.Source;

pub const description = "Manage and teleport to your saved home location.";
pub const usage =
	\\/home
	\\/home set
	\\/home remove
;

pub const Args = union(enum) {
	@"/home <action>": struct {action: enum {set, remove}},
	@"/home": struct {},
};

pub fn execute(args: Args, source: Source) void {
	if (source != .user) {
		source.sendMessage("Command cannot be run without a user", .{});
		return;
	}
	const user = source.user;
	const prof = user.player();

	switch (args) {
		.@"/home" => {
			if (prof.home_pos) |hp| {
				prof.back_pos = prof.pos;
				main.network.protocols.genericUpdate.sendTPCoordinates(user.conn, hp);
				source.sendMessage("#cfcfcfTeleporting to your home...", .{});
			} else {
				source.sendMessage("#e6312cYou do not have a home set yet. #b8221e(Use /home set to save one)", .{});
			}
		},
		.@"/home <action>" => |params| switch (params.action) {
			.set => {
				prof.home_pos = prof.pos;
				source.sendMessage("#cfcfcfHome saved at your current position!", .{});
			},
			.remove => {
				if (prof.home_pos == null) {
					source.sendMessage("#e6312cYou do not have a home set.", .{});
				} else {
					prof.home_pos = null;
					source.sendMessage("#cfcfcfHome has been removed.", .{});
				}
			},
		},
	}
}
