-- Surface overview and deletion: one-time deletion list, automatic deletion of idle planets (two tiers), manual deletion.
-- A deleted planet stays on the star map; if someone travels there later it is generated again.
local cfg = require("scripts.cfg")
local Z = require("scripts.zones")
local say = require("scripts.say")

local S = {}

-- Every player counts, offline ones too (their character stays where they logged out)
function S.players_on(surface)
  local n = 0
  for _, p in pairs(game.players) do
    if p.surface.index == surface.index or p.physical_surface.index == surface.index then n = n + 1 end
  end
  return n
end

-- Returns true, or false and a locale key suffix explaining why not
function S.can_delete(surface)
  if surface.index == 1 then return false, "main" end
  if surface.platform then return false, "platform" end
  if not surface.deletable then return false, "not-deletable" end
  if S.players_on(surface) > 0 then return false, "players" end
  return true
end

function S.delete(surface)
  local name = surface.name
  game.delete_surface(surface)
  -- a planet that is generated again starts as a fresh one
  if storage.landed then storage.landed[name] = nil end
  storage.surfaces_deleted = (storage.surfaces_deleted or 0) + 1
  say.all({"upg.surface-deleted", name}, "ok")
end

---------------------------------------------------------------- one-time list
function S.delete_once()
  storage.deleted_once = storage.deleted_once or {}
  local list = cfg.set_of("delete-once") or {}
  for name in pairs(storage.deleted_once) do
    if not list[name] then storage.deleted_once[name] = nil end
  end
  for name in pairs(list) do
    if not storage.deleted_once[name] then
      local s = game.get_surface(name)
      if not s then
        storage.deleted_once[name] = true
      elseif S.can_delete(s) then
        S.delete(s)
        storage.deleted_once[name] = true
      end
    end
  end
end

---------------------------------------------------------------- idle planets, two tiers
-- Tier "fresh": nobody ever stood or built there (a planet only a platform has visited). Deleted after delete-fresh-hours.
-- Tier "used": it was used once and is empty now. Deleted after delete-unused-hours.
-- A surface is idle when no player is on it and nothing of a player force stands on it.
local TICKS_PER_HOUR = 216000

local function is_active(surface)
  return S.players_on(surface) > 0 or Z.has_buildings(surface, Z.own_forces())
end

-- A platform parked at this planet keeps the timer running, but does not make the planet "used".
local function platform_in_orbit(surface)
  local planet = surface.planet
  if not planet then return false end
  for _, force in pairs(game.forces) do
    local ok, list = pcall(function() return force.platforms end)
    if ok and list then
      for _, platform in pairs(list) do
        local at = platform.valid and platform.space_location
        if at and at.name == planet.name then return true end
      end
    end
  end
  return false
end

-- Surfaces that exist when the mod meets a save count as used: they get the longer timer, never a surprise.
function S.init_landed()
  if storage.landed then return end
  storage.landed = {}
  for _, s in pairs(game.surfaces) do storage.landed[s.name] = true end
end

function S.tier(surface)
  return (storage.landed or {})[surface.name] and "used" or "fresh"
end

function S.track_activity()
  S.init_landed()
  storage.surface_active = storage.surface_active or {}
  storage.delete_warned = storage.delete_warned or {}
  -- Nobody watched for a while (the rules were off): the old marks say nothing, start counting again
  local long_ago = storage.tracked_tick and game.tick - storage.tracked_tick > 2 * cfg.get("cycle-hours") * TICKS_PER_HOUR
  storage.tracked_tick = game.tick
  local seen = {}
  for _, s in pairs(cfg.auto_surfaces(nil, true)) do
    seen[s.name] = true
    local active = is_active(s)
    if active then storage.landed[s.name] = true end
    if active or long_ago or platform_in_orbit(s) or not storage.surface_active[s.name] then
      storage.surface_active[s.name] = game.tick
      storage.delete_warned[s.name] = nil
    end
  end
  for name in pairs(storage.surface_active) do
    if not seen[name] then storage.surface_active[name] = nil; storage.delete_warned[name] = nil end
  end
end

-- The rule for a surface: {tier, limit in hours or nil when that tier is off}
local function rule(surface)
  local tier = S.tier(surface)
  if tier == "fresh" then
    return tier, cfg.get("delete-fresh") and cfg.get("delete-fresh-hours") or nil
  end
  return tier, cfg.get("delete-unused") and cfg.get("delete-unused-hours") or nil
end

-- Every tracked planet that could be deleted now (no players on it etc.), with its tier, idle time and limit.
-- Returns a list of {surface, tier, idle (hours), limit (hours or nil when the rule is off)}.
function S.candidates()
  local out = {}
  for _, s in pairs(cfg.auto_surfaces(nil, true)) do
    local last = (storage.surface_active or {})[s.name]
    if last and S.can_delete(s) then
      local tier, limit = rule(s)
      out[#out + 1] = {surface = s, tier = tier, idle = (game.tick - last) / TICKS_PER_HOUR, limit = limit}
    end
  end
  table.sort(out, function(a, b) return a.surface.index < b.surface.index end)
  return out
end

-- Planets idle for longer than their tier allows. Returns a list of surfaces.
function S.unused()
  local out = {}
  for _, c in ipairs(S.candidates()) do
    if c.limit and c.idle >= c.limit then out[#out + 1] = c.surface end
  end
  return out
end

-- Used planets get a chat warning at half the time and in the last pass before the deletion
local function warn_before_delete()
  local pass = cfg.get("cycle-hours")
  for _, c in ipairs(S.candidates()) do
    if c.tier == "used" and c.limit and c.idle < c.limit then
      local name = c.surface.name
      local warned = storage.delete_warned[name] or {}
      local last = c.idle + pass >= c.limit
      local half = c.idle >= c.limit / 2
      if (last and not warned.last) or (half and not warned.half) then
        warned.half, warned.last = true, warned.last or last
        storage.delete_warned[name] = warned
        say.all({"upg.surface-warn", name, math.floor(c.idle), math.max(1, math.ceil(c.limit - c.idle))}, "warn")
      end
    end
  end
end

function S.auto_delete_unused()
  if not (cfg.get("delete-fresh") or cfg.get("delete-unused")) then return 0 end
  S.track_activity()
  local n = 0
  for _, s in ipairs(S.unused()) do
    S.delete(s)
    n = n + 1
  end
  warn_before_delete()
  return n
end

---------------------------------------------------------------- overview
local function kind_of(surface)
  if surface.platform then return "platform" end
  if surface.index == 1 then return "main" end
  if surface.planet then return "planet" end
  return "other"
end

function S.info(surface)
  local chunks = 0
  for c in surface.get_chunks() do
    if surface.is_chunk_generated(c) then chunks = chunks + 1 end
  end
  local w = (storage.watch or {})[surface.name]
  return {
    name = surface.name,
    kind = kind_of(surface),
    chunks = chunks,
    players = S.players_on(surface),
    spawners = w and w.spawners or -1,
    units = w and w.units or -1,
    idle_hours = (storage.surface_active or {})[surface.name]
      and math.floor((game.tick - storage.surface_active[surface.name]) / TICKS_PER_HOUR) or -1,
    deletable = (S.can_delete(surface)),
    protected = cfg.protected(surface),
  }
end

function S.overview()
  local out = {}
  for _, s in pairs(game.surfaces) do out[#out + 1] = S.info(s) end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

return S
