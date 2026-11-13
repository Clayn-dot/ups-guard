-- Admin subcommands of /upq: settings, presets, the maintenance pass, ground items, map trimming, far enemy bases.
local cfg = require("scripts.cfg")
local spec = require("scripts.spec")
local U = require("scripts.util")
local say = require("scripts.say")
local cycle = require("scripts.cycle")
local items = require("scripts.items")
local trim = require("scripts.trim")
local freeze = require("scripts.freeze")
local sweep = require("scripts.sweep")
local presets = require("scripts.presets")
local changes = require("scripts.changes")

local take_confirm = U.take_confirm

local function shown(value)
  return value == "" and "-" or tostring(value)
end

---------------------------------------------------------------- settings
local function settings_commands(reg)
  reg("set", true, function(ctx)
    local key, raw = ctx.args[1], table.concat(ctx.args, " ", 2)
    if not key or raw == "" then say.reply(ctx, {"upq.set-usage"}); return end
    local ok, value, name = cfg.set(key, raw)
    if not ok then
      local s = spec.find(key) or {}
      say.reply(ctx, {"upq.set-" .. tostring(value), key, s.min or "", s.max or ""})
      return
    end
    say.reply(ctx, {"upq.set-ok", name, shown(value)})
  end)

  reg("reset", true, function(ctx)
    local ok, value, name = cfg.reset(ctx.args[1] or "")
    if not ok then say.reply(ctx, {"upq.set-unknown", ctx.args[1] or ""}); return end
    say.reply(ctx, {"upq.set-ok", name, shown(value)})
  end)

  reg("preset", true, function(ctx)
    local name = ctx.args[1] and string.lower(ctx.args[1])
    if not name or not presets.exists(name) then
      say.reply(ctx, {"upq.preset-list"})
      for _, p in ipairs(presets.order) do say.reply(ctx, {"upq.preset-" .. p}) end
      return
    end
    local n = 0
    changes.quiet(function() n = presets.apply(name) end)
    changes.all()
    say.reply(ctx, {"upq.preset-ok", name, n})
  end)
end

---------------------------------------------------------------- the pass and the report
local function pass_commands(reg)
  reg("cycle", true, function(ctx)
    if cycle.start(ctx.player and ctx.player.index) then
      storage.minutes = 0
      say.reply(ctx, {"upq.cycle-started", cfg.get("cycle-hours")})
    else
      say.reply(ctx, {"upq.cycle-busy"})
    end
  end)

  reg("abort", true, function(ctx)
    say.reply(ctx, {"upq.cycle-aborted", cycle.abort()})
  end)

  reg("report", true, function(ctx)
    cycle.queue_report(ctx.player and ctx.player.index)
    say.reply(ctx, {"upq.report-queued"})
  end)
end

---------------------------------------------------------------- ground items and units
local function item_commands(reg)
  reg("clean", true, function(ctx)
    local apply = take_confirm(ctx.args)
    local list = cfg.command_surfaces(table.concat(ctx.args, ","), nil)
    local map = {}
    for _, s in ipairs(list) do
      local n = items.clean(s, apply)
      if n > 0 then map[s.name] = n end
    end
    local total, text = U.summary(map)
    say.reply(ctx, {apply and "upq.cleaned" or "upq.cleaned-dry", total, text})
  end)

  reg("sweep", true, function(ctx)
    if not sweep.enabled() then say.reply(ctx, {"upq.sweep-none"}); return end
    say.reply(ctx, {"upq.sweep-done", sweep.sweep(true)})
  end)
end

---------------------------------------------------------------- map and far enemy bases
local function map_commands(reg)
  reg("trim", true, function(ctx)
    local apply = take_confirm(ctx.args)
    local s = ctx.args[1] and game.get_surface(ctx.args[1])
    if not (s and cfg.eligible(s)) then say.reply(ctx, {"upq.trim-usage"}); return end
    local buffer = cfg.get("trim-buffer")
    local given = tonumber(ctx.args[2] or "")
    if given then buffer = math.max(8, math.floor(given)) end
    local r = trim.run(s, buffer, apply)
    say.reply(ctx, {apply and "upq.trim-done" or "upq.trim-dry", s.name, r.chunks, r.used, buffer, apply and r.deleted or r.doomed})
  end)

  reg("freeze", true, function(ctx)
    local list = cfg.command_surfaces(table.concat(ctx.args, ","), nil)
    say.reply(ctx, {"upq.freeze-started", freeze.start_on(list, false)})
  end)

  reg("thin", true, function(ctx)
    if not take_confirm(ctx.args) then say.reply(ctx, {"upq.thin-confirm", cfg.get("thin-radius")}); return end
    local list = cfg.command_surfaces(table.concat(ctx.args, ","), nil)
    say.reply(ctx, {"upq.thin-started", freeze.start_on(list, true)})
  end)
end

return function(reg)
  settings_commands(reg)
  pass_commands(reg)
  item_commands(reg)
  map_commands(reg)
end
