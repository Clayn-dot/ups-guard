-- Small helpers without game state: lists, counters, and the bucket index used for "is this chunk near something".
local U = {}

-- "a, b c" -> {a = true, b = true, c = true}; nil when there are no names
function U.parse_list(text)
  local set, any = {}, false
  for name in string.gmatch(text or "", "[^,%s]+") do set[name] = true; any = true end
  return any and set or nil
end

function U.list_text(set)
  local names = {}
  for name in pairs(set or {}) do names[#names + 1] = name end
  table.sort(names)
  return table.concat(names, ",")
end

function U.words(text)
  local out = {}
  for w in string.gmatch(text or "", "%S+") do out[#out + 1] = w end
  return out
end

-- Removes the word "confirm" from the list. Returns true if it was there.
function U.take_confirm(args)
  for i = #args, 1, -1 do
    if string.lower(args[i]) == "confirm" then table.remove(args, i); return true end
  end
  return false
end

-- {name = count} -> total, "name n, name n" sorted by count
function U.summary(map)
  local names, total = {}, 0
  for name, n in pairs(map) do names[#names + 1] = name; total = total + n end
  table.sort(names, function(a, b)
    if map[a] ~= map[b] then return map[a] > map[b] end
    return a < b
  end)
  local parts = {}
  for _, name in ipairs(names) do parts[#parts + 1] = name .. " " .. map[name] end
  return total, table.concat(parts, ", ")
end

function U.minutes_since(tick)
  return math.floor((game.tick - (tick or game.tick)) / 3600)
end

function U.chunk_area(x, y)
  return {{x * 32, y * 32}, {x * 32 + 32, y * 32 + 32}}
end

-- Buckets: a square reach around a point is stored in 16x16 chunk cells, so a lookup touches one cell only.
local BUCKET = 16

function U.bucket_add(b, x, y, r)
  local e = {x, y, r}
  for bx = math.floor((x - r) / BUCKET), math.floor((x + r) / BUCKET) do
    for by = math.floor((y - r) / BUCKET), math.floor((y + r) / BUCKET) do
      local k = bx .. ":" .. by
      local l = b[k]
      if not l then l = {}; b[k] = l end
      l[#l + 1] = e
    end
  end
end

function U.is_protected(b, x, y)
  local l = b[math.floor(x / BUCKET) .. ":" .. math.floor(y / BUCKET)]
  if not l then return false end
  for i = 1, #l do
    local e = l[i]
    if math.abs(e[1] - x) <= e[3] and math.abs(e[2] - y) <= e[3] then return true end
  end
  return false
end

-- Cells of 4x4 chunks -> bucket index with the given reach (in chunks)
function U.cell_buckets(cells, reach)
  local b = {}
  for _, c in pairs(cells) do U.bucket_add(b, c[1] * 4 + 1.5, c[2] * 4 + 1.5, reach) end
  return b
end

function U.cell_key(x, y)
  return math.floor(x / 4) .. ":" .. math.floor(y / 4)
end

return U
