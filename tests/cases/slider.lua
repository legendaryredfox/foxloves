local h = require("tests.harness")
local fox, check, love_stub = h.fox, h.check, h.love_stub

do
  h.section("Slider")
  local v
  local s = fox.Slider.new{ x = 0, y = 0, w = 100, h = 20, min = 0, max = 100,
    onChange = function(nv) v = nv end }
  check("starts at min", s.value == 0)
  -- press at far right jumps toward max
  s:mousepressed(100, 10, 1)
  check("dragging set", s.dragging == true)
  check("value jumped high", s.value > 90)
  check("onChange fired on press", v == s.value)
  -- update follows cursor while button held
  love_stub.setMouseDown(1, true)
  love_stub.setMouse(0, 10)
  s:update(0.016)
  check("value followed to low", s.value < 10)
  -- releasing the physical button ends drag on next update
  love_stub.setMouseDown(1, false)
  s:update(0.016)
  check("drag ends when button up", s.dragging == false)
  -- step snapping
  local snapped = fox.Slider.new{ x = 0, y = 0, w = 100, min = 0, max = 10, step = 2 }
  snapped:mousepressed(55, 10, 1)   -- ~ mid
  check("snapped to step", snapped.value % 2 == 0)
  love_stub.setMouseDown(1, false)
  local ok = pcall(function() s:draw() end)
  check("draw no error", ok)
end
