-- Finding what is "yours" on a surface. A chunk is used if it holds anything built by a player force
-- or a placed floor tile. Scans run in slices so a big map does not freeze the game.
local U = require("scripts.util")

local Z = {}

local SLICE = 500

function Z.own_forces()
  local f = {}
  for _, force in pairs(game.forces) do
    if force.name ~= "enemy" and force.name ~= "neutral" then f[#f + 1] = force.name end
  end
  return f
end

-- Entities the map generator puts on a player force by itself (Fulgoran ruin attractors) are not "yours".
local natural_cache
local function is_natural(entity)
  if not natural_cache then
    natural_cache = {}
    for name, proto in pairs(prototypes.entity) do
      if proto.autoplace_specification then natural_cache[name] = true end
    end
  end
  return natural_cache[entity.name] == true
end

-- area == nil searches the whole surface
function Z.has_buildings(surface, forces, area)
  local first = surface.find_entities_filtered{area = area, force = forces, limit = 1}[1]
  if not first then return false end
  if not is_natural(first) then return true end
  for _, e in pairs(surface.find_entities_filtered{area = area, force = forces}) do
    if not is_natural(e) then return true end
  end
  return false
end

-- Tiles players can place (not the ones the generator places by itself, like grass or sand)
local tile_cache
local function placed_tiles()
  if tile_cache then return tile_cache end
  local set, list = {}, {}
  for _, item in pairs(prototypes.item) do
    local pt = item.place_as_tile_result
    if pt and pt.result and not pt.result.autoplace_specification then set[pt.result.name] = true end
  end
  for name in pairs(set) do list[#list + 1] = name end
  tile_cache = list
  return list
end

function Z.artillery_range(entity)
  local best = 0
  for _, gun in pairs(entity.prototype.guns or {}) do
    local ap = gun.attack_parameters
    if ap and ap.range and ap.range > best then best = ap.range end
  end
  if best <= 0 then best = 224 end
  return best * (1 + entity.force.artillery_range_modifier)
end

---------------------------------------------------------------- scan
-- State: chunks (generated ones), i, coarse (cells of 4x4 chunks holding something built), used
function Z.scan_new(surface, with_tiles)
  local list = {}
  for c in surface.get_chunks() do
    if surface.is_chunk_generated(c) then list[#list + 1] = {c.x, c.y} end
  end
  return {chunks = list, i = 1, coarse = {}, used = 0, forces = Z.own_forces(), tiles = with_tiles}
end

-- Returns true when the scan is finished
function Z.scan_step(surface, st)
  local tiles = st.tiles and placed_tiles() or {}
  local last = math.min(st.i + SLICE - 1, #st.chunks)
  for i = st.i, last do
    local x, y = st.chunks[i][1], st.chunks[i][2]
    local area = U.chunk_area(x, y)
    local used = Z.has_buildings(surface, st.forces, area)
    if not used and #tiles > 0 then
      used = surface.count_tiles_filtered{area = area, name = tiles, limit = 1} > 0
    end
    if used then
      st.used = st.used + 1
      st.coarse[U.cell_key(x, y)] = {math.floor(x / 4), math.floor(y / 4)}
    end
  end
  st.i = last + 1
  return st.i > #st.chunks
end

-- Cells of 4x4 chunks holding something built, found in one go (no tiles). For commands.
function Z.built_cells(surface)
  return Z.scan_all(surface, false).coarse
end

-- Runs a whole scan at once (for commands)
function Z.scan_all(surface, with_tiles)
  local st = Z.scan_new(surface, with_tiles)
  while not Z.scan_step(surface, st) do end
  return st
end

---------------------------------------------------------------- protection of points of interest
-- radius_chunks: how far from a player's chunk stays protected. all=true includes offline players.
function Z.add_players(b, surface, radius_chunks, all)
  for _, p in pairs(all and game.players or game.connected_players) do
    if p.surface.index == surface.index then
      U.bucket_add(b, math.floor(p.position.x / 32), math.floor(p.position.y / 32), radius_chunks)
    end
  end
end

-- The far scan range of a radar is not readable at runtime, so the vanilla 14 chunks is used (at least)
local RADAR_SCAN = 14

function Z.add_radars(b, surface, forces, min_reach)
  for _, r in pairs(surface.find_entities_filtered{type = "radar", force = forces}) do
    local reach = math.max(RADAR_SCAN, r.prototype.radar_range or 0)
    U.bucket_add(b, math.floor(r.position.x / 32), math.floor(r.position.y / 32), math.max(min_reach, reach + 2))
  end
end

function Z.add_artillery(b, surface, forces, min_reach)
  for _, a in pairs(surface.find_entities_filtered{type = {"artillery-turret", "artillery-wagon"}, force = forces}) do
    local reach = math.ceil(Z.artillery_range(a) / 32) + 2
    U.bucket_add(b, math.floor(a.position.x / 32), math.floor(a.position.y / 32), math.max(min_reach, reach))
  end
end

return Z
