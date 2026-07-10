local h = require("tests.harness")
local fox, check, love_stub = h.fox, h.check, h.love_stub

do
  h.section("RadioGroup")
  local idx
  local rg = fox.RadioGroup.new{ x = 0, y = 0, options = { "a", "b", "c" },
    spacing = 30, onChange = function(i) idx = i end }
  check("default selected 1", rg.selected == 1)
  -- click row 2 (y ~ 30..48)
  local rx, ry = rg:rowBounds(2)
  check("press row 2 consumes", rg:mousepressed(rx + 2, ry + 2, 1) == true)
  rg:mousereleased(rx + 2, ry + 2, 1)
  check("selected became 2", rg.selected == 2)
  check("onChange got 2", idx == 2)
  -- clicking the already-selected row does not re-fire
  idx = nil
  rg:mousepressed(rx + 2, ry + 2, 1); rg:mousereleased(rx + 2, ry + 2, 1)
  check("no re-fire on same row", idx == nil)
  local ok = pcall(function() rg:draw() end)
  check("draw no error", ok)
end

do
  h.section("RadioGroup keyboard")
  local idx
  local r = fox.Root.new()
  local rg = r:add(fox.RadioGroup.new{ x = 0, y = 0, options = { "a", "b", "c" },
    spacing = 30, onChange = function(i) idx = i end })
  r:setFocus(rg)
  rg:keypressed("down")
  check("down moves to 2", rg.selected == 2 and idx == 2)
  rg:keypressed("up")
  check("up moves back to 1", rg.selected == 1)
  rg:keypressed("up")
  check("up wraps to last", rg.selected == 3)
  rg:keypressed("down")
  check("down wraps to first", rg.selected == 1)
  rg:keypressed("end")
  check("end selects last", rg.selected == 3)
  rg:keypressed("home")
  check("home selects first", rg.selected == 1)

  -- Hover tracks the row under the cursor.
  local rx, ry = rg:rowBounds(2)
  love_stub.setMouse(rx + 2, ry + 2)
  rg:update(0.016)
  check("hover tracks row 2", rg.hover == 2)
  love_stub.setMouse(999, 999)
  rg:update(0.016)
  check("hover cleared off group", rg.hover == nil)
end
