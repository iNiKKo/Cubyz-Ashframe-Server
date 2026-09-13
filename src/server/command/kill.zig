const std = @import("std");

const main = @import("main");
const command = main.server.command;
const Source = command.Source;
const ashutil = @import("ashutil.zig");

pub const description = "Kills the player";
pub const usage =
	\\/kill
	\\/kill @<playerIndex>
	\\/kill <name>
;

pub const Args = union(enum) {
	@"/kill <playerIndex>": struct { playerIndex: ?command.PlayerIndex },
	@"/kill <name>": struct { name: []const u8 },
};

pub fn execute(args: Args, source: Source) void {
	const target = switch (args) {
		.@"/kill <playerIndex>" => |params| command.Target.fromPlayerIndex(params.playerIndex, source) catch return,
		.@"/kill <name>" => |params| blk: {
			const user = ashutil.findTargetByNameOrIndex(params.name) orelse {
				source.sendMessage("#e6312cPlayer '#cfcfcf{s}#e6312c' not found or offline.", .{params.name});
				return;
			};
			break :blk command.Target{.user = user};
		},
	};

	main.sync.addHealth(-std.math.floatMax(f32), .kill, .server, target.user.id);
}
