-- Cross-cutting interaction behaviors that span several widgets: keyboard focus
-- traversal, keyboard activation, wheel scrolling, and hover feedback.
local h = require("tests.harness")
local fox, check, love_stub = h.fox, h.check, h.love_stub

do
  h.section("Focus traversal")
  local r = fox.Root.new()
  local b1 = r:add(fox.Button.new{ x = 0, y = 0, w = 40, h = 20 })
  r:add(fox.Label.new{ x = 0, y = 30, text = "not focusable" })
  local b2 = r:add(fox.Button.new{ x = 0, y = 60, w = 40, h = 20 })

  check("tab focuses first focusable", (r:keypressed("tab") and r.focused) == b1)
  check("tab skips label to next", (r:keypressed("tab") and r.focused) == b2)
  check("tab wraps to first", (r:keypressed("tab") and r.focused) == b1)

  -- Shift-Tab reverses.
  love_stub.setKey("lshift", true)
  check("shift-tab goes back to last", (r:keypressed("tab") and r.focused) == b2)
  love_stub.setKey("lshift", false)

  -- No focusables: tab is not consumed.
  local empty = fox.Root.new()
  empty:add(fox.Label.new{ text = "x" })
  check("tab not consumed without focusables", empty:keypressed("tab") == false)

  -- setFocus syncs a Textbox's own focused flag.
  local f = fox.Root.new()
  local tb = f:add(fox.Textbox.new{ x = 0, y = 0, w = 100, h = 30 })
  f:keypressed("tab")
  check("tab into textbox sets its focused", tb.focused == true)
  f:setFocus(nil)
  check("clearing focus blurs textbox", tb.focused == false)
end

do
  h.section("Keyboard activation")
  -- Button: Space/Enter fire onClick only when focused via Root.
  local clicks = 0
  local r = fox.Root.new()
  local b = r:add(fox.Button.new{ x = 0, y = 0, w = 40, h = 20,
    onClick = function() clicks = clicks + 1 end })
  check("unfocused key ignored", b:keypressed("space") == false)
  check("unfocused no click", clicks == 0)
  r:setFocus(b)
  check("space activates focused button", b:keypressed("space") == true)
  check("return activates focused button", b:keypressed("return") == true)
  check("two activations counted", clicks == 2)

  -- Checkbox toggles on space when focused.
  local rc = fox.Root.new()
  local c = rc:add(fox.Checkbox.new{ x = 0, y = 0 })
  rc:setFocus(c)
  c:keypressed("space")
  check("checkbox toggled by space", c.checked == true)

  -- Toggle flips on enter when focused.
  local rt = fox.Root.new()
  local tg = rt:add(fox.Toggle.new{ x = 0, y = 0 })
  rt:setFocus(tg)
  tg:keypressed("return")
  check("toggle flipped by return", tg.on == true)

  -- Slider: arrows step, Home/End jump.
  local rs = fox.Root.new()
  local sv
  local s = rs:add(fox.Slider.new{ x = 0, y = 0, w = 100, min = 0, max = 10, step = 2,
    onChange = function(v) sv = v end })
  rs:setFocus(s)
  s:keypressed("right")
  check("slider right steps up", s.value == 2)
  check("slider onChange fired", sv == 2)
  s:keypressed("left")
  check("slider left steps down", s.value == 0)
  s:keypressed("end")
  check("slider end jumps to max", s.value == 10)
  s:keypressed("home")
  check("slider home jumps to min", s.value == 0)

  -- Dropdown opens its popup on Down when focused.
  local rd = fox.Root.new()
  local dd = rd:add(fox.Dropdown.new{ x = 0, y = 0, w = 100, h = 30,
    options = { "a", "b" } })
  rd:setFocus(dd)
  check("dropdown opens on down key", dd:keypressed("down") == true)
  check("popup overlay opened", #rd.overlays == 1)
end

do
  h.section("Wheel scroll")
  -- ListBox scrolls one row per wheel notch when the cursor is over it.
  local items = {}
  for i = 1, 20 do items[i] = "i" .. i end
  local r = fox.Root.new()
  local lb = r:add(fox.ListBox.new{ x = 0, y = 0, w = 100, h = 80, rowH = 20,
    items = items })
  love_stub.setMouse(10, 10)  -- over the box
  check("wheel down scrolls", r:wheelmoved(0, -1) == true)
  check("scroll advanced one row", lb.scroll == 20)
  r:wheelmoved(0, 1)          -- wheel up
  check("wheel up scrolls back", lb.scroll == 0)
  love_stub.setMouse(500, 500)  -- off the box
  check("wheel ignored off widget", r:wheelmoved(0, -1) == false)

  -- Slider nudges value on wheel over the track.
  local sv
  local s = fox.Slider.new{ x = 0, y = 0, w = 100, min = 0, max = 10, step = 1,
    onChange = function(v) sv = v end }
  love_stub.setMouse(50, 10)  -- over the slider
  check("wheel up nudges slider", s:wheelmoved(0, 1) == true)
  check("slider value increased", s.value == 1 and sv == 1)
  love_stub.setMouse(0, 0)
end

do
  h.section("Hover feedback")
  -- ListBox tracks the hovered row (distinct from selection).
  local items = {}
  for i = 1, 10 do items[i] = "r" .. i end
  local lb = fox.ListBox.new{ x = 0, y = 0, w = 100, h = 100, rowH = 20, items = items }
  love_stub.setMouse(10, 25)  -- row 2 (y 20..40)
  lb:update(0.016)
  check("listbox hovers row 2", lb.hover == 2)
  love_stub.setMouse(500, 500)
  lb:update(0.016)
  check("listbox hover cleared off box", lb.hover == nil)

  -- Tabs track the hovered header segment.
  local function fakePanel()
    return { update = function() end, draw = function() end,
      mousepressed = function() return false end, mousereleased = function() end,
      keypressed = function() return false end, textinput = function() return false end }
  end
  local tabs = fox.Tabs.new{ x = 0, y = 0, w = 200, headerH = 30,
    tabs = { { label = "A", panel = fakePanel() }, { label = "B", panel = fakePanel() } } }
  love_stub.setMouse(150, 15)  -- second header (x 100..200)
  tabs:update(0.016)
  check("tabs hover second header", tabs.hoverTab == 2)
  love_stub.setMouse(0, 500)
  tabs:update(0.016)
  check("tabs hover cleared", tabs.hoverTab == nil)
  love_stub.setMouse(0, 0)
end
