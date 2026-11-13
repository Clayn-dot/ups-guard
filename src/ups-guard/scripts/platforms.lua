-- Asteroids around space platforms. They pile up when a platform sits still or has weak defence, and every one costs
-- UPS. Over the limit the ones farthest from the hub are removed. Platforms are never deleted or paused.
local cfg = require("scripts.cfg")

local A = {}

function A.count(surface)
  return surface.count_entities_filtered{type = "asteroid"}
end

-- Returns how many asteroids were removed (or would be, when apply is false)
function A.cap(surface, apply)
  local limit = cfg.get("asteroids-cap")
  if limit <= 0 or not surface.platform then return 0 end
  local list = surface.find_entities_filtered{type = "asteroid"}
  local extra = #list - limit
  if extra <= 0 then return 0 end
  local hub = surface.platform.hub
  local cx, cy = hub and hub.position.x or 0, hub and hub.position.y or 0
  local keyed = {}
  for i, e in ipairs(list) do
    local dx, dy = e.position.x - cx, e.position.y - cy
    keyed[i] = {e, dx * dx + dy * dy}
  end
  table.sort(keyed, function(a, b) return a[2] > b[2] end)
  if apply then
    for i = 1, extra do
      if keyed[i][1].valid then keyed[i][1].destroy() end
    end
    storage.asteroids_removed = (storage.asteroids_removed or 0) + extra
  end
  return extra
end

function A.platform_surfaces()
  local out = {}
  for _, s in pairs(game.surfaces) do
    if s.platform and s.valid then out[#out + 1] = s end
  end
  table.sort(out, function(a, b) return a.index < b.index end)
  return out
end

return A
