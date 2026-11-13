# UPS Guard

Keeps a heavy multiplayer Factorio 2.1 save fast. Pick an effect level in the mod settings and a maintenance pass (default every 4 hours) does the rest in small steps.

## Levels

The setting "Effect level" writes a ready set of settings. You can still change any of them afterwards; "Custom" writes nothing.

| | Minimal (default) | Medium | High |
| --- | --- | --- | --- |
| Ground items | yes | yes | yes |
| Enemy count and warnings | yes | yes | yes |
| Castra fixes (pause and thin, stuck collectors) | yes | yes | yes |
| Fire and remnants removed | | yes | yes |
| Far enemy bases paused | Castra only | every planet | every planet |
| Slower enemy expansion | | yes | stronger |
| Pollution cleared on empty planets | | yes | after 2 h |
| Asteroids around platforms | | spawn 75%, limit 600 | spawn 50%, limit 250 |
| Enemy pathfinding and attack groups | | 80% | 50% |
| Trains without a path counted | | yes | yes |
| Pass slows down with many players online | | 12 players | 6 players |
| Map trimming, automatic thinning, new planet tuning | | | yes |
| Planets nobody uses deleted | | | after 48 h |
| Pollution spreads less, robots build slower | | | yes |

Everything is also a separate setting, so you can start from a level and change single values. Values the mod changes in the game (pathfinding, pollution, asteroids, robots, expansion) are saved first and put back when you switch the setting off.

## What it does

- removes items lying on the ground, away from players
- removes fire and remnants (and ghosts, if you list them)
- trims far empty map (chunks with no buildings, radar or artillery nearby)
- deletes planets nobody uses, or planets you list once
- pauses far enemy bases and can thin them, wakes them when a player comes close
- counts nests, enemy units and trains without a path, and warns in chat
- keeps asteroids around space platforms under a limit
- clears pollution on planets nobody visits
- lowers enemy pathfinding, attack groups, asteroid spawning and robot building work
- paces enemy expansion and tunes enemies on new planets

The end of each pass is one chat card with only the lines that have something to say. Destructive parts are off on the minimal level.

## Commands

`/upq help` lists them. Players: `status`, `surfaces`, `trains`, `config`, `messages on|off`. Admins: `set`, `reset`, `preset`, `cycle`, `abort`, `report`, `clean`, `junk`, `pollution`, `platforms`, `sweep`, `trim`, `freeze`, `thin`, `enemies artillery|near|reset`, `surface delete|unused`, `profile`. Commands that remove things only count until you add `confirm`.

## Server settings that help too

These are in `server-settings.json`, not in the mod: a longer autosave interval, `non_blocking_saving` where it is supported, and a latency setting that fits your players. Check the names against your game version.

[![Support me on Boosty](https://img.shields.io/badge/Support%20me%20on-Boosty-F15F2C?style=for-the-badge)](https://boosty.to/bruklynben)

The mod is free. If you like it, you can say thanks with a one-time donation on Boosty: no subscription is needed.

## Development

- Source: `src/ups-guard`
- Build: `python tools/build.py` (zip in `dist/`)
- Install into the game: `python tools/install.py` (only when Factorio is closed)

License: MIT. Author: bruklyn.ben.
