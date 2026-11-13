-- One list of all mod settings. settings.lua builds the prototypes from it and the /upq commands validate values with it.
-- Row: {key, kind, default, min, max}. The real setting name is "upq-" .. key.
local M = {}

M.global = {
  -- general
  {"cycle-hours", "int", 4, 1, 48},
  {"announce", "bool", true},
  {"extra-surfaces", "string", ""},
  {"protected-surfaces", "string", ""},
  {"enemy-keep-surfaces", "string", ""},
  -- ground items
  {"items-enabled", "bool", true},
  {"items-radius", "int", 48, 0, 1000},
  {"items-surfaces", "string", ""},
  {"items-keep", "string", ""},
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
  {"freeze-enabled", "bool", false},
  {"freeze-surfaces", "string", ""},
  {"freeze-radius", "int", 1000, 300, 5000},
  {"freeze-wake-radius", "int", 320, 64, 1000},
  {"thin-once", "bool", false},
  {"thin-radius", "int", 1500, 600, 10000},
  {"sweep-prefixes", "string", ""},
  -- enemy count watch
  {"watch-enabled", "bool", true},
  {"watch-spawners", "int", 1000, 1, 1000000},
  {"watch-units", "int", 5000, 1, 10000000},
  {"watch-thin", "bool", false},
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
}

M.player = {
  {"player-messages", "bool", true},
}

local by_key = {}
for _, row in ipairs(M.global) do
  by_key[row[1]] = {key = row[1], kind = row[2], default = row[3], min = row[4], max = row[5]}
end

-- Accepts "items-radius" and "upq-items-radius". Returns a table or nil.
function M.find(name)
  name = string.lower(name or "")
  if string.sub(name, 1, 4) == "upq-" then name = string.sub(name, 5) end
  return by_key[name]
end

return M
