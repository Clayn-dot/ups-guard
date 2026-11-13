-- Subcommands of /upg for the newer cleanups: junk, pollution, space platform asteroids, trains without a path, profile.
local cfg = require("scripts.cfg")
local U = require("scripts.util")
local say = require("scripts.say")
local junk = require("scripts.junk")
local pollution = require("scripts.pollution")
local platforms = require("scripts.platforms")
local trains = require("scripts.trains")

local take_confirm = U.take_confirm

local function junk_command(ctx)
  local apply = take_confirm(ctx.args)
  if #junk.types() == 0 then say.reply(ctx, {"upg.junk-none"}); return end
  local map = {}
  for _, s in ipairs((cfg.command_surfaces(table.concat(ctx.args, ","), nil))) do
    for t, n in pairs(junk.clean(s, apply)) do map[t] = (map[t] or 0) + n end
  end
  local total, text = U.summary(map)
  say.reply(ctx, {apply and "upg.junk-done" or "upg.junk-dry", total, text})
end

local function pollution_command(ctx)
  local apply = take_confirm(ctx.args)
  local list, named = cfg.command_surfaces(table.concat(ctx.args, ","), nil)
  for _, s in ipairs(list) do
    if s.pollutant_type then
      local n = pollution.clear(s, apply, named)
      say.reply(ctx, {"upg.pollution-line", s.name, math.floor(s.get_total_pollution()), pollution.idle_hours(s), n, tostring(apply)})
    end
  end
end

local function platforms_command(ctx)
  local apply = take_confirm(ctx.args)
  local limit = cfg.get("asteroids-cap")
  for _, s in ipairs(platforms.platform_surfaces()) do
    local count = platforms.count(s)
    local extra = platforms.cap(s, apply)
    say.reply(ctx, {"upg.platform-line", s.platform.name, count, limit, extra, tostring(apply)})
  end
end

local function trains_command(ctx)
  local st = trains.stuck()
  say.reply(ctx, {"upg.trains-head", st.total})
  for _, row in ipairs(st.sample) do say.reply(ctx, {"upg.trains-line", row[1], row[2], row[3]}) end
end

local function profile_command(ctx)
  local arg = ctx.args[1] and string.lower(ctx.args[1])
  if arg == "on" or arg == "off" then storage.profile = (arg == "on") or nil end
  say.reply(ctx, {storage.profile and "upg.profile-on" or "upg.profile-off"})
end

return function(reg)
  reg("junk", true, junk_command)
  reg("pollution", true, pollution_command)
  reg("platforms", true, platforms_command)
  reg("trains", false, trains_command)
  reg("profile", true, profile_command)
end
