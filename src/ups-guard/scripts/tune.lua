-- Game-wide numbers the mod can lower to save UPS: enemy pathfinding and attack groups, pollution spreading, asteroid
-- spawning, robot building. Each value is a percent of what the game had before the mod touched it. The old values are
-- saved and put back when the switch is turned off.
local cfg = require("scripts.cfg")

local T = {}

local function ms(name)
  return function() return game.map_settings[name] end
end

-- {switch, setting that holds the percent, object, field, integer?}
local ROWS = {
  {"ai-tune", "ai-path-percent", ms("path_finder"), "max_work_done_per_tick", true},
  {"ai-tune", "ai-path-percent", ms("path_finder"), "max_steps_worked_per_tick", false},
  {"ai-tune", "ai-groups-percent", ms("unit_group"), "max_gathering_unit_groups", true},
  {"ai-tune", "ai-groups-percent", ms("unit_group"), "max_unit_group_size", true},
  {"pollution-tune", "pollution-diffuse-percent", ms("pollution"), "min_to_diffuse", false},
  {"asteroids-tune", "asteroids-percent", ms("asteroids"), "spawning_rate", false},
}

local function scaled(base, percent, integer)
  local v = base * percent / 100
  if integer then return math.max(1, math.floor(v + 0.5)) end
  return v
end

local function apply_row(row)
  local switch, pct_key, get, field, integer = row[1], row[2], row[3], row[4], row[5]
  local obj = get()
  storage.tune_backup = storage.tune_backup or {}
  local id = switch .. "." .. field
  if cfg.get(switch) then
    if storage.tune_backup[id] == nil then storage.tune_backup[id] = obj[field] end
    obj[field] = scaled(storage.tune_backup[id], cfg.get(pct_key), integer)
  elseif storage.tune_backup[id] ~= nil then
    obj[field] = storage.tune_backup[id]
    storage.tune_backup[id] = nil
  end
end

local function player_forces()
  local out = {}
  for _, f in pairs(game.forces) do
    if f.name ~= "enemy" and f.name ~= "neutral" then out[#out + 1] = f end
  end
  return out
end

-- Building speed of robots: how many ghosts a construction queue tries to build per tick
local function apply_queues()
  storage.queue_backup = storage.queue_backup or {}
  local on, pct = cfg.get("build-queue-tune"), cfg.get("build-queue-percent")
  for _, f in ipairs(player_forces()) do
    local b = storage.queue_backup[f.name]
    if on then
      if not b then
        b = {ok = f.max_successful_attempts_per_tick_per_construction_queue}
        storage.queue_backup[f.name] = b
      end
      f.max_successful_attempts_per_tick_per_construction_queue = scaled(b.ok, pct, true)
    elseif b then
      f.max_successful_attempts_per_tick_per_construction_queue = b.ok
      storage.queue_backup[f.name] = nil
    end
  end
end

function T.apply()
  for _, row in ipairs(ROWS) do apply_row(row) end
  apply_queues()
end

-- Names of the values the mod holds right now, for /upg status
function T.active()
  local out = {}
  for id in pairs(storage.tune_backup or {}) do out[#out + 1] = id end
  table.sort(out)
  return out
end

return T
