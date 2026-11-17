# Zoom Out

A mod for [Dungeon Rampage Haxe](https://github.com/Tutez64/Dungeon-Rampage-Haxe), made from [DRH-Mods-Template](https://github.com/Tutez64/DRH-Mods-Template).

<!-- drh:show -->
Zooms the dungeon camera out so you see more of the floor around your hero.

- **Settings → MODS → Zoom Out**: turn it on or off, and set **Camera zoom** (1 is the game's normal view, lower shows more, default 0.75).
- **Keys**: `-` zooms out and `=` zooms in, in steps of 0.05. Rebind them at the end of **Settings → CONTROLS**.
- The game's own camera effects still happen (attack zooms, boss rooms), relative to your zoom.

Only the camera on your screen changes: nothing is sent to the server.
<!-- /drh:show -->

Uses the game's camera directly (`extends`), so it may need an update after a DRH update.
