-- Trains that cannot find a path. They ask for a path again and again, which costs UPS on a big rail network.
-- The mod only counts and names them; fixing the schedule is up to you.
local cfg = require("scripts.cfg")

local Tr = {}

-- Returns {total = n, surfaces = {name = n}, sample = {{id, surface, station}}} (sample is at most 10 trains)
function Tr.stuck()
  local out = {total = 0, surfaces = {}, sample = {}}
  for _, t in pairs(game.train_manager.get_trains{}) do
    if t.valid and t.state == defines.train_state.no_path then
      local stock = t.front_stock
      local name = stock and stock.valid and stock.surface.name or "?"
      out.total = out.total + 1
      out.surfaces[name] = (out.surfaces[name] or 0) + 1
      if #out.sample < 10 then
        local sch = t.schedule
        local rec = sch and sch.records and sch.records[sch.current]
        out.sample[#out.sample + 1] = {t.id, name, rec and rec.station or "-"}
      end
    end
  end
  return out
end

function Tr.over_limit(stuck)
  return stuck.total > cfg.get("trains-limit")
end

return Tr
