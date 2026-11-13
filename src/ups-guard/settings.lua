local spec = require("scripts.spec")

local PROTO = {int = "int-setting", double = "double-setting", bool = "bool-setting", string = "string-setting",
               choice = "string-setting"}

local function build(rows, setting_type, first)
  local out = {}
  for i, row in ipairs(rows) do
    local p = {
      type = PROTO[row[2]],
      name = "upg-" .. row[1],
      setting_type = setting_type,
      default_value = row[3],
      order = string.format("%03d", first + i),
    }
    if row[2] == "string" then p.allow_blank = true end
    if row[2] == "choice" then
      p.allowed_values = row[4]
    else
      if row[4] then p.minimum_value = row[4] end
      if row[5] then p.maximum_value = row[5] end
    end
    out[#out + 1] = p
  end
  return out
end

data:extend(build(spec.global, "runtime-global", 0))
data:extend(build(spec.player, "runtime-per-user", 0))
