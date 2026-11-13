-- Counts nests and enemy units per surface and compares them with the limits.
local cfg = require("scripts.cfg")

local W = {}

-- One surface: store the counts. Returns nothing.
function W.count(surface)
  storage.watch = storage.watch or {}
  storage.watch[surface.name] = {
    spawners = surface.count_entities_filtered{type = "unit-spawner", force = "enemy"},
    units = surface.count_entities_filtered{type = "unit", force = "enemy"},
    tick = game.tick,
  }
end

function W.over_limit(name)
  local w = (storage.watch or {})[name]
  if not w then return false end
  return w.spawners > cfg.get("watch-spawners") or w.units > cfg.get("watch-units")
end

return W
