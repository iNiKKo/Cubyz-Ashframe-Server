# Ashframe custom files — Cubyz 0.4.0

This branch contains **only the files that differ from upstream
[PixelGuys/Cubyz](https://github.com/PixelGuys/Cubyz) master** (as of
commit `89233bd`, 2026-09-07). It is not a full copy of the game —
download a real Cubyz 0.4.0 release/checkout separately, then copy these
files into it, overwriting the matching paths.

## How to use

1. Download or clone upstream Cubyz (0.4.0 release once it's out, or
   current master as a preview).
2. Copy every file from this branch into the same relative path in your
   Cubyz checkout, overwriting what's there.
3. Build as normal (`zig build`).

## What's in here

New commands (no upstream equivalent):

- `src/server/command/home.zig` — `/home add/remove/list/spawn/<name>`
- `src/server/command/tpa.zig` — `/tpa <player>`
- `src/server/command/tpaccept.zig` — `/tpaccept`
- `src/server/command/back.zig` — `/back`
- `src/server/command/players.zig` — `/players`
- `src/server/command/playtime.zig` — `/playtime`, `/playtime list`
- `src/server/command/afk.zig` — `/afk`
- `src/server/command/prefix.zig` — `/prefix add/remove @<index> <text>`
- `src/server/emojis.zig` — `:shortcode:` → emoji table used by chat formatting

Modified upstream files:

- `src/server/command/_list.zig` — registers the new commands above.
- `src/server/Entity.zig` — adds player fields the new commands need
  (home slots, back position, playtime, AFK state, chat prefix) plus
  their save/load logic.
- `src/server/server.zig` — chat formatting (`messageFrom`): applies
  emoji shortcodes and `[prefix]` before the player name; grants
  default permissions for the new commands on join.
- `src/server/world.zig` — auto-AFK after idling, on top of the
  restored neighbor-block-update fix.

`/spawn` (bare, no args) and `/help` (permission-filtered output) are
**not** in this overlay — current upstream master already behaves this
way natively, no changes needed.

Not included on purpose: chest-locking and other older fork features —
out of scope for this pass.
