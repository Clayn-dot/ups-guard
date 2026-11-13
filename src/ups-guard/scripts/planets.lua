-- Enemy settings for planets generated for the first time (event on_surface_created).
local cfg = require("scripts.cfg")
local say = require("scripts.say")

local P = {}

local function adjust(map_gen, f, z, sa)
  local touched = false
  for name, c in pairs(map_gen.autoplace_controls or {}) do
    if string.find(name, "enemy") then
      c.frequency = (c.frequency or 1) * f
      c.size = (c.size or 1) * z
      touched = true
    end
  end
  map_gen.starting_area = (tonumber(map_gen.starting_area) or 1) * sa
  return touched
end

function P.on_surface_created(event)
  if not cfg.get("new-planet-enabled") then return end
  local s = game.get_surface(event.surface_index)
  if not (s and s.valid and s.planet) then return end
  local f, z, sa = cfg.get("new-planet-frequency"), cfg.get("new-planet-size"), cfg.get("new-planet-starting-area")
  local ok, touched = pcall(function()
    local m = s.map_gen_settings
    local t = adjust(m, f, z, sa)
    s.map_gen_settings = m
    return t
  end)
  if ok then
    say.all({"upg.new-planet", s.name, f, z, sa, touched and "" or "?"}, "ok")
  else
    log("ups-guard: could not adjust map generation on " .. s.name)
  end
end

return P
