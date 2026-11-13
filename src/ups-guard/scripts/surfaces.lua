-- Surface overview and deletion: one-time deletion list, automatic deletion of unused planets, manual deletion.
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

---------------------------------------------------------------- unused planets
-- A surface is idle when no player is on it and nothing of a player force stands on it.
local function is_active(surface)
  return S.players_on(surface) > 0 or Z.has_buildings(surface, Z.own_forces())
end

function S.track_activity()
  storage.surface_active = storage.surface_active or {}
  local seen = {}
  for _, s in pairs(cfg.auto_surfaces(nil, true)) do
    seen[s.name] = true
    if is_active(s) or not storage.surface_active[s.name] then storage.surface_active[s.name] = game.tick end
  end
  for name in pairs(storage.surface_active) do
    if not seen[name] then storage.surface_active[name] = nil end
  end
end

-- Planets idle for at least delete-unused-hours. Returns a list of surfaces.
function S.unused()
  local limit = cfg.get("delete-unused-hours") * 3600 * 60
  local out = {}
  for _, s in pairs(cfg.auto_surfaces(nil, true)) do
    local last = (storage.surface_active or {})[s.name]
    if last and game.tick - last >= limit and S.can_delete(s) then out[#out + 1] = s end
  end
  return out
end

function S.auto_delete_unused()
  if not cfg.get("delete-unused") then return 0 end
  S.track_activity()
  local n = 0
  for _, s in ipairs(S.unused()) do
    S.delete(s)
    n = n + 1
  end
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
      and math.floor((game.tick - storage.surface_active[surface.name]) / 216000) or -1,
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
