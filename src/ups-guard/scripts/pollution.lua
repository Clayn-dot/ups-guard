-- Pollution cleared where it only costs UPS. Two cases:
-- planets with no enemy nests: cleared in every pass, whether or not a player is there (nothing can use it);
-- planets with nests: only when nobody has visited for a while (pollution there feeds enemy attacks).
-- "Visited" is checked once a minute of game time. Buildings of players do not count as a visit.
local cfg = require("scripts.cfg")
local surfaces = require("scripts.surfaces")

local P = {}

function P.visit()
  storage.visited = storage.visited or {}
  for _, s in pairs(game.surfaces) do
    if not storage.visited[s.name] or surfaces.players_on(s) > 0 then storage.visited[s.name] = game.tick end
  end
end

function P.idle_hours(surface)
  local t = (storage.visited or {})[surface.name]
  return t and math.floor((game.tick - t) / 216000) or -1
end

-- True when the surface has no enemy nests. Counted now, the search stops at the first nest.
function P.quiet(surface)
  return surface.count_entities_filtered{type = "unit-spawner", force = "enemy", limit = 1} == 0
end

-- Should this surface be cleared now? auto: the mod's own pass, which follows the settings.
-- By hand (auto is false) the rules are the same, but the settings do not have to be on.
function P.due(surface, auto)
  if P.quiet(surface) then return not auto or cfg.get("pollution-clear-quiet") end
  if auto and not cfg.get("pollution-clear") then return false end
  return P.idle_hours(surface) >= cfg.get("pollution-clear-hours")
end

-- Returns the pollution that was (or would be) cleared on this surface, 0 when it was skipped
function P.clear(surface, apply, force_all, auto)
  if not surface.pollutant_type then return 0 end
  if not force_all and not P.due(surface, auto) then return 0 end
  local total = math.floor(surface.get_total_pollution())
  if total < 1 then return 0 end
  if apply then
    surface.clear_pollution()
    storage.pollution_cleared = (storage.pollution_cleared or 0) + total
  end
  return total
end

return P
