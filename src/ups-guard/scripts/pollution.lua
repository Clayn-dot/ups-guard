-- Pollution on planets nobody has visited for a while. The cloud keeps spreading and costs UPS even where nobody plays.
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

-- Returns the pollution that was (or would be) cleared on this surface, 0 when it was skipped
function P.clear(surface, apply, force_all)
  if not surface.pollutant_type then return 0 end
  if not force_all and P.idle_hours(surface) < cfg.get("pollution-clear-hours") then return 0 end
  local total = math.floor(surface.get_total_pollution())
  if total < 1 then return 0 end
  if apply then
    surface.clear_pollution()
    storage.pollution_cleared = (storage.pollution_cleared or 0) + total
  end
  return total
end

return P
