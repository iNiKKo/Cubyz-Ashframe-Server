# Cubyz-Ashframe-Server

Custom server modification specifically for hosting and running the **Ashframe** community server.

This branch targets Cubyz **0.4.0** download or clone upstream Cubyz separately, then copy these files over the matching paths and build as normal (`zig build`).

---

## Player Commands

| Syntax / Usage | Description |
| :--- | :--- |
| `/home` | Teleports you to your saved home location. |
| `/home set` | Saves your current location as your home. |
| `/home remove` | Deletes your saved home. |
| `/tpa <player>` | Sends a teleport request using smart name matching. Automatically filters out game color codes and handles case-insensitive partial names or explicit `@id` fallbacks. |
| `/tpaccept` | Accepts a pending incoming teleport request. |
| `/tpdeny` | Declines a pending incoming teleport request. |
| `/back` | Teleports you back to your last position, including your exact spot of death right before you respawn. |
| `/spawn` | Teleports you instantly to the world spawn point. |
| `/msg <player> <message>` | Sends a private message to another player. Uses the same smart name matching as `/tpa`. |
| `/playtime` | Displays your total accumulated playtime on this server. |
| `/playtime list` | Opens the server-wide playtime leaderboard. |
| `/avatar <skin>` | Modifies your character's active 3D model skin. *(e.g., `/avatar base:skin_name`)* |
| `/afk` | Toggles your status to away-from-keyboard and notifies the chat. Also triggers automatically after 5 minutes idle. |
| `/players` | Displays a list of all currently connected online players. |
| `/kill @<playerIndex>` or `/kill <name>` | Kills the specified player (self, by index, or by smart name match). |
| `/help` | Displays a personalized list of commands showing only what you have permission to use. |

---

## Admin Commands

### Prefix Management
*   **Add a Prefix:**
    ```bash
    /prefix add @<playerIndex> <text>
    ```
    *Example:* `/prefix add @2 Admin` — Assigns a bracketed visual title to a player in chat. `<text>` may span multiple words, and can embed its own `§#rrggbb` color code (defaults to red if omitted).
*   **Remove a Prefix:**
    ```bash
    /prefix remove @<playerIndex>
    ```
    *Example:* `/prefix remove @2` — Strips the title and safely deallocates the string memory from the server.

> **Note:** Admin commands are dynamically filtered out of `/help` and hidden from regular users who lack permission.

---
