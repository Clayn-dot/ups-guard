-- Junk entities: fire, remnants, and (only if you list them) ghosts. Only the types below can be chosen, so the setting
-- can never delete buildings. Nothing within "items-radius" of a player is touched.
local cfg = require("scripts.cfg")
local items = require("scripts.items")

local J = {}

local ALLOWED = {fire = true, corpse = true, ["entity-ghost"] = true}
J.allowed = {"corpse", "entity-ghost", "fire"}

-- Types from the setting that are allowed
function J.types()
  local out = {}
  for t in pairs(cfg.set_of("junk-types") or {}) do
    if ALLOWED[t] then out[#out + 1] = t end
  end
  table.sort(out)
  return out
end

-- Returns {type = count} of what was removed (or would be, when apply is false)
function J.clean(surface, apply)
  local r = cfg.get("items-radius")
  local points = items.player_points(surface)
  local result = {}
  for _, t in ipairs(J.types()) do
    local n = 0
    for _, e in pairs(surface.find_entities_filtered{type = t}) do
      if e.valid and not items.near_any(points, e.position, r * r) then
        if apply then e.destroy() end
        n = n + 1
      end
    end
    if n > 0 then result[t] = n end
  end
  if apply then
    local total = 0
    for _, n in pairs(result) do total = total + n end
    storage.junk_removed = (storage.junk_removed or 0) + total
  end
  return result
end

return J
