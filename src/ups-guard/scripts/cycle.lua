-- The maintenance pass: a queue of small jobs (one surface, one slice at a time, one job per 30 ticks),
-- started every N hours of game time or by hand. Other long jobs (the entity report) use the same queue.
local cfg = require("scripts.cfg")
local say = require("scripts.say")
local items = require("scripts.items")
local trim = require("scripts.trim")
local watch = require("scripts.watch")
local surfaces = require("scripts.surfaces")
local freeze = require("scripts.freeze")
local report = require("scripts.report")
local junk = require("scripts.junk")
local pollution = require("scripts.pollution")
local platforms = require("scripts.platforms")
local trains = require("scripts.trains")
local passcard = require("scripts.passcard")

local Cy = {}

-- Time spent per kind of job, only measured while /upq profile is on. Not saved: profilers cannot be serialized.
local spent = {}

function Cy.init()
  storage.jobs = storage.jobs or {}
  storage.minutes = storage.minutes or 0
  storage.items_removed = storage.items_removed or 0
  storage.watch = storage.watch or {}
end

function Cy.period()
  return cfg.get("cycle-hours") * 60
end

function Cy.minutes_left()
  local period = Cy.period()
  return period - (storage.minutes % period)
end

---------------------------------------------------------------- planning
local function plan()
  local jobs = {}
  if cfg.get("delete-unused") then jobs[#jobs + 1] = {kind = "unused"} end
  if cfg.get("items-enabled") then
    for _, s in ipairs(cfg.auto_surfaces("items-surfaces", false)) do jobs[#jobs + 1] = {kind = "items", surface = s.index} end
  end
  if cfg.get("junk-enabled") then
    for _, s in ipairs(cfg.auto_surfaces("junk-surfaces", false)) do jobs[#jobs + 1] = {kind = "junk", surface = s.index} end
  end
  if cfg.get("pollution-clear") then
    for _, s in ipairs(cfg.auto_surfaces("pollution-surfaces", false)) do jobs[#jobs + 1] = {kind = "pollution", surface = s.index} end
  end
  if cfg.get("asteroids-cap") > 0 then
    for _, s in ipairs(platforms.platform_surfaces()) do jobs[#jobs + 1] = {kind = "asteroids", surface = s.index} end
  end
  if cfg.get("trim-enabled") then
    for _, s in ipairs(cfg.auto_surfaces("trim-surfaces", true)) do jobs[#jobs + 1] = {kind = "trim", surface = s.index} end
  end
  if cfg.get("watch-enabled") then
    for _, s in ipairs(cfg.auto_surfaces(nil, false)) do jobs[#jobs + 1] = {kind = "watch", surface = s.index} end
  end
  if cfg.get("trains-watch") then jobs[#jobs + 1] = {kind = "trains"} end
  return jobs
end

-- Returns false when a pass is already running
function Cy.start(announce_to)
  if storage.cycle then return false end
  storage.cycles = (storage.cycles or 0) + 1
  storage.cycle = {items = {}, junk = {}, pollution = {}, asteroids = {}, checked = {}, trimmed = {},
                   announce = announce_to, deleted = 0, number = storage.cycles}
  for _, job in ipairs(plan()) do storage.jobs[#storage.jobs + 1] = job end
  spent = {}
  return true
end

function Cy.abort()
  local n = #storage.jobs
  storage.jobs, storage.cycle, storage.progress = {}, nil, nil
  return n
end

function Cy.queue_report(player_index)
  storage.jobs[#storage.jobs + 1] = {kind = "report", state = report.new(player_index)}
end

---------------------------------------------------------------- finishing
local function check_watch(c)
  local names = {}
  for name in pairs(c.checked) do names[#names + 1] = name end
  table.sort(names)
  local lim_s, lim_u = cfg.get("watch-spawners"), cfg.get("watch-units")
  for _, name in ipairs(names) do
    if watch.over_limit(name) then
      local w = storage.watch[name]
      say.all({"upq.watch-alert", name, w.spawners, w.units, lim_s, lim_u}, "warn")
      local s = game.get_surface(name)
      if s and cfg.get("watch-thin") then freeze.start(s, true) end
    end
  end
  if c.trains and trains.over_limit(c.trains) then
    say.all({"upq.trains-alert", c.trains.total, cfg.get("trains-limit")}, "warn")
  end
end

local function time_line()
  if not storage.profile then return nil end
  local names = {}
  for name in pairs(spent) do names[#names + 1] = name end
  if #names == 0 then return nil end
  table.sort(names)
  local parts = {"", {"upq.card-time"}}
  for _, name in ipairs(names) do
    parts[#parts + 1] = " " .. name .. " "
    parts[#parts + 1] = spent[name]
  end
  return parts
end

local function finish()
  local c = storage.cycle
  storage.cycle, storage.progress = nil, nil
  say.card({"upq.card-title", c.number}, passcard.lines(c, time_line()), "ok")
  check_watch(c)
  if c.announce then
    local p = game.get_player(c.announce)
    if p and p.valid then p.print({"upq.cycle-done"}) end
  end
end

---------------------------------------------------------------- running jobs
local function run_trim(job, s)
  if not job.state then
    job.state = trim.new(s, cfg.get("trim-buffer"), true, cfg.get("trim-min-chunks"))
  end
  storage.progress = trim.progress(job.state)
  storage.progress.surface = s.name
  if not trim.step(s, job.state) then return false end
  if job.state.deleted > 0 and storage.cycle then storage.cycle.trimmed[s.name] = job.state.deleted end
  return true
end

local function note(map, name, n)
  if n > 0 and storage.cycle then map[name] = (map[name] or 0) + n end
end

local function run_items(_, s)
  if storage.cycle then note(storage.cycle.items, s.name, items.clean(s, true)) end
  return true
end

local function run_junk(_, s)
  local done = junk.clean(s, true)
  for t, n in pairs(done) do
    if storage.cycle then note(storage.cycle.junk, t, n) end
  end
  return true
end

local function run_pollution(_, s)
  local n = pollution.clear(s, true)
  if storage.cycle then note(storage.cycle.pollution, s.name, n) end
  return true
end

local function run_asteroids(_, s)
  if storage.cycle then note(storage.cycle.asteroids, s.name, platforms.cap(s, true)) end
  return true
end

local function run_watch(_, s)
  watch.count(s)
  if storage.cycle then storage.cycle.checked[s.name] = true end
  return true
end

local SURFACE_JOBS = {items = run_items, junk = run_junk, pollution = run_pollution, asteroids = run_asteroids,
                      trim = run_trim, watch = run_watch}

-- Returns true when the job is finished
local function run(job)
  if job.kind == "unused" then
    local n = surfaces.auto_delete_unused()
    if storage.cycle then storage.cycle.deleted = storage.cycle.deleted + n end
    return true
  elseif job.kind == "trains" then
    if storage.cycle then storage.cycle.trains = trains.stuck() end
    return true
  elseif job.kind == "report" then
    if report.step(job.state) then say.all({"upq.report-done"}, "ok"); return true end
    return false
  end
  local s = game.get_surface(job.surface)
  if not (s and s.valid) then return true end
  if job.kind ~= "asteroids" and not cfg.eligible(s) then return true end
  return SURFACE_JOBS[job.kind](job, s)
end

local function timed_run(job)
  if not storage.profile then return run(job) end
  local p = helpers.create_profiler()
  local done = run(job)
  p.stop()
  if spent[job.kind] then spent[job.kind].add(p) else spent[job.kind] = p end
  return done
end

-- On a busy server the pass slows down: with many players online one job per 90 ticks instead of 30
local function calm_now()
  local limit = cfg.get("calm-players")
  return limit > 0 and #game.connected_players >= limit and game.tick % 90 ~= 0
end

-- Called every 30 ticks
function Cy.step()
  if calm_now() then return end
  local job = table.remove(storage.jobs, 1)
  if not job then
    if storage.cycle then finish() end
    return
  end
  if not timed_run(job) then table.insert(storage.jobs, 1, job) end
end

-- Called once a minute of game time
function Cy.minute()
  storage.minutes = storage.minutes + 1
  surfaces.delete_once()
  if cfg.get("pollution-clear") then pollution.visit() end
  local left = Cy.minutes_left()
  if left == Cy.period() then
    Cy.start()
  elseif (left == 30 or left == 1) and #plan() > 0 then
    say.all({"upq.cycle-soon", left})
  end
end

-- First pass five minutes from now
function Cy.schedule_soon()
  local period = Cy.period()
  storage.minutes = period - 5 + (storage.minutes - storage.minutes % period)
end

return Cy
