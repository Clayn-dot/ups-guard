-- What to redo when a setting changes (from the settings window or from /upg set).
local expansion = require("scripts.expansion")
local surfaces = require("scripts.surfaces")
local freeze = require("scripts.freeze")
local tune = require("scripts.tune")
local presets = require("scripts.presets")
local say = require("scripts.say")
local cfg = require("scripts.cfg")

local Ch = {}

-- Writing a setting from a script raises the change event at once. While a level or a preset writes many settings,
-- the events are ignored and Ch.all() redoes everything afterwards.
local busy = false

function Ch.quiet(fn)
  local was = busy
  busy = true
  local ok, err = pcall(fn)
  busy = was
  if not ok then error(err, 0) end
end

local TUNE_PREFIXES = {"upg-ai-", "upg-pollution-tune", "upg-pollution-diffuse", "upg-asteroids-tune", "upg-asteroids-percent",
                       "upg-build-queue-"}

local function starts(name, prefix)
  return string.sub(name, 1, #prefix) == prefix
end

-- After many settings changed at once (levels and presets)
function Ch.all()
  expansion.apply()
  tune.apply()
  surfaces.delete_once()
  freeze.recheck(false, true)
  freeze.thin_once()
end

function Ch.on_setting(name)
  if busy then return end
  if name == "upg-level" then
    local level = cfg.get("level")
    if level ~= "custom" then
      local n = 0
      Ch.quiet(function() n = presets.apply(level) end)
      Ch.all()
      say.all({"upg.level-applied", level, n}, "ok")
    end
    return
  end
  if starts(name, "upg-expansion-") then expansion.apply() end
  if name == "upg-delete-once" then surfaces.delete_once() end
  if starts(name, "upg-freeze-") then freeze.recheck(false, true) end
  for _, prefix in ipairs(TUNE_PREFIXES) do
    if starts(name, prefix) then tune.apply(); break end
  end
end

return Ch
