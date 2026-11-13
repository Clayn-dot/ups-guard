-- Enemy expansion pace. The values from before the mod touched them are saved and put back when
-- "expansion-manage" is switched off.
local cfg = require("scripts.cfg")

local X = {}

local function remember(x)
  if storage.expansion_backup then return end
  storage.expansion_backup = {
    min = x.min_expansion_cooldown, max = x.max_expansion_cooldown,
    settlers_min = x.settler_group_min_size, settlers_max = x.settler_group_max_size,
  }
end

function X.apply()
  local x = game.map_settings.enemy_expansion
  if not cfg.get("expansion-manage") then
    local b = storage.expansion_backup
    if b then
      x.min_expansion_cooldown, x.max_expansion_cooldown = b.min, b.max
      x.settler_group_min_size, x.settler_group_max_size = b.settlers_min, b.settlers_max
      storage.expansion_backup = nil
    end
    return
  end
  remember(x)
  local mn = cfg.get("expansion-min") * 3600
  x.min_expansion_cooldown = mn
  x.max_expansion_cooldown = math.max(cfg.get("expansion-max") * 3600, mn)
  x.settler_group_max_size = cfg.get("expansion-settlers")
  if x.settler_group_min_size > x.settler_group_max_size then
    x.settler_group_min_size = x.settler_group_max_size
  end
end

return X
