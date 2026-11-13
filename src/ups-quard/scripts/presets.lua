-- Ready sets of settings for /upq preset. "default" puts every setting back to its default.
-- A preset only changes the settings it lists, so presets can be stacked (heavy, then castra).
local spec = require("scripts.spec")
local cfg = require("scripts.cfg")

local P = {}

P.order = {"default", "light", "heavy", "castra"}

local SETS = {
  light = {
    ["items-enabled"] = true, ["watch-enabled"] = true,
    ["trim-enabled"] = false, ["freeze-enabled"] = false, ["watch-thin"] = false,
    ["expansion-manage"] = false, ["delete-unused"] = false,
  },
  heavy = {
    ["items-enabled"] = true, ["watch-enabled"] = true, ["watch-thin"] = true,
    ["trim-enabled"] = true, ["freeze-enabled"] = true,
    ["expansion-manage"] = true, ["new-planet-enabled"] = true,
  },
  -- for the Castra mod: its data collectors leave stuck units and its enemy bases are needed for research
  castra = {
    ["freeze-enabled"] = true, ["freeze-surfaces"] = "castra", ["thin-once"] = true,
    ["sweep-prefixes"] = "data-collector-", ["enemy-keep-surfaces"] = "castra",
  },
}

function P.exists(name)
  return name == "default" or SETS[name] ~= nil
end

-- Returns the number of settings written
function P.apply(name)
  local n = 0
  if name == "default" then
    for _, row in ipairs(spec.global) do cfg.put(row[1], row[3]); n = n + 1 end
    return n
  end
  for key, value in pairs(SETS[name]) do cfg.put(key, value); n = n + 1 end
  return n
end

return P
