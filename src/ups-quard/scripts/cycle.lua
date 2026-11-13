-- The maintenance pass: a queue of small jobs (one surface, one slice at a time, one job per 30 ticks),
-- started every N hours of game time or by hand. Other long jobs (the entity report) use the same queue.
local cfg = require("scripts.cfg")
local U = require("scripts.util")
local say = require("scripts.say")
local items = require("scripts.items")
local trim = require("scripts.trim")
local watch = require("scripts.watch")
local surfaces = require("scripts.surfaces")
local freeze = require("scripts.freeze")
local report = require("scripts.report")

local Cy = {}

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
  if cfg.get("trim-enabled") then
    for _, s in ipairs(cfg.auto_surfaces("trim-surfaces", true)) do jobs[#jobs + 1] = {kind = "trim", surface = s.index} end
  end
  if cfg.get("watch-enabled") then
    for _, s in ipairs(cfg.auto_surfaces(nil, false)) do jobs[#jobs + 1] = {kind = "watch", surface = s.index} end
  end
  return jobs
end

-- Returns false when a pass is already running
function Cy.start(announce_to)
  if storage.cycle then return false end
  storage.cycle = {items = {}, checked = {}, trimmed = {}, announce = announce_to, deleted = 0}
  for _, job in ipairs(plan()) do storage.jobs[#storage.jobs + 1] = job end
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
local function say_trim_and_items(c)
  local total, text = U.summary(c.items)
  if total > 0 then say.all({"upq.cycle-items", total, text}) end
  local t_total, t_text = U.summary(c.trimmed)
  if t_total > 0 then say.all({"upq.cycle-trim", t_total, t_text}) end
end

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
end

local function finish()
  local c = storage.cycle
  storage.cycle, storage.progress = nil, nil
  say_trim_and_items(c)
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

local function run_items(job, s)
  local n = items.clean(s, true)
  if n > 0 and storage.cycle then storage.cycle.items[s.name] = (storage.cycle.items[s.name] or 0) + n end
  return true
end

local function run_watch(job, s)
  watch.count(s)
  if storage.cycle then storage.cycle.checked[s.name] = true end
  return true
end

local SURFACE_JOBS = {items = run_items, trim = run_trim, watch = run_watch}

-- Returns true when the job is finished
local function run(job)
  if job.kind == "unused" then
    surfaces.auto_delete_unused()
    return true
  elseif job.kind == "report" then
    if report.step(job.state) then say.all({"upq.report-done"}, "ok"); return true end
    return false
  end
  local s = game.get_surface(job.surface)
  if not (s and s.valid and cfg.eligible(s)) then return true end
  return SURFACE_JOBS[job.kind](job, s)
end

-- Called every 30 ticks
function Cy.step()
  local job = table.remove(storage.jobs, 1)
  if not job then
    if storage.cycle then finish() end
    return
  end
  if not run(job) then table.insert(storage.jobs, 1, job) end
end

-- Called once a minute of game time
function Cy.minute()
  storage.minutes = storage.minutes + 1
  surfaces.delete_once()
  local left = Cy.minutes_left()
  if left == Cy.period() then
    storage.cycles = (storage.cycles or 0) + 1
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
