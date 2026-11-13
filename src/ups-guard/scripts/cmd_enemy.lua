-- /upg enemies <artillery|near|reset>: bulk enemy removal. Without the word "confirm" it only counts.
-- Without surface names it works on every planet except the ones in "enemy-keep-surfaces".
local cfg = require("scripts.cfg")
local U = require("scripts.util")
local say = require("scripts.say")
local enemies = require("scripts.enemies")

local ACTIONS = {}

-- args after the action: [number] [surface names...]. Returns number, surfaces
local function parse(ctx, default, lo, hi)
  local args = {}
  for i = 2, #ctx.args do args[#args + 1] = ctx.args[i] end
  local n = default
  local given = tonumber(args[1] or "")
  if default and given then
    n = math.min(hi, math.max(lo, math.floor(given)))
    table.remove(args, 1)
  end
  local list = cfg.command_surfaces(table.concat(args, ","), "enemy-keep-surfaces")
  return n, list
end

function ACTIONS.artillery(ctx, apply)
  local _, list = parse(ctx)
  local r = enemies.artillery(ctx.force, list, apply)
  local _, text = U.summary(r.per)
  say.reply(ctx, {apply and "upg.artillery-done" or "upg.artillery-dry", r.guns, math.floor(r.max_r), r.count, text, r.charted})
end

function ACTIONS.near(ctx, apply)
  local tiles, list = parse(ctx, 800, 64, 5000)
  local total, per = enemies.near(ctx.force, tiles, list, apply)
  local _, text = U.summary(per)
  say.reply(ctx, {apply and "upg.near-done" or "upg.near-dry", tiles, total, text})
end

function ACTIONS.reset(ctx, apply)
  local keep, list = parse(ctx, 6, 0, 50)
  local removed, placed, report = enemies.reset(ctx.force, keep, list, apply)
  say.reply(ctx, {apply and "upg.reset-done" or "upg.reset-dry", removed, placed, report})
end

return function(reg)
  reg("enemies", true, function(ctx)
    local apply = U.take_confirm(ctx.args)
    local action = ACTIONS[string.lower(ctx.args[1] or "")]
    if not action then say.reply(ctx, {"upg.enemies-usage"}); return end
    action(ctx, apply)
    if not apply then say.reply(ctx, {"upg.confirm-hint"}) end
  end)
end
