-- Bulk enemy removal for commands. Only real enemies: asteroids are on the enemy force too, and enemy
-- gun turrets of some mods are "ammo-turret" - neither is touched. Every function counts without
-- removing when apply is false.
local U = require("scripts.util")
local Z = require("scripts.zones")

local E = {}

local TYPES = {"unit", "unit-spawner", "turret", "spider-unit", "segmented-unit"}

local function remove(list, apply)
  local n = 0
  for _, e in pairs(list) do
    if e.valid then
      if apply then e.destroy() end
      n = n + 1
    end
  end
  return n
end

---------------------------------------------------------------- inside artillery reach
-- Re-chart the zone so the map stops showing the removed nests
local function chart_zone(surface, force, pos, r, done)
  local cx, cy, c = math.floor(pos.x / 32), math.floor(pos.y / 32), math.ceil(r / 32) + 1
  local charted = 0
  for x = cx - c, cx + c do
    for y = cy - c, cy + c do
      local k = x .. ":" .. y
      if not done[k] and surface.is_chunk_generated({x, y}) then
        done[k] = true
        force.chart(surface, {{x * 32, y * 32}, {x * 32 + 31, y * 32 + 31}})
        charted = charted + 1
      end
    end
  end
  return charted
end

function E.artillery(force, surfaces, apply)
  local res = {guns = 0, max_r = 0, count = 0, per = {}, charted = 0}
  for _, s in ipairs(surfaces) do
    local done = {}
    for _, a in pairs(s.find_entities_filtered{type = {"artillery-turret", "artillery-wagon"}, force = force}) do
      res.guns = res.guns + 1
      local r = Z.artillery_range(a)
      if r > res.max_r then res.max_r = r end
      local n = remove(s.find_entities_filtered{position = a.position, radius = r, force = "enemy", type = TYPES}, apply)
      if n > 0 then res.count = res.count + n; res.per[s.name] = (res.per[s.name] or 0) + n end
      if apply then res.charted = res.charted + chart_zone(s, force, a.position, r, done) end
    end
  end
  return res
end

---------------------------------------------------------------- near your buildings
-- Returns total, {surface = count}
function E.near(force, tiles, surfaces, apply)
  local total, per = 0, {}
  for _, s in ipairs(surfaces) do
    local b = U.cell_buckets(Z.built_cells(s), math.ceil(tiles / 32) + 2)
    local n = 0
    for c in s.get_chunks() do
      if s.is_chunk_generated(c) and U.is_protected(b, c.x, c.y) then
        local found = s.find_entities_filtered{area = c.area, force = "enemy", type = TYPES}
        if #found > 0 then
          n = n + remove(found, apply)
          if apply then force.chart(s, c.area) end
        end
      end
    end
    if n > 0 then per[s.name] = n; total = total + n end
  end
  return total, per
end

---------------------------------------------------------------- reset
-- Removes every living enemy, then puts back a few spread-out nests outside artillery reach.
local function artillery_reach(surface, force)
  local best = 0
  for _, a in pairs(surface.find_entities_filtered{type = {"artillery-turret", "artillery-wagon"}, force = force}) do
    best = math.max(best, Z.artillery_range(a))
  end
  return best
end

-- Nests that are not too close to you and not too far to matter
local function candidates(surface, near, far)
  local coarse = Z.built_cells(surface)
  local b_near = U.cell_buckets(coarse, math.ceil(near / 32) + 2)
  local b_far = U.cell_buckets(coarse, math.ceil(far / 32) + 2)
  local out = {}
  for _, e in pairs(surface.find_entities_filtered{force = "enemy", type = "unit-spawner"}) do
    local cx, cy = math.floor(e.position.x / 32), math.floor(e.position.y / 32)
    if U.is_protected(b_far, cx, cy) and not U.is_protected(b_near, cx, cy) then
      out[#out + 1] = {name = e.name, x = e.position.x, y = e.position.y}
    end
  end
  return out
end

-- Greedy farthest-point choice, so the kept nests are spread out
local function pick_spread(list, keep)
  local chosen = {}
  if #list == 0 or keep <= 0 then return chosen end
  chosen[1] = list[1]
  while #chosen < keep and #chosen < #list do
    local best, bestd = nil, -1
    for _, c in ipairs(list) do
      local dmin = math.huge
      for _, k in ipairs(chosen) do
        local d = (c.x - k.x) ^ 2 + (c.y - k.y) ^ 2
        if d < dmin then dmin = d end
      end
      if dmin > bestd then bestd = dmin; best = c end
    end
    if not best or bestd <= 0 then break end
    chosen[#chosen + 1] = best
  end
  return chosen
end

local function reset_surface(surface, force, keep, apply)
  local near = math.max(artillery_reach(surface, force), 500) + 200
  local chosen = pick_spread(candidates(surface, near, near + 700), keep)
  local removed = remove(surface.find_entities_filtered{force = "enemy", type = TYPES}, apply)
  local back = 0
  for _, c in ipairs(chosen) do
    if not apply or surface.create_entity{name = c.name, position = {c.x, c.y}, force = "enemy"} then back = back + 1 end
  end
  if apply and removed > 0 then force.chart_all(surface) end
  return removed, back
end

-- Returns removed, placed, "surface -n/+m, ..."
function E.reset(force, keep, surfaces, apply)
  local removed, placed, report = 0, 0, {}
  for _, s in ipairs(surfaces) do
    local n, back = reset_surface(s, force, keep, apply)
    removed, placed = removed + n, placed + back
    if n > 0 or back > 0 then report[#report + 1] = s.name .. " -" .. n .. "/+" .. back end
  end
  return removed, placed, table.concat(report, ", ")
end

return E
