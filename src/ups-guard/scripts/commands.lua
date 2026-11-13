-- The /upq command: one root, many subcommands. Everyone can use the read-only ones; the rest need an admin
-- (the server console and RCON count as admin). Admin and enemy/surface subcommands live in cmd_*.lua files.
local cfg = require("scripts.cfg")
local spec = require("scripts.spec")
local U = require("scripts.util")
local say = require("scripts.say")
local cycle = require("scripts.cycle")
local surfaces = require("scripts.surfaces")
local presets = require("scripts.presets")
local tune = require("scripts.tune")

local M = {}

local registry, order = {}, {}

-- reg(name, admin_only, function(ctx))   ctx = {player, force, args}
local function reg(name, admin, fn)
  registry[name] = {admin = admin, run = fn}
  order[#order + 1] = name
end

---------------------------------------------------------------- read-only commands
local STAGES = {scan = "scan", protect = "protect", check = "check", delete = "delete"}

local function status_progress(ctx)
  local queue = #storage.jobs
  local pr = storage.progress
  if storage.cycle and pr then
    say.reply(ctx, {"upq.status-progress", pr.surface, STAGES[pr.stage] or pr.stage, math.max(0, (pr.i or 1) - 1), pr.n or 0, queue})
  elseif queue > 0 then
    say.reply(ctx, {"upq.status-queue", queue})
  end
end

local function status_extra(ctx)
  local names = {}
  for name in pairs(storage.freeze_stats or {}) do names[#names + 1] = name end
  table.sort(names)
  for _, name in ipairs(names) do
    local f = storage.freeze_stats[name]
    say.reply(ctx, {"upq.status-freeze", name, f.frozen, U.minutes_since(f.tick)})
  end
  names = {}
  for name in pairs(storage.watch or {}) do names[#names + 1] = name end
  table.sort(names)
  for _, name in ipairs(names) do
    local w = storage.watch[name]
    say.reply(ctx, {"upq.status-watch", name, w.spawners, w.units, U.minutes_since(w.tick)})
  end
end

reg("status", false, function(ctx)
  say.reply(ctx, {"upq.status", storage.items_removed or 0, cfg.get("cycle-hours"), cycle.minutes_left()})
  local level = cfg.get("level")
  say.reply(ctx, {"upq.status-level", level, presets.diff(level), #tune.active()})
  local junk_n, poll_n, ast_n = storage.junk_removed or 0, storage.pollution_cleared or 0, storage.asteroids_removed or 0
  if junk_n + poll_n + ast_n > 0 then say.reply(ctx, {"upq.status-removed", junk_n, poll_n, ast_n}) end
  status_progress(ctx)
  local x = game.map_settings.enemy_expansion
  say.reply(ctx, {"upq.status-expansion", math.floor(x.min_expansion_cooldown / 3600),
    math.floor(x.max_expansion_cooldown / 3600), x.settler_group_max_size, tostring(cfg.get("expansion-manage"))})
  if (storage.loot_swept or 0) > 0 then say.reply(ctx, {"upq.status-sweep", storage.loot_swept}) end
  if (storage.surfaces_deleted or 0) > 0 then say.reply(ctx, {"upq.status-deleted", storage.surfaces_deleted}) end
  status_extra(ctx)
end)

local function num(n)
  return n < 0 and "?" or tostring(n)
end

reg("surfaces", false, function(ctx)
  for _, i in ipairs(surfaces.overview()) do
    say.reply(ctx, {"upq.surface-line", i.name, i.kind, i.chunks, i.players, num(i.spawners), num(i.units)})
  end
end)

reg("config", false, function(ctx)
  local filter = ctx.args[1] and string.lower(ctx.args[1])
  for _, row in ipairs(spec.global) do
    if not filter or string.find(row[1], filter, 1, true) then
      local v = cfg.get(row[1])
      say.reply(ctx, "upq-" .. row[1] .. " = " .. (v == "" and "-" or tostring(v)))
    end
  end
end)

reg("messages", false, function(ctx)
  if not ctx.player then return end
  local arg = ctx.args[1] and string.lower(ctx.args[1])
  if arg == "on" or arg == "off" then
    ctx.player.mod_settings["upq-player-messages"] = {value = (arg == "on")}
  end
  say.reply(ctx, {ctx.player.mod_settings["upq-player-messages"].value and "upq.messages-on" or "upq.messages-off"})
end)

reg("help", false, function(ctx)
  say.reply(ctx, {"upq.help-header"})
  for _, name in ipairs(order) do
    local e = registry[name]
    if not e.admin or not ctx.player or ctx.player.admin then
      say.reply(ctx, {"upq.help-" .. name})
    end
  end
end)

---------------------------------------------------------------- dispatcher
local function handler(cmd)
  local player = cmd.player_index and game.get_player(cmd.player_index) or nil
  local words = U.words(cmd.parameter)
  local name = string.lower(table.remove(words, 1) or "help")
  local ctx = {player = player, args = words,
               force = player and player.force or game.forces["player"]}
  local entry = registry[name]
  if not entry then say.reply(ctx, {"upq.unknown-command", name}); return end
  if entry.admin and player and not player.admin then say.reply(ctx, {"upq.admin-only"}); return end
  entry.run(ctx)
end

function M.register()
  require("scripts.cmd_admin")(reg)
  require("scripts.cmd_enemy")(reg)
  require("scripts.cmd_surface")(reg)
  require("scripts.cmd_tools")(reg)
  commands.add_command("upq", {"upq.help-short"}, handler)
end

return M
