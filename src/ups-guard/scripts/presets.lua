-- Levels and ready sets of settings. The "level" setting (minimal, medium, high) writes a whole set of settings;
-- after that every setting can still be changed by hand ("custom" stops the level from writing anything).
-- /upg preset <name> does the same from chat. "default" puts every setting back to its default.
local spec = require("scripts.spec")
local cfg = require("scripts.cfg")

local P = {}

P.order = {"default", "minimal", "medium", "high"}

-- Settings that hold a list of names: a level adds its names to the list and keeps the ones you added.
local LISTS = {["protected-surfaces"] = true, ["enemy-keep-surfaces"] = true}

-- Minimal: ground items and the enemy count. Everything else is off. Equals the defaults in spec.lua.
local MINIMAL = {
  ["protected-surfaces"] = "cerys", ["freeze-enabled"] = false, ["thin-once"] = false, ["sweep-prefixes"] = "",
  ["items-enabled"] = true, ["watch-enabled"] = true, ["calm-players"] = 0,
  ["junk-enabled"] = false, ["trim-enabled"] = false, ["delete-unused"] = false, ["delete-unused-hours"] = 24,
  ["watch-thin"] = false, ["trains-watch"] = false,
  ["expansion-manage"] = false, ["expansion-min"] = 20, ["expansion-max"] = 80, ["expansion-settlers"] = 12,
  ["new-planet-enabled"] = false,
  ["ai-tune"] = false, ["ai-path-percent"] = 100, ["ai-groups-percent"] = 100,
  ["pollution-tune"] = false, ["pollution-diffuse-percent"] = 100, ["pollution-clear"] = false, ["pollution-clear-hours"] = 6,
  ["asteroids-tune"] = false, ["asteroids-percent"] = 100, ["asteroids-cap"] = 0,
  ["build-queue-tune"] = false, ["build-queue-percent"] = 100,
}

-- Medium: noticeable savings that players hardly feel. Far enemy bases are paused on every planet, expansion is slower,
-- fire and remnants go, pollution is cleared on empty planets, asteroids and enemy pathfinding are lowered a little.
local MEDIUM = {
  ["freeze-enabled"] = true, ["freeze-surfaces"] = "",
  ["junk-enabled"] = true, ["pollution-clear"] = true, ["trains-watch"] = true, ["calm-players"] = 12,
  ["expansion-manage"] = true,
  ["ai-tune"] = true, ["ai-path-percent"] = 80, ["ai-groups-percent"] = 80,
  ["asteroids-tune"] = true, ["asteroids-percent"] = 75, ["asteroids-cap"] = 600,
}

-- High: the serious one. Adds trimming of far empty map, automatic thinning, deleting planets nobody uses,
-- slower expansion, stronger limits on enemy pathfinding, pollution spreading, asteroids and robot building.
local HIGH = {
  ["trim-enabled"] = true, ["watch-thin"] = true, ["new-planet-enabled"] = true,
  ["delete-unused"] = true, ["delete-unused-hours"] = 48, ["calm-players"] = 6,
  ["expansion-min"] = 30, ["expansion-max"] = 120, ["expansion-settlers"] = 8,
  ["ai-path-percent"] = 50, ["ai-groups-percent"] = 50,
  ["pollution-tune"] = true, ["pollution-diffuse-percent"] = 400, ["pollution-clear-hours"] = 2,
  ["asteroids-percent"] = 50, ["asteroids-cap"] = 250,
  ["build-queue-tune"] = true, ["build-queue-percent"] = 67,
}

local function merged(...)
  local out = {}
  for _, t in ipairs({...}) do
    for k, v in pairs(t) do out[k] = v end
  end
  return out
end

local SETS = {
  minimal = merged(MINIMAL),
  medium = merged(MINIMAL, MEDIUM),
  high = merged(MINIMAL, MEDIUM, HIGH),
}
P.sets = SETS

function P.exists(name)
  return name == "default" or SETS[name] ~= nil
end

local function wanted(key, value)
  if LISTS[key] and value ~= "" then
    local have = cfg.set_of(key) or {}
    for name in string.gmatch(value, "[^,%s]+") do have[name] = true end
    local names = {}
    for name in pairs(have) do names[#names + 1] = name end
    table.sort(names)
    return table.concat(names, ",")
  end
  return value
end

-- Returns the number of settings written
function P.apply(name)
  local n = 0
  if name == "default" then
    for _, row in ipairs(spec.global) do cfg.put(row[1], row[3]); n = n + 1 end
    return n
  end
  for key, value in pairs(SETS[name]) do cfg.put(key, wanted(key, value)); n = n + 1 end
  cfg.put("level", name)
  return n
end

-- How many settings of a level have a different value now (lists count as equal when the level's names are in them)
function P.diff(name)
  local set = SETS[name]
  if not set then return 0 end
  local n = 0
  for key, value in pairs(set) do
    if cfg.get(key) ~= wanted(key, value) then n = n + 1 end
  end
  return n
end

return P
