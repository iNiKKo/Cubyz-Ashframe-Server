const std = @import("std");

const main = @import("main");
const ZonElement = main.ZonElement;
const vec = main.vec;
const Vec3f = vec.Vec3f;
const Vec3d = vec.Vec3d;
const NeverFailingAllocator = main.heap.NeverFailingAllocator;

pos: Vec3d = .{0, 0, 0},
vel: Vec3d = .{0, 0, 0},
rot: Vec3f = .{0, 0, 0},

// --- ASHFRAME CUSTOM (Fields) ---
prefix: ?[]const u8 = null,
tpa_request_from: ?usize = null,
still_time: f32 = 0.0,
is_afk: bool = false,
home_pos: ?Vec3d = null,
back_pos: ?Vec3d = null,
playtime: u64 = 0,
login_time: i64 = 0,
// --- ASHFRAME CUSTOM (Fields) ---

health: f32 = 8,
maxHealth: f32 = 8,
energy: f32 = 8,
maxEnergy: f32 = 8,
name: ?[]const u8 = null,
id: main.entity.Entity = .noValue,

pub fn loadFrom(self: *@This(), id: main.entity.Entity, zon: ZonElement, comptime side: main.sync.Side, defaultPos: Vec3d) !void {
	self.id = id;
	self.pos = zon.get(Vec3d, "position") orelse defaultPos;
	self.vel = zon.get(Vec3d, "velocity") orelse .{0, 0, 0};
	self.rot = zon.get(Vec3f, "rotation") orelse .{0, 0, 0};
	self.health = zon.get(f32, "health") orelse self.maxHealth;
	self.energy = zon.get(f32, "energy") orelse self.maxEnergy;

	// --- ASHFRAME CUSTOM (loadFrom) ---
	self.playtime = zon.get(u64, "playtime") orelse 0;
	self.login_time = @intCast(@divTrunc(main.timestamp().toNanoseconds(), 1000000000));
	// --- ASHFRAME CUSTOM (loadFrom) ---

	if (zon.getChildOrNull("components")) |components| {
		try main.entity.loadComponentsFromBase64(components.as([]const u8) orelse "", self.id, side);
	}

	if (zon.getChildOrNull("name")) |name| {
		if (self.name) |oldname| {
			main.globalAllocator.free(oldname);
		}
		self.name = main.globalAllocator.dupe(u8, name.as([]const u8) orelse "invalid name");
	}

	// --- ASHFRAME CUSTOM (loadFrom) ---
	self.back_pos = zon.get(Vec3d, "back_pos");

	// Single-home format.
	if (zon.get(Vec3d, "home_pos")) |hp| {
		self.home_pos = hp;
	} else {
		// Backward compatibility with the old 3-slot format: prefer whichever slot
		// was marked as the respawn point, otherwise fall back to the first filled slot.
		const legacySlots = [3]?Vec3d{
			zon.get(Vec3d, "ash_hp_0"),
			zon.get(Vec3d, "ash_hp_1"),
			zon.get(Vec3d, "ash_hp_2"),
		};
		const spawnIndex = zon.get(usize, "ash_spawn_index") orelse 0;
		if (spawnIndex < legacySlots.len and legacySlots[spawnIndex] != null) {
			self.home_pos = legacySlots[spawnIndex];
		} else {
			for (legacySlots) |slot| {
				if (self.home_pos == null) self.home_pos = slot;
			}
		}
	}

	if (zon.getChildOrNull("prefix")) |prefix_node| {
		if (self.prefix) |old| main.globalAllocator.free(old);
		self.prefix = main.globalAllocator.dupe(u8, prefix_node.as([]const u8) orelse "");
	}
	// --- ASHFRAME CUSTOM (loadFrom) ---
}
pub fn clone(self: *@This(), copy: *@This()) void {
	const originalID = copy.id;
	std.debug.assert(copy.name == null);
	copy.* = self.*;
	copy.name = if (self.name) |name| main.globalAllocator.dupe(u8, name) else null;

	// --- ASHFRAME CUSTOM (clone) ---
	copy.prefix = if (self.prefix) |p| main.globalAllocator.dupe(u8, p) else null;
	// --- ASHFRAME CUSTOM (clone) ---

	copy.id = originalID;
}

pub fn save(self: *const @This(), allocator: NeverFailingAllocator, audience: main.entity.AudienceInfo) ZonElement {
	const zon = ZonElement.initObject(allocator);
	zon.put("position", self.pos);
	zon.put("velocity", self.vel);
	zon.put("rotation", self.rot);
	zon.put("health", self.health);
	zon.put("energy", self.energy);
	zon.put("id", @intFromEnum(self.id));

	// --- ASHFRAME CUSTOM (save) ---
	const current_time: i64 = @intCast(@divTrunc(main.timestamp().toNanoseconds(), 1000000000));
	const session_seconds = if (current_time > self.login_time) current_time - self.login_time else 0;
	zon.put("playtime", self.playtime + @as(u64, @intCast(session_seconds)));
	// --- ASHFRAME CUSTOM (save) ---

	var base64 = main.entity.server.componentsToBase64(allocator, self.id, audience);
	defer base64.deinit(allocator);
	zon.putOwnedString("components", base64.getEncodedMessage());

	// --- ASHFRAME CUSTOM (save) ---
	if (self.back_pos) |bp| {
		zon.put("back_pos", bp);
	}
	if (self.home_pos) |hp| {
		zon.put("home_pos", hp);
	}
	if (self.prefix) |p| {
		zon.put("prefix", p);
	}
	// --- ASHFRAME CUSTOM (save) ---

	if (self.name) |name| {
		zon.put("name", name);
	}
	return zon;
}
pub fn deinit(self: *@This(), comptime side: main.sync.Side) void {
	// --- ASHFRAME CUSTOM (deinit) ---
	if (self.prefix) |p| {
		main.globalAllocator.free(p);
		self.prefix = null;
	}
	// --- ASHFRAME CUSTOM (deinit) ---

	if (self.name) |name| {
		main.globalAllocator.free(name);
		self.name = null;
	}
	if (side == .server) {
		main.entity.server.removeAllComponents(self.id);
	} else {
		main.entity.client.removeAllComponents(self.id);
	}
}
