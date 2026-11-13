-- Entity report of every surface, written to script-output/ups-quard-report.txt.
-- Counts chunk by chunk in slices, so a map with millions of entities does not freeze the game.
local U = require("scripts.util")

local R = {}

local SLICE = 150
local TOP_TYPES, TOP_NAMES = 20, 25

local function names_of(surfaces)
  local out = {}
  for _, s in pairs(surfaces) do out[#out + 1] = s.name end
  table.sort(out)
  return out
end

function R.new(player_index)
  return {names = names_of(game.surfaces), si = 1, text = {}, player = player_index or 0}
end

local function open_surface(st, surface)
  local list = {}
  for c in surface.get_chunks() do
    if surface.is_chunk_generated(c) then list[#list + 1] = {c.x, c.y} end
  end
  st.cur = {chunks = list, i = 1, types = {}, kinds = {}, n = 0, enemies = 0}
end

local function top(map, k)
  local a = {}
  for name, c in pairs(map) do a[#a + 1] = {name, c} end
  table.sort(a, function(p, q) return p[2] > q[2] or (p[2] == q[2] and p[1] < q[1]) end)
  local out = {}
  for i = 1, math.min(k, #a) do out[#out + 1] = "  " .. a[i][1] .. " = " .. a[i][2] end
  return table.concat(out, "\n")
end

local function close_surface(st, surface)
  local c = st.cur
  st.text[#st.text + 1] = "### " .. surface.name .. " | entities: " .. c.n .. " | enemy: " .. c.enemies ..
    " | chunks: " .. #c.chunks .. "\n-- types:\n" .. top(c.types, TOP_TYPES) .. "\n-- names:\n" .. top(c.kinds, TOP_NAMES)
  st.cur = nil
  st.si = st.si + 1
end

local function count_slice(surface, c)
  local last = math.min(c.i + SLICE - 1, #c.chunks)
  for i = c.i, last do
    local area = U.chunk_area(c.chunks[i][1], c.chunks[i][2])
    c.enemies = c.enemies + surface.count_entities_filtered{area = area, force = "enemy"}
    for _, e in pairs(surface.find_entities_filtered{area = area}) do
      c.n = c.n + 1
      c.types[e.type] = (c.types[e.type] or 0) + 1
      c.kinds[e.name] = (c.kinds[e.name] or 0) + 1
    end
  end
  c.i = last + 1
  return c.i > #c.chunks
end

-- One slice. Returns true when the report is written.
function R.step(st)
  local name = st.names[st.si]
  if not name then
    helpers.write_file("ups-quard-report.txt", table.concat(st.text, "\n\n") .. "\n", false, st.player)
    return true
  end
  local surface = game.get_surface(name)
  if not (surface and surface.valid) then st.si = st.si + 1; return false end
  if not st.cur then open_surface(st, surface) end
  if count_slice(surface, st.cur) then close_surface(st, surface) end
  return false
end

return R
