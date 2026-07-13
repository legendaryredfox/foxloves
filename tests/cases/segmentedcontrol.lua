local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("SegmentedControl")
  local idx
  local sc = fox.SegmentedControl.new{ x = 0, y = 0, w = 300, h = 30,
    options = { "Day", "Week", "Month" }, onChange = function(i) idx = i end }
  check("default selected 1", sc.selected == 1)
  check("segment width even", sc:_segW() == 100)

  -- Click the middle segment (100..200) selects it.
  check("press mid consumes", sc:mousepressed(150, 10, 1) == true)
  check("selected became 2", sc.selected == 2)
  check("onChange got 2", idx == 2)

  -- Clicking the already-selected segment does not re-fire.
  idx = nil
  sc:mousepressed(150, 10, 1)
  check("no re-fire on same segment", idx == nil)

  -- Last segment via a click near the right edge.
  sc:mousepressed(290, 10, 1)
  check("selected became 3", sc.selected == 3)

  -- Press outside consumes nothing.
  check("press outside inert", sc:mousepressed(400, 10, 1) == false)

  -- Hover tracks the segment under the cursor.
  sc:mousemoved(50, 10)
  check("hover tracks segment 1", sc.hovered == 1)
  sc:mousemoved(999, 999)
  check("hover cleared off control", sc.hovered == nil)
end

do
  h.section("SegmentedControl keyboard")
  local r = fox.Root.new()
  local sc = r:add(fox.SegmentedControl.new{ x = 0, y = 0, w = 300, h = 30,
    options = { "a", "b", "c" } })
  r:setFocus(sc)
  sc:keypressed("right")
  check("right moves to 2", sc.selected == 2)
  sc:keypressed("right"); sc:keypressed("right")
  check("right wraps to first", sc.selected == 1)
  sc:keypressed("left")
  check("left wraps to last", sc.selected == 3)

  -- Unfocused control ignores keys.
  r:setFocus(nil)
  local before = sc.selected
  check("keys ignored when unfocused", sc:keypressed("left") == false and sc.selected == before)

  check("draw no error", pcall(function() sc:draw() end))
end
