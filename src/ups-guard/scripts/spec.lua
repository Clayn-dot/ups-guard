-- One list of all mod settings. settings.lua builds the prototypes from it and the /upq commands validate values with it.
-- Row: {key, kind, default, min, max}. The real setting name is "upq-" .. key.
-- Kind "choice": row[4] is the list of allowed values. Defaults are the "minimal" level (see presets.lua).
local M = {}

M.global = {
  -- general
  {"level", "choice", "minimal", {"minimal", "medium", "high", "custom"}},
  {"cycle-hours", "int", 4, 1, 48},
  {"announce", "bool", true},
  {"calm-players", "int", 0, 0, 200},
  {"extra-surfaces", "string", ""},
  {"protected-surfaces", "string", "castra"},
  {"enemy-keep-surfaces", "string", "castra"},
  -- ground items
  {"items-enabled", "bool", true},
  {"items-radius", "int", 48, 0, 1000},
  {"items-surfaces", "string", ""},
  {"items-keep", "string", ""},
  -- junk entities
  {"junk-enabled", "bool", false},
  {"junk-types", "string", "fire,corpse"},
  {"junk-surfaces", "string", ""},
  -- map trimming
  {"trim-enabled", "bool", false},
  {"trim-buffer", "int", 16, 8, 64},
  {"trim-min-chunks", "int", 300, 1, 1000000},
  {"trim-surfaces", "string", ""},
  -- surface deletion
  {"delete-once", "string", ""},
  {"delete-unused", "bool", false},
  {"delete-unused-hours", "int", 24, 1, 720},
  -- far enemy bases
  {"freeze-enabled", "bool", true},
  {"freeze-surfaces", "string", "castra"},
  {"freeze-radius", "int", 1000, 300, 5000},
  {"freeze-wake-radius", "int", 320, 64, 1000},
  {"thin-once", "bool", true},
  {"thin-surfaces", "string", "castra"},
  {"thin-radius", "int", 1500, 600, 10000},
  {"sweep-prefixes", "string", "data-collector-"},
  -- watch: enemy counts and trains
  {"watch-enabled", "bool", true},
  {"watch-spawners", "int", 1000, 1, 1000000},
  {"watch-units", "int", 5000, 1, 10000000},
  {"watch-thin", "bool", false},
  {"trains-watch", "bool", false},
  {"trains-limit", "int", 20, 1, 100000},
  -- expansion
  {"expansion-manage", "bool", false},
  {"expansion-min", "int", 20, 1, 1440},
  {"expansion-max", "int", 80, 1, 2880},
  {"expansion-settlers", "int", 12, 1, 100},
  -- new planets
  {"new-planet-enabled", "bool", false},
  {"new-planet-frequency", "double", 0.8, 0, 6},
  {"new-planet-size", "double", 0.9, 0, 6},
  {"new-planet-starting-area", "double", 2, 0.5, 6},
  -- map settings (all in percent of the value the game had before the mod touched it)
  {"ai-tune", "bool", false},
  {"ai-path-percent", "int", 100, 10, 200},
  {"ai-groups-percent", "int", 100, 10, 200},
  {"pollution-tune", "bool", false},
  {"pollution-diffuse-percent", "int", 100, 100, 2000},
  {"asteroids-tune", "bool", false},
  {"asteroids-percent", "int", 100, 0, 200},
  {"build-queue-tune", "bool", false},
  {"build-queue-percent", "int", 100, 20, 100},
  -- pollution on empty planets, asteroids around platforms
  {"pollution-clear", "bool", false},
  {"pollution-clear-hours", "int", 6, 1, 720},
  {"pollution-surfaces", "string", ""},
  {"asteroids-cap", "int", 0, 0, 100000},
}

M.player = {
  {"player-messages", "bool", true},
}

local by_key = {}
for _, row in ipairs(M.global) do
  by_key[row[1]] = {key = row[1], kind = row[2], default = row[3], min = row[4], max = row[5]}
  if row[2] == "choice" then
    by_key[row[1]].allowed, by_key[row[1]].min, by_key[row[1]].max = row[4], nil, nil
  end
end

-- Accepts "items-radius" and "upq-items-radius". Returns a table or nil.
function M.find(name)
  name = string.lower(name or "")
  if string.sub(name, 1, 4) == "upq-" then name = string.sub(name, 5) end
  return by_key[name]
end

return M
