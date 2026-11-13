-- Items lying on the ground. Items near players, marked for deconstruction, or named in "items-keep" stay.
local cfg = require("scripts.cfg")

local I = {}

local function player_points(surface)
  local points = {}
  for _, p in pairs(game.connected_players) do
    if p.surface.index == surface.index then points[#points + 1] = p.position end
    if p.physical_surface.index == surface.index and p.physical_surface.index ~= p.surface.index then
      points[#points + 1] = p.physical_position
    end
  end
  return points
end

local function near_any(points, pos, r2)
  for i = 1, #points do
    local dx, dy = pos.x - points[i].x, pos.y - points[i].y
    if dx * dx + dy * dy <= r2 then return true end
  end
  return false
end

-- Returns how many items were removed (or would be, when apply is false)
function I.clean(surface, apply)
  local radius = cfg.get("items-radius")
  local r2 = radius * radius
  local points = player_points(surface)
  local keep = cfg.set_of("items-keep") or {}
  local n = 0
  for _, e in pairs(surface.find_entities_filtered{type = "item-entity"}) do
    if e.valid and not e.to_be_deconstructed() and not keep[e.stack.name] and not near_any(points, e.position, r2) then
      if apply then e.destroy() end
      n = n + 1
    end
  end
  if apply then storage.items_removed = (storage.items_removed or 0) + n end
  return n
end

return I
