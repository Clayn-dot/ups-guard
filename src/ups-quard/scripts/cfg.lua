-- Reading and writing the mod settings, and choosing which surfaces a job works on.
local spec = require("scripts.spec")
local U = require("scripts.util")

local C = {}

function C.get(key)
  return settings.global["upq-" .. key].value
end

function C.set_of(key)
  return U.parse_list(C.get(key))
end

-- A surface the mod may treat like a planet: not a platform, and a planet, nauvis, or listed in "extra-surfaces".
function C.eligible(surface)
  if not (surface and surface.valid) or surface.platform then return false end
  if surface.planet or surface.index == 1 then return true end
  return (C.set_of("extra-surfaces") or {})[surface.name] == true
end

function C.protected(surface)
  return (C.set_of("protected-surfaces") or {})[surface.name] == true
end

-- Surfaces for an automatic job: eligible, inside the include list (empty list = all), optionally not protected.
function C.auto_surfaces(include_key, honor_protected)
  local only = include_key and C.set_of(include_key) or nil
  local out = {}
  for _, s in pairs(game.surfaces) do
    if C.eligible(s) and (not only or only[s.name]) and not (honor_protected and C.protected(s)) then
      out[#out + 1] = s
    end
  end
  table.sort(out, function(a, b) return a.index < b.index end)
  return out
end

-- Surfaces for a command. Names in the text are used as given (even protected ones); without names the
-- default is every eligible surface except the ones in the skip setting.
function C.command_surfaces(text, skip_key)
  local named = U.parse_list(text)
  local skip = (not named and skip_key and C.set_of(skip_key)) or {}
  local out = {}
  for _, s in pairs(game.surfaces) do
    if C.eligible(s) and (not named or named[s.name]) and not skip[s.name] then out[#out + 1] = s end
  end
  table.sort(out, function(a, b) return a.index < b.index end)
  return out, named ~= nil
end

local WORDS = {on = true, ["true"] = true, yes = true, ["1"] = true,
                off = false, ["false"] = false, no = false, ["0"] = false}

local function parse_value(row, raw)
  if row.kind == "bool" then
    local v = WORDS[string.lower(raw)]
    if v == nil then return nil, "bad" end
    return v
  end
  local n = tonumber(raw)
  if not n then return nil, "bad" end
  if row.kind == "int" then n = math.floor(n + 0.5) end
  if (row.min and n < row.min) or (row.max and n > row.max) then return nil, "range" end
  return n
end

local function edit_list(current, raw)
  if raw == "-" then return "" end
  local op, name = string.sub(raw, 1, 1), string.sub(raw, 2)
  if (op == "+" or op == "-") and name ~= "" then
    local set = U.parse_list(current) or {}
    set[name] = (op == "+") or nil
    return U.list_text(set)
  end
  return raw
end

-- Writes a value that is already valid (presets, defaults)
function C.put(key, value)
  settings.global["upq-" .. key] = {value = value}
end

-- Returns true, value, setting name on success, or nil, "unknown" | "bad" | "range"
function C.set(key, raw)
  local row = spec.find(key)
  if not row then return nil, "unknown" end
  local value, err
  if row.kind == "string" then
    value = edit_list(C.get(row.key), raw)
  else
    value, err = parse_value(row, raw)
    if value == nil then return nil, err end
  end
  C.put(row.key, value)
  return true, value, "upq-" .. row.key
end

function C.reset(key)
  local row = spec.find(key)
  if not row then return nil, "unknown" end
  C.put(row.key, row.default)
  return true, row.default, "upq-" .. row.key
end

return C
