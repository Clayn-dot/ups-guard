-- UPS Guard (ups-quard): keeps a heavy multiplayer save fast. This file only wires events to the modules in scripts/.
-- All state that must survive saves and stay equal in multiplayer lives in `storage`.
local cfg = require("scripts.cfg")
local say = require("scripts.say")
local cycle = require("scripts.cycle")
local freeze = require("scripts.freeze")
local sweep = require("scripts.sweep")
local expansion = require("scripts.expansion")
local planets = require("scripts.planets")
local surfaces = require("scripts.surfaces")
local changes = require("scripts.changes")
local commands_module = require("scripts.commands")

local function startup_jobs()
  expansion.apply()
  surfaces.delete_once()
  freeze.thin_once()
  freeze.recheck(false)
end

script.on_init(function()
  cycle.init()
  -- first pass 5 game minutes after the mod is added, then every N hours
  storage.minutes = cycle.period() - 5
  say.all({"upq.installed", cfg.get("cycle-hours")}, "ok")
  startup_jobs()
end)

script.on_configuration_changed(function(data)
  cycle.init()
  local ch = data and data.mod_changes and data.mod_changes["ups-quard"]
  if ch and ch.old_version and ch.new_version and ch.old_version ~= ch.new_version then
    cycle.schedule_soon()
    say.all({"upq.updated", ch.new_version}, "ok")
  end
  startup_jobs()
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if event.setting then changes.on_setting(event.setting) end
end)

script.on_event(defines.events.on_surface_created, planets.on_surface_created)

-- Timers. Each one is cheap or works in slices.
script.on_nth_tick(15, freeze.tick)
script.on_nth_tick(30, cycle.step)
script.on_nth_tick(120, freeze.wake)
script.on_nth_tick(3600, cycle.minute)
script.on_nth_tick(3613, function()
  if sweep.enabled() then sweep.sweep(true) end
end)
-- zones are rechecked every 10 minutes of game time
script.on_nth_tick(36000, function() freeze.recheck(false) end)

commands_module.register()

-- Other mods may line up with the maintenance schedule (read-only)
remote.add_interface("ups-quard", {
  schedule = function()
    return {minutes_left = cycle.minutes_left(), period_minutes = cycle.period(), cycles = storage.cycles or 0}
  end,
})
