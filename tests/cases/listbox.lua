local h = require("tests.harness")
local fox, check, love_stub = h.fox, h.check, h.love_stub

do
  h.section("ListBox")
  local picked
  local items = {}
  for i = 1, 20 do items[i] = "item " .. i end
  local lb = fox.ListBox.new{ x = 0, y = 0, w = 200, h = 100, rowH = 20,
    items = items, onChange = function(i) picked = i end }
  check("maxScroll computed", lb:maxScroll() == 20 * 20 - 100)  -- 300

  -- click row 2 (y 20..40) with no drag => selects it
  lb:mousepressed(10, 25, 1)
  love_stub.setMouseDown(1, true); love_stub.setMouse(10, 25)
  lb:update(0.016)              -- no movement, stays a click
  love_stub.setMouseDown(1, false)
  lb:mousereleased(10, 25, 1)
  check("clicked row 2 selected", lb.selected == 2)
  check("onChange got 2", picked == 2)

  -- drag scrolls instead of selecting
  local before = lb.selected
  lb:mousepressed(10, 50, 1)
  love_stub.setMouseDown(1, true)
  love_stub.setMouse(10, 20)    -- moved up 30px => scroll down
  lb:update(0.016)
  love_stub.setMouseDown(1, false)
  lb:mousereleased(10, 20, 1)
  check("drag scrolled", lb.scroll > 0)
  check("drag did not select", lb.selected == before)

  -- scroll clamps to maxScroll
  lb.scroll = 0
  lb:mousepressed(10, 50, 1)
  love_stub.setMouseDown(1, true)
  love_stub.setMouse(10, -10000)
  lb:update(0.016)
  love_stub.setMouseDown(1, false)
  lb:mousereleased(10, -10000, 1)
  check("scroll clamped to max", lb.scroll == lb:maxScroll())

  local ok = pcall(function() lb:draw() end)
  check("draw no error", ok)
  love_stub.setMouse(0, 0)
end

do
  h.section("ListBox keyboard")
  local items = {}
  for i = 1, 20 do items[i] = "i" .. i end
  local picked
  local r = fox.Root.new()
  local lb = r:add(fox.ListBox.new{ x = 0, y = 0, w = 100, h = 80, rowH = 20,
    items = items, onChange = function(i) picked = i end })
  check("focusable", lb.focusable == true)
  check("visibleRows from height", lb:visibleRows() == 4)

  r:setFocus(lb)
  lb:keypressed("down")
  check("first down selects row 1", lb.selected == 1)
  lb:keypressed("down")
  check("down advances", lb.selected == 2 and picked == 2)
  lb:keypressed("up")
  check("up retreats", lb.selected == 1)
  lb:keypressed("end")
  check("end selects last", lb.selected == 20)
  check("end scrolls selection into view", lb.scroll == lb:maxScroll())
  lb:keypressed("home")
  check("home selects first", lb.selected == 1 and lb.scroll == 0)
  lb:keypressed("pagedown")
  check("pagedown pages by visible rows", lb.selected == 5)

  -- Enter re-confirms current selection (fires onChange).
  picked = nil
  lb:keypressed("return")
  check("enter re-confirms selection", picked == 5)

  -- Unfocused ListBox ignores keys.
  r:setFocus(nil)
  check("unfocused ignores keys", lb:keypressed("down") == false)
end
