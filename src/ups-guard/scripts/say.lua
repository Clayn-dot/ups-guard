-- Chat messages. Broadcasts respect the "announce" setting and each player's own switch.
-- Every broadcast starts with a coloured "UPS Guard" tag (locale upg.tag-*). A card is one message with a title and
-- several lines, so a maintenance pass appears as one block and not as a stream of lines.
local cfg = require("scripts.cfg")

local S = {}

local COLORS = {
  info = {0.78, 0.86, 0.92},
  ok = {0.8, 0.98, 0.8},
  warn = {1, 0.85, 0.5},
}

local function tagged(msg, kind)
  return {"", {"upg.tag-" .. (kind or "info")}, " ", msg}
end

local function send(msg, kind)
  log(msg)
  if not cfg.get("announce") then return end
  local color = COLORS[kind or "info"]
  for _, p in pairs(game.connected_players) do
    if p.mod_settings["upg-player-messages"].value then p.print(msg, {color = color}) end
  end
end

function S.all(msg, kind)
  send(tagged(msg, kind), kind)
end

-- A title and lines, joined with line breaks. A LocalisedString holds at most 20 parts, so long cards are nested.
function S.card(title, lines, kind)
  local body = {"", title}
  local group = body
  for _, line in ipairs(lines) do
    if #group >= 18 then
      local nxt = {""}
      group[#group + 1] = nxt
      group = nxt
    end
    group[#group + 1] = "\n"
    group[#group + 1] = line
  end
  send(tagged(body, kind), kind)
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
