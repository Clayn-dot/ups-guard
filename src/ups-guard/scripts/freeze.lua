-- Far-base freeze: on chosen surfaces, enemy entities far from anything you built and from players are paused
-- (disabled_by_script), so they cost nothing per tick. A "thin" job also deletes the ones beyond the thin radius.
-- Near you everything stays alive; when a player walks up, the area wakes within about two seconds.
local cfg = require("scripts.cfg")
local U = require("scripts.util")
local Z = require("scripts.zones")
local say = require("scripts.say")

local F = {}

local function freeze_on(surface)
  if not cfg.get("freeze-enabled") or not cfg.eligible(surface) then return false end
  local only = cfg.set_of("freeze-surfaces")
  return only == nil or only[surface.name] == true
end
F.applies = freeze_on

local function wake_chunks()
  return math.ceil(cfg.get("freeze-wake-radius") / 32) + 3
end

-- thin=true also deletes enemies beyond the thin radius. A running job is kept, unless restart is set
-- (settings changed) or it has to become a thinning job. Returns true when a job was started.
function F.start(surface, thin, restart)
  storage.freeze_jobs = storage.freeze_jobs or {}
  local existing = storage.freeze_jobs[surface.index]
  if existing and not restart and not (thin and not existing.thin) then return false end
  local st = Z.scan_new(surface, false)
  st.stage, st.enabled = "scan", freeze_on(surface)
  st.thin = thin or (existing ~= nil and existing.thin) or false
  st.frozen, st.woken, st.removed = 0, 0, 0
  storage.freeze_jobs[surface.index] = st
  return true
end

local function zone(surface, st)
  local b = U.cell_buckets(st.coarse, math.ceil(cfg.get("freeze-radius") / 32) + 2)
  Z.add_players(b, surface, wake_chunks(), false)
  if st.thin then
    local tb = U.cell_buckets(st.coarse, math.ceil(cfg.get("thin-radius") / 32) + 2)
    Z.add_players(tb, surface, wake_chunks(), false)
    st.thin_buckets = tb
  end
  st.coarse = nil
  st.buckets = b
  st.i = 1
  st.stage = "apply"
end

local function apply_chunk(surface, st, x, y)
  local awake = (not st.enabled) or U.is_protected(st.buckets, x, y)
  local remove = st.thin_buckets and not U.is_protected(st.thin_buckets, x, y)
  for _, e in pairs(surface.find_entities_filtered{area = U.chunk_area(x, y), force = "enemy"}) do
    if e.valid and e.type ~= "asteroid" then
      if remove then
        e.destroy(); st.removed = st.removed + 1
      elseif awake then
        if e.disabled_by_script then e.disabled_by_script = false; st.woken = st.woken + 1 end
      elseif not e.disabled_by_script then
        e.disabled_by_script = true; st.frozen = st.frozen + 1
      end
    end
  end
end

local function apply(surface, st)
  local last = math.min(st.i + 299, #st.chunks)
  for i = st.i, last do apply_chunk(surface, st, st.chunks[i][1], st.chunks[i][2]) end
  st.i = last + 1
  return st.i > #st.chunks
end

local function step(surface, st)
  if st.stage == "scan" then
    if Z.scan_step(surface, st) then st.stage = "zone" end
    return false
  elseif st.stage == "zone" then
    zone(surface, st)
    return false
  end
  return apply(surface, st)
end

local function count_paused(surface)
  local n = 0
  for _, e in pairs(surface.find_entities_filtered{force = "enemy"}) do
    if e.disabled_by_script then n = n + 1 end
  end
  return n
end

local function finish(surface, st)
  local paused = st.enabled and count_paused(surface) or 0
  storage.freeze_stats = storage.freeze_stats or {}
  storage.freeze_stats[surface.name] = {frozen = paused, tick = game.tick}
  if st.thin then
    storage.thinned = storage.thinned or {}
    storage.thinned[surface.name] = true
    say.all({"upq.thin-done", surface.name, st.removed, cfg.get("thin-radius"), paused}, "ok")
  end
end

-- Called every 15 ticks: one slice of one surface
function F.tick()
  local jobs = storage.freeze_jobs
  if not jobs then return end
  for idx, st in pairs(jobs) do
    local s = game.get_surface(idx)
    if not (s and s.valid) then
      jobs[idx] = nil
    elseif step(s, st) then
      jobs[idx] = nil
      finish(s, st)
    end
    return -- one surface per call
  end
end

-- Wake everything around players on frozen surfaces
function F.wake()
  if not cfg.get("freeze-enabled") then return end
  local radius = cfg.get("freeze-wake-radius")
  for _, p in pairs(game.connected_players) do
    if freeze_on(p.surface) then
      for _, e in pairs(p.surface.find_entities_filtered{position = p.position, radius = radius, force = "enemy"}) do
        if e.valid and e.disabled_by_script then e.disabled_by_script = false end
      end
    end
  end
end

-- Recalculate the zones of every surface the freeze applies to or has touched before
function F.recheck(thin, restart)
  local n = 0
  for _, s in pairs(game.surfaces) do
    if cfg.eligible(s) and (freeze_on(s) or (storage.freeze_stats or {})[s.name]) then
      if F.start(s, thin, restart) then n = n + 1 end
    end
  end
  return n
end

-- thin-once: one thinning per surface, remembered in storage
function F.thin_once()
  if not cfg.get("thin-once") then return end
  storage.thinned = storage.thinned or {}
  for _, s in pairs(cfg.auto_surfaces("thin-surfaces", false)) do
    if not storage.thinned[s.name] then F.start(s, true) end
  end
end

-- Pause or thin a given list of surfaces now (command)
function F.start_on(surfaces, thin)
  local n = 0
  for _, s in ipairs(surfaces) do
    if F.start(s, thin) then n = n + 1 end
  end
  return n
end

return F
