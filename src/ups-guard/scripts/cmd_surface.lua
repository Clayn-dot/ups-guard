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
  say.reply(ctx, {"upg.surface-unused-head", cfg.get("delete-fresh-hours"), tostring(cfg.get("delete-fresh")),
                  cfg.get("delete-unused-hours"), tostring(cfg.get("delete-unused"))})
  local list = surfaces.candidates()
  for _, c in ipairs(list) do
    local tier = {"upg.tier-" .. c.tier}
    local idle = math.floor(c.idle)
    if not c.limit then
      say.reply(ctx, {"upg.surface-unused-off", c.surface.name, tier, idle})
    elseif c.idle >= c.limit then
      say.reply(ctx, {"upg.surface-unused-due", c.surface.name, tier, idle, c.limit})
    else
      say.reply(ctx, {"upg.surface-unused-wait", c.surface.name, tier, idle, c.limit, math.ceil(c.limit - c.idle)})
    end
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
