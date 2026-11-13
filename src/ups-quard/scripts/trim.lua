-- Map trimming: delete generated chunks that are far from everything of yours.
-- Protected: chunks within the buffer of anything built, radar scan areas, artillery reach, players.
-- Stages: scan -> protect -> check -> delete. Each step is a slice, so a big map does not freeze.
local U = require("scripts.util")
local Z = require("scripts.zones")

local T = {}

function T.new(surface, buffer, delete, min_chunks)
  local st = Z.scan_new(surface, true)
  st.stage, st.buffer, st.delete, st.min = "scan", buffer, delete, min_chunks
  st.doomed, st.deleted = {}, 0
  return st
end

local function protect(surface, st)
  local b = U.cell_buckets(st.coarse, st.buffer + 2)
  st.coarse = nil
  Z.add_players(b, surface, st.buffer, true)
  Z.add_radars(b, surface, st.forces, st.buffer)
  Z.add_artillery(b, surface, st.forces, st.buffer)
  st.buckets = b
  st.i = 1
  st.stage = "check"
end

local function check(st)
  local last = math.min(st.i + 2999, #st.chunks)
  for i = st.i, last do
    local c = st.chunks[i]
    if not U.is_protected(st.buckets, c[1], c[2]) then st.doomed[#st.doomed + 1] = c end
  end
  st.i = last + 1
  if st.i <= #st.chunks then return false end
  st.buckets, st.chunks, st.i = nil, nil, 1
  if st.delete and #st.doomed >= st.min then st.stage = "delete"; return false end
  return true
end

local function delete_slice(surface, st)
  local last = math.min(st.i + 499, #st.doomed)
  for i = st.i, last do
    surface.delete_chunk(st.doomed[i])
    st.deleted = st.deleted + 1
  end
  st.i = last + 1
  return st.i > #st.doomed
end

-- Advances one slice. Returns true when finished.
function T.step(surface, st)
  if st.stage == "scan" then
    if Z.scan_step(surface, st) then st.stage = "protect" end
    return false
  elseif st.stage == "protect" then
    protect(surface, st)
    return false
  elseif st.stage == "check" then
    return check(st)
  end
  return delete_slice(surface, st)
end

-- For the job list: where the job is now
function T.progress(st)
  local n = st.stage == "delete" and #st.doomed or (st.chunks and #st.chunks or 0)
  return {stage = st.stage, i = st.i, n = n}
end

-- Runs a whole trim at once (for the command). apply=false only counts.
function T.run(surface, buffer, apply)
  local st = T.new(surface, buffer, apply, 1)
  local total = #st.chunks
  while not T.step(surface, st) do end
  return {chunks = total, used = st.used, doomed = #st.doomed, deleted = st.deleted}
end

return T
