-- The chat card at the end of a maintenance pass: only the lines that have something to say.
local cfg = require("scripts.cfg")
local U = require("scripts.util")

local K = {}

local function add_map(out, key, map)
  local total, text = U.summary(map or {})
  if total > 0 then out[#out + 1] = {key, total, text} end
end

local function enemy_text(checked)
  local names = {}
  for name in pairs(checked or {}) do
    local w = (storage.watch or {})[name]
    if w and (w.spawners > 0 or w.units > 0) then names[#names + 1] = name end
  end
  table.sort(names, function(a, b) return storage.watch[a].units > storage.watch[b].units end)
  local parts = {}
  for i = 1, math.min(#names, 5) do
    local w = storage.watch[names[i]]
    parts[#parts + 1] = names[i] .. " " .. w.spawners .. " / " .. w.units
  end
  return table.concat(parts, ", ")
end

-- c is storage.cycle; time_line is an optional extra line (profiler)
function K.lines(c, time_line)
  local out = {}
  add_map(out, "upq.card-items", c.items)
  add_map(out, "upq.card-junk", c.junk)
  add_map(out, "upq.card-trim", c.trimmed)
  add_map(out, "upq.card-pollution", c.pollution)
  add_map(out, "upq.card-asteroids", c.asteroids)
  if (c.deleted or 0) > 0 then out[#out + 1] = {"upq.card-deleted", c.deleted} end
  local enemies = enemy_text(c.checked)
  if enemies ~= "" then out[#out + 1] = {"upq.card-enemies", enemies} end
  if c.trains and c.trains.total > 0 then out[#out + 1] = {"upq.card-trains", c.trains.total} end
  if #out == 0 then out[1] = {"upq.card-quiet"} end
  if time_line then out[#out + 1] = time_line end
  out[#out + 1] = {"upq.card-next", cfg.get("cycle-hours"), cfg.get("level")}
  return out
end

return K
