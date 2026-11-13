-- Levels and ready sets of settings. The "level" setting (minimal, medium, high, extreme) writes a whole set of settings;
-- after that every setting can still be changed by hand ("custom" stops the level from writing anything).
-- /upg preset <name> does the same from chat. "default" puts every setting back to its default.
-- Rule: what does not touch play is on early. What makes the game easier opens up step by step. What makes it harder
-- for players (asteroid spawning, robot building) is Extreme only.
local spec = require("scripts.spec")
local cfg = require("scripts.cfg")

local P = {}

P.order = {"default", "minimal", "medium", "high", "extreme"}

-- Settings that hold a list of names: a level adds its names to the list and keeps the ones you added.
local LISTS = {["protected-surfaces"] = true, ["enemy-keep-surfaces"] = true}

-- Minimal: only what players do not notice. Ground items, map trimming far from everything, planets nobody ever
-- reached, the enemy count. Equals the defaults in spec.lua. Lists every setting a higher level changes.
local MINIMAL = {
  ["protected-surfaces"] = "cerys", ["sweep-prefixes"] = "",
  ["items-enabled"] = true, ["items-radius"] = 48,
  ["trim-enabled"] = true, ["trim-buffer"] = 24, ["trim-min-chunks"] = 300,
  ["delete-fresh"] = true, ["delete-fresh-hours"] = 12, ["delete-unused"] = false, ["delete-unused-hours"] = 24,
  ["junk-enabled"] = false,
  ["freeze-enabled"] = false, ["freeze-radius"] = 1000, ["freeze-surfaces"] = "",
  ["watch-enabled"] = true, ["watch-spawners"] = 1000, ["watch-units"] = 5000,
  ["watch-thin"] = false, ["thin-radius"] = 1500, ["thin-once"] = false,
  ["trains-watch"] = false, ["calm-players"] = 0,
  ["expansion-manage"] = false, ["expansion-min"] = 20, ["expansion-max"] = 80, ["expansion-settlers"] = 12,
  ["new-planet-enabled"] = false, ["new-planet-frequency"] = 0.8, ["new-planet-size"] = 0.9, ["new-planet-starting-area"] = 2,
  ["ai-tune"] = false, ["ai-path-percent"] = 100, ["ai-groups-percent"] = 100,
  ["pollution-tune"] = false, ["pollution-diffuse-percent"] = 100,
  ["pollution-clear-quiet"] = false, ["pollution-clear"] = false, ["pollution-clear-hours"] = 6,
  ["asteroids-cap"] = 0, ["asteroids-tune"] = false, ["asteroids-percent"] = 100,
  ["build-queue-tune"] = false, ["build-queue-percent"] = 100,
}

-- Medium: noticeable savings that players hardly feel. Far enemy bases are paused on every planet (soft radius),
-- expansion is a bit slower, fire and remnants go, pollution is cleared on planets with no nests.
-- Modelled on the settings the old UPS Guard ran on a real server.
local MEDIUM = {
  ["trim-buffer"] = 16,
  ["junk-enabled"] = true,
  ["freeze-enabled"] = true, ["freeze-radius"] = 1500,
  ["trains-watch"] = true, ["calm-players"] = 12,
  ["expansion-manage"] = true,
  ["new-planet-enabled"] = true,
  ["ai-tune"] = true, ["ai-path-percent"] = 90, ["ai-groups-percent"] = 100,
  ["pollution-clear-quiet"] = true,
}

-- High: stronger limits, automatic thinning, planets that were used and left empty are deleted after a day.
local HIGH = {
  ["trim-buffer"] = 12,
  ["delete-unused"] = true, ["delete-unused-hours"] = 24,
  ["freeze-radius"] = 1000,
  ["watch-spawners"] = 800, ["watch-units"] = 4000, ["watch-thin"] = true,
  ["calm-players"] = 8,
  ["expansion-min"] = 25, ["expansion-max"] = 100, ["expansion-settlers"] = 10,
  ["new-planet-frequency"] = 0.7, ["new-planet-size"] = 0.85, ["new-planet-starting-area"] = 2.5,
  ["ai-path-percent"] = 75, ["ai-groups-percent"] = 90,
  ["pollution-tune"] = true, ["pollution-diffuse-percent"] = 200,
  ["asteroids-cap"] = 600,
}

-- Extreme: UPS over comfort. The game stays playable, but robots build slower, fewer asteroids appear,
-- pollution is cleared even where enemies live and enemies come in smaller groups.
local EXTREME = {
  ["trim-buffer"] = 8,
  ["delete-unused-hours"] = 12,
  ["freeze-radius"] = 600,
  ["watch-spawners"] = 500, ["watch-units"] = 2500, ["thin-radius"] = 1000,
  ["calm-players"] = 6,
  ["expansion-min"] = 30, ["expansion-max"] = 120, ["expansion-settlers"] = 8,
  ["new-planet-frequency"] = 0.6, ["new-planet-size"] = 0.8, ["new-planet-starting-area"] = 3,
  ["ai-path-percent"] = 50, ["ai-groups-percent"] = 60,
  ["pollution-diffuse-percent"] = 400, ["pollution-clear"] = true, ["pollution-clear-hours"] = 2,
  ["asteroids-cap"] = 400, ["asteroids-tune"] = true, ["asteroids-percent"] = 75,
  ["build-queue-tune"] = true, ["build-queue-percent"] = 75,
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
  extreme = merged(MINIMAL, MEDIUM, HIGH, EXTREME),
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

-- Settings of a level that have a different value now, as a sorted list of {key, now, new}.
-- Lists count as equal when the level's names are in them.
function P.changes(name)
  local out = {}
  if name == "default" then
    for _, row in ipairs(spec.global) do
      if cfg.get(row[1]) ~= row[3] then out[#out + 1] = {row[1], cfg.get(row[1]), row[3]} end
    end
    return out
  end
  local set = SETS[name]
  if not set then return out end
  for key, value in pairs(set) do
    local new = wanted(key, value)
    if cfg.get(key) ~= new then out[#out + 1] = {key, cfg.get(key), new} end
  end
  if cfg.get("level") ~= name then out[#out + 1] = {"level", cfg.get("level"), name} end
  table.sort(out, function(a, b) return a[1] < b[1] end)
  return out
end

-- How many settings of a level have a different value now
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
