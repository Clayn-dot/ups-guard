-- Chat messages. Broadcasts respect the "announce" setting and each player's own switch.
local cfg = require("scripts.cfg")

local S = {}

local COLORS = {
  info = {0.6, 0.9, 1},
  ok = {0.7, 1, 0.7},
  warn = {1, 0.75, 0.2},
}

function S.all(msg, kind)
  log(msg)
  if not cfg.get("announce") then return end
  local color = COLORS[kind or "info"]
  for _, p in pairs(game.connected_players) do
    if p.mod_settings["upq-player-messages"].value then p.print(msg, {color = color}) end
  end
end

-- Answer to whoever ran a command. ctx.player is nil for the server console and RCON.
function S.reply(ctx, msg)
  if ctx.player and ctx.player.valid then
    ctx.player.print(msg)
  else
    rcon.print(msg)
    game.print(msg)
    log(msg)
  end
end

return S
