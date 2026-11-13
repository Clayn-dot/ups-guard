-- Removes enemy units whose prototype name starts with a listed prefix (setting "sweep-prefixes").
-- Some mods spawn short-lived "units" that should turn into items at once (Castra data collectors do this);
-- when some slip through they pile up by the thousand and eat UPS. Never used on real enemies unless named.
local cfg = require("scripts.cfg")
local U = require("scripts.util")

local W = {}

local cache = {key = nil, names = {}}

local function names_for(text)
  if cache.key == text then return cache.names end
  local prefixes = {}
  for p in string.gmatch(text, "[^,%s]+") do prefixes[#prefixes + 1] = p end
  local names = {}
  for name, proto in pairs(prototypes.entity) do
    if proto.type == "unit" then
      for _, p in ipairs(prefixes) do
        if string.sub(name, 1, #p) == p then names[#names + 1] = name; break end
      end
    end
  end
  cache = {key = text, names = names}
  return names
end

-- Returns how many units were removed (or would be, when apply is false)
function W.sweep(apply)
  local text = cfg.get("sweep-prefixes")
  local names = names_for(text)
  if #names == 0 then return 0 end
  local total = 0
  for _, s in pairs(game.surfaces) do
    if cfg.eligible(s) then
      if apply then
        for _, e in pairs(s.find_entities_filtered{name = names, force = "enemy"}) do
          if e.valid then e.destroy(); total = total + 1 end
        end
      else
        total = total + s.count_entities_filtered{name = names, force = "enemy"}
      end
    end
  end
  if apply then storage.loot_swept = (storage.loot_swept or 0) + total end
  return total
end

function W.enabled()
  return U.parse_list(cfg.get("sweep-prefixes")) ~= nil
end

return W
