-- What to redo when a setting changes (from the settings window or from /upq set).
local expansion = require("scripts.expansion")
local surfaces = require("scripts.surfaces")
local freeze = require("scripts.freeze")

local Ch = {}

function Ch.on_setting(name)
  if string.sub(name, 1, 14) == "upq-expansion-" then expansion.apply() end
  if name == "upq-delete-once" then surfaces.delete_once() end
  if string.sub(name, 1, 11) == "upq-freeze-" then freeze.recheck(false, true) end
end

-- After many settings changed at once (presets)
function Ch.all()
  expansion.apply()
  surfaces.delete_once()
  freeze.recheck(false, true)
  freeze.thin_once()
end

return Ch
