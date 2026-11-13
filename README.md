# UPS Guard

Keeps a heavy multiplayer Factorio 2.1 save fast. A maintenance pass every few hours (default 4) does the parts you switch on:

- removes items lying on the ground, away from players
- trims far empty map (chunks with no buildings, radar or artillery nearby)
- deletes planets nobody uses, or planets you list once
- pauses far enemy bases and can thin them, wakes them when a player comes close
- counts nests and enemy units and warns when a planet passes your limits
- paces enemy expansion and tunes enemies on new planets

Everything is optional and set in the mod settings or in game with `/upq`. Destructive parts are off by default.

## Commands

`/upq help` lists them. Players: `status`, `surfaces`, `config`, `messages on|off`. Admins: `set`, `reset`, `preset`, `cycle`, `abort`, `report`, `clean`, `sweep`, `trim`, `freeze`, `thin`, `enemies artillery|near|reset`, `surface delete|unused`. Commands that remove things only count until you add `confirm`.

[![Support me on Boosty](https://img.shields.io/badge/Support%20me%20on-Boosty-F15F2C?style=for-the-badge)](https://boosty.to/bruklynben)

The mod is free. If you like it, you can say thanks with a one-time donation on Boosty: no subscription is needed.

## Development

- Source: `src/ups-quard`
- Build: `python tools/build.py` (zip in `dist/`)
- Install into the game: `python tools/install.py` (only when Factorio is closed)

License: MIT. Author: bruklyn.ben.
