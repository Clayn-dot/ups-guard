-- /upg surface <delete|unused>: deleting surfaces by hand and listing the ones the automatic deletion would take.
local cfg = require("scripts.cfg")
local U = require("scripts.util")
local say = require("scripts.say")
local surfaces = require("scripts.surfaces")

local ACTIONS = {}

function ACTIONS.delete(ctx, apply)
  local s = ctx.args[2] and game.get_surface(ctx.args[2])
  if not s then say.reply(ctx, {"upg.surface-not-found", ctx.args[2] or ""}); return end
  local ok, why = surfaces.can_delete(s)
  if not ok then say.reply(ctx, {"upg.surface-no-" .. tostring(why), s.name}); return end
  if not apply then say.reply(ctx, {"upg.surface-delete-dry", s.name}); return end
  surfaces.delete(s)
  say.reply(ctx, {"upg.surface-delete-ok", s.name})
end

function ACTIONS.unused(ctx)
  surfaces.track_activity()
  say.reply(ctx, {"upg.surface-unused-head", cfg.get("delete-unused-hours"), tostring(cfg.get("delete-unused"))})
  local list = surfaces.unused()
  for _, s in ipairs(list) do
    say.reply(ctx, {"upg.surface-unused-line", s.name, math.floor((game.tick - storage.surface_active[s.name]) / 216000)})
  end
  if #list == 0 then say.reply(ctx, {"upg.surface-unused-none"}) end
end

return function(reg)
  reg("surface", true, function(ctx)
    local apply = U.take_confirm(ctx.args)
    local action = ACTIONS[string.lower(ctx.args[1] or "")]
    if not action then say.reply(ctx, {"upg.surface-usage"}); return end
    action(ctx, apply)
  end)
end
