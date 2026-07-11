local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Toggle")
  local got
  local tg = fox.Toggle.new{ x = 0, y = 0, w = 44, h = 24,
    onChange = function(v) got = v end }
  check("starts off", tg.on == false)
  tg:mousepressed(5, 5, 1); tg:mousereleased(5, 5, 1)
  check("clicked on", tg.on == true)
  check("onChange got true", got == true)
  -- animation eases toward target over updates
  tg.anim = 0
  for _ = 1, 60 do tg:update(0.016) end
  check("anim reaches on end", tg.anim == 1)
  check("input ignored outside", tg:mousepressed(900, 900, 1) == false)
  -- hover fill (event-driven, local coords)
  tg:mousemoved(5, 5)
  check("hover true over track", tg.hovered == true)
  tg:mousemoved(900, 900)
  check("hover false off widget", tg.hovered == false)
  local dt = fox.Toggle.new{ disabled = true }
  dt:mousemoved(5, 5)
  check("disabled never hovers", dt.hovered == false)
  local ok = pcall(function() tg:draw() end)
  check("draw no error", ok)
end
