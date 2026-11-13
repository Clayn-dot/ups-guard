# UPS Guard

A Factorio mod that keeps a heavy multiplayer save fast. Pick an effect level (minimal, medium, high or extreme) and every few hours the mod quietly clears what the game works on for nothing: items on the ground, far empty map, planets nobody uses and enemy bases nobody is near. It works in small steps, so there is no freeze. Every part is also a separate setting, and nothing is tied to a server or a planet name.

Works with Factorio 2.0 and 2.1, with or without Space Age. Languages: English and Russian.

## Versions

| Mod version | Factorio |
| --- | --- |
| 1.0.x | 2.0 |
| 1.1.x | 2.1 |

Both come from the same source. A release of a mod has one game version, so the build script writes the right `info.json` and changelog for each.

## Levels

The setting "Effect level" writes a ready set of settings. You can still change any of them afterwards; "Custom" writes nothing. `/upg preset <name>` shows what a level would change, add `confirm` to apply it. Each level includes the one below it.

| | Minimal (default) | Medium | High | Extreme |
| --- | --- | --- | --- | --- |
| Ground items | yes | yes | yes | yes |
| Enemy count and warnings | yes | yes | yes | yes |
| Far empty map trimmed, margin | 24 chunks | 16 | 12 | 8 |
| Planets nobody ever used deleted | after 12 h | after 12 h | after 12 h | after 12 h |
| Planets used and left empty deleted | | | after 24 h | after 12 h |
| Fire and remnants removed | | yes | yes | yes |
| Far enemy bases paused, live zone | | 1500 tiles | 1000 | 600 |
| Automatic thinning when over the nest limits | | | yes | yes |
| Slower enemy expansion | | a little | more | most |
| Fewer nests on new planets | | a little | more | most |
| Enemy pathfinding / attack groups | | 90% / 100% | 75% / 90% | 50% / 60% |
| Pollution cleared on planets with no nests | | yes | yes | yes |
| Pollution cleared on planets with nests | | | | after 2 h |
| Pollution spreads less | | | yes | stronger |
| Asteroid limit around a platform | | | 600 | 400 |
| Asteroid spawning, robot building | | | | 75% |
| Trains without a path counted | | yes | yes | yes |
| Pass slows down with many players online | | 12 players | 8 | 6 |

Deleting a planet also resets its enemy evolution (evolution is kept per planet) and the map is generated again if someone returns. The numbers are starting values, not measurements. A rough guess of the gain on a big save: Minimal 0-2%, Medium 5-15%, High 10-25%, Extreme more than High. Values the mod changes in the game (pathfinding, pollution, asteroids, robots, expansion) are saved first and put back when you switch the setting off.

## Commands

`/upg help` lists them. Players: `status`, `surfaces`, `trains`, `config`, `messages on|off`. Admins: `set`, `reset`, `preset`, `cycle`, `abort`, `report`, `clean`, `junk`, `pollution`, `platforms`, `sweep`, `trim`, `freeze`, `thin`, `enemies artillery|near|reset`, `surface delete|unused`, `profile`. Commands that remove things only count until you add `confirm`.

## Other mods

No mod, planet or server name is built in, so planets and enemies from other mods are treated like the vanilla ones (surface lists in the settings). The mod adds no prototypes and no items.

Factory Radar, if installed, reads the pass schedule through the `ups-guard` remote interface (`schedule`) and ends its shift summary together with the pass.

## Layout

```
src/ups-guard/    the mod itself (info.json, control.lua, settings.lua, scripts/, locale/, thumbnail.png)
tools/            build.py (makes the zips), install.py (copies the zip into mods), make_cover.py (the cover image)
portal/           text of the mod portal page, images, cover
fonts/            Bruk Sans, used for the cover
```

## Build

```
python tools/build.py          # dist/for-2.1/ups-guard_1.1.0.zip
python tools/build.py 2.0      # dist/for-2.0/ups-guard_1.0.0.zip
python tools/build.py all      # both
python tools/install.py        # build and copy into the game mods folder (game closed)
```

## License

MIT, see the LICENSE file.
