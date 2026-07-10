-- foxloves test runner. No external deps.
-- Run from project root: luajit tests/run.lua   (or: lua tests/run.lua)

package.path = "./?.lua;./?/init.lua;" .. package.path

local love_stub = require("tests.love_stub")
love_stub.install()

local fox = require("foxloves")

local pass, fail = 0, 0
local function check(name, cond)
  if cond then
    pass = pass + 1
    print("  ok   " .. name)
  else
    fail = fail + 1
    print("  FAIL " .. name)
  end
end

-- ---------------------------------------------------------------- Button
do
  print("Button")
  local clicks = 0
  local b = fox.Button.new{ x = 10, y = 10, w = 100, h = 30,
    onClick = function() clicks = clicks + 1 end }

  check("contains inside", b:contains(20, 20))
  check("contains outside", not b:contains(200, 200))

  -- press + release inside fires onClick
  check("press inside consumes", b:mousepressed(20, 20, 1) == true)
  check("pressed state set", b.pressed == true)
  b:mousereleased(20, 20, 1)
  check("onClick fired once", clicks == 1)
  check("pressed cleared", b.pressed == false)

  -- press inside, release outside: no click
  b:mousepressed(20, 20, 1)
  b:mousereleased(500, 500, 1)
  check("release outside no click", clicks == 1)

  -- right button ignored
  check("right button ignored", b:mousepressed(20, 20, 2) == false)

  -- hover via update
  love_stub.setMouse(20, 20); b:update(0.016)
  check("hover true over widget", b.hovered == true)
  love_stub.setMouse(300, 300); b:update(0.016)
  check("hover false off widget", b.hovered == false)

  -- disabled swallows nothing
  local db = fox.Button.new{ x = 0, y = 0, w = 50, h = 20,
    disabled = true, onClick = function() clicks = clicks + 1 end }
  check("disabled press ignored", db:mousepressed(10, 10, 1) == false)
  db:mousereleased(10, 10, 1)
  check("disabled no click", clicks == 1)

  -- draw smoke test (must not error)
  local okDraw = pcall(function() b:draw() end)
  check("draw does not error", okDraw)
end

-- --------------------------------------------------------------- Textbox
do
  print("Textbox")
  local last
  local t = fox.Textbox.new{ x = 0, y = 0, w = 200, h = 30,
    onChange = function(v) last = v end }

  check("starts empty", t.value == "")
  check("starts unfocused", t.focused == false)

  -- typing requires focus
  t:textinput("x")
  check("no input while unfocused", t.value == "")

  -- focus by clicking inside
  check("click focuses", t:mousepressed(5, 5, 1) == true)
  check("focused after click", t.focused == true)

  t:textinput("H"); t:textinput("i")
  check("typed text", t.value == "Hi")
  check("onChange fired", last == "Hi")
  check("caret at end", t.caret == 2)

  -- backspace
  t:keypressed("backspace")
  check("backspace removes char", t.value == "H")
  check("caret follows", t.caret == 1)

  -- caret movement + mid-string insert
  t:textinput("ello")            -- "Hello"
  t:keypressed("left"); t:keypressed("left")
  check("caret moved left", t.caret == 3)
  t:textinput("X")               -- "HelXlo"
  check("mid insert", t.value == "HelXlo")

  -- maxLength cap
  local cap = fox.Textbox.new{ maxLength = 3 }
  cap:mousepressed(0, 0, 1)      -- focus (default bounds contain 0,0)
  cap:textinput("a"); cap:textinput("b"); cap:textinput("c"); cap:textinput("d")
  check("maxLength enforced", cap.value == "abc")

  -- blur by clicking outside
  t:mousepressed(999, 999, 1)
  check("click outside blurs", t.focused == false)
  t:textinput("z")
  check("no input after blur", t.value == "HelXlo")

  -- draw smoke test
  local okDraw = pcall(function() t.focused = true; t:draw() end)
  check("draw does not error", okDraw)
end

-- ----------------------------------------------------------------- Label
do
  print("Label")
  local l = fox.Label.new{ x = 5, y = 5, text = "hi" }
  check("holds text", l.text == "hi")
  l:setText("bye")
  check("setText updates", l.text == "bye")
  check("mousepressed ignored", l:mousepressed(5, 5, 1) == false)
  check("keypressed ignored", l:keypressed("a") == false)
  local okPrint = pcall(function() l:draw() end)
  check("draw (print) no error", okPrint)
  local wrapped = fox.Label.new{ x = 0, y = 0, w = 100, text = "wrap", align = "center" }
  local okPrintf = pcall(function() wrapped:draw() end)
  check("draw (printf) no error", okPrintf)
end

-- --------------------------------------------------------------- Divider
do
  print("Divider")
  local d = fox.Divider.new{ x = 0, y = 0, length = 50 }
  check("mousepressed ignored", d:mousepressed(0, 0, 1) == false)
  local ok = pcall(function() d:draw(); fox.Divider.new{ vertical = true }:draw() end)
  check("draw no error", ok)
end

-- ------------------------------------------------------------ ProgressBar
do
  print("ProgressBar")
  local p = fox.ProgressBar.new{ x = 0, y = 0, w = 100, h = 10, value = 0.5 }
  check("fraction mid", math.abs(p:fraction() - 0.5) < 1e-9)
  p.value = 5
  check("fraction clamps high", p:fraction() == 1)
  p.value = -5
  check("fraction clamps low", p:fraction() == 0)
  local ranged = fox.ProgressBar.new{ min = 10, max = 20, value = 15 }
  check("fraction with min/max", math.abs(ranged:fraction() - 0.5) < 1e-9)
  check("input ignored", p:mousepressed(0, 0, 1) == false)
  local ok = pcall(function() p:draw() end)
  check("draw no error", ok)
end

-- --------------------------------------------------------------- Checkbox
do
  print("Checkbox")
  local changed
  local c = fox.Checkbox.new{ x = 0, y = 0, size = 20, label = "on",
    onChange = function(v) changed = v end }
  check("starts unchecked", c.checked == false)
  check("press inside consumes", c:mousepressed(5, 5, 1) == true)
  c:mousereleased(5, 5, 1)
  check("toggled on", c.checked == true)
  check("onChange got true", changed == true)
  c:mousepressed(5, 5, 1); c:mousereleased(5, 5, 1)
  check("toggled off", c.checked == false)
  -- press inside, release outside: no toggle
  c:mousepressed(5, 5, 1); c:mousereleased(900, 900, 1)
  check("release outside no toggle", c.checked == false)
  -- disabled ignores
  local dc = fox.Checkbox.new{ disabled = true }
  check("disabled press ignored", dc:mousepressed(5, 5, 1) == false)
  local ok = pcall(function() c.checked = true; c:draw() end)
  check("draw no error", ok)
end

-- ----------------------------------------------------------------- Toggle
do
  print("Toggle")
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
  local ok = pcall(function() tg:draw() end)
  check("draw no error", ok)
end

-- ------------------------------------------------------------- RadioGroup
do
  print("RadioGroup")
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

-- ----------------------------------------------------------------- Slider
do
  print("Slider")
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

-- ---------------------------------------------------------------- Stepper
do
  print("Stepper")
  local v
  local st = fox.Stepper.new{ x = 0, y = 0, w = 120, h = 30, value = 5, step = 1,
    min = 0, max = 10, onChange = function(nv) v = nv end }
  check("initial value", st.value == 5)
  -- plus button is the right square (x = 90..120)
  st:mousepressed(105, 10, 1); st:mousereleased(105, 10, 1)
  check("plus increments", st.value == 6)
  check("onChange got 6", v == 6)
  -- minus button is the left square (x = 0..30)
  st:mousepressed(15, 10, 1); st:mousereleased(15, 10, 1)
  check("minus decrements", st.value == 5)
  -- clamp at max
  local cap = fox.Stepper.new{ x = 0, w = 120, h = 30, value = 10, max = 10 }
  cap:mousepressed(105, 10, 1); cap:mousereleased(105, 10, 1)
  check("clamped at max", cap.value == 10)
  local ok = pcall(function() st:draw() end)
  check("draw no error", ok)
end

-- ------------------------------------------------------------- IconButton
do
  print("IconButton")
  local fakeImage = {
    getWidth = function() return 16 end,
    getHeight = function() return 16 end,
  }
  local clicks = 0
  local ib = fox.IconButton.new{ x = 0, y = 0, w = 32, h = 32, image = fakeImage,
    onClick = function() clicks = clicks + 1 end }
  check("press inside consumes", ib:mousepressed(5, 5, 1) == true)
  ib:mousereleased(5, 5, 1)
  check("onClick fired", clicks == 1)
  ib:mousepressed(5, 5, 1); ib:mousereleased(900, 900, 1)
  check("release outside no click", clicks == 1)
  love_stub.setMouse(5, 5); ib:update(0.016)
  check("hover true over widget", ib.hovered == true)
  local ok = pcall(function() ib:draw() end)
  check("draw with image no error", ok)
  local okNoImg = pcall(function() fox.IconButton.new{ w = 32, h = 32 }:draw() end)
  check("draw without image no error", okNoImg)
end

-- ------------------------------------------------------------------- Root
do
  print("Root")

  -- A minimal contract-satisfying widget that records calls and can be told
  -- whether to consume input.
  local function fakeWidget(consume)
    local w = { consume = consume or false,
      up = 0, dr = 0, mp = 0, mr = 0, kp = 0, ti = 0 }
    function w:update() self.up = self.up + 1 end
    function w:draw() self.dr = self.dr + 1 end
    function w:mousepressed() self.mp = self.mp + 1; return self.consume end
    function w:mousereleased() self.mr = self.mr + 1; return false end
    function w:keypressed() self.kp = self.kp + 1; return self.consume end
    function w:textinput() self.ti = self.ti + 1; return self.consume end
    return w
  end

  -- update/draw forwarding
  local r = fox.Root.new()
  local a = r:add(fakeWidget(false))
  r:update(0.016); r:draw()
  check("forwards update", a.up == 1)
  check("forwards draw", a.dr == 1)

  -- press consumed sets focus
  local b = fox.Root.new()
  local hit = b:add(fakeWidget(true))
  check("consumed press returns true", b:mousepressed(1, 1, 1) == true)
  check("focus set to consumer", b.focused == hit)

  -- press hitting nothing clears focus
  b.focused = hit
  local miss = fox.Root.new()
  miss:add(fakeWidget(false))
  check("unconsumed press returns false", miss:mousepressed(1, 1, 1) == false)
  check("focus cleared on miss", miss.focused == nil)

  -- modal overlay traps input: base never sees the press
  local m = fox.Root.new()
  local baseW = m:add(fakeWidget(true))
  local modalW = fakeWidget(false)
  m:openOverlay(modalW, { modal = true })
  check("openOverlay sets root ref", modalW.root == m)
  check("modal miss still returns true", m:mousepressed(1, 1, 1) == true)
  check("modal traps base", baseW.mp == 0)
  check("modal widget got press", modalW.mp == 1)

  -- non-modal overlay miss dismisses and falls through to base
  local d = fox.Root.new()
  local under = d:add(fakeWidget(true))
  local pop = fakeWidget(false)
  d:openOverlay(pop, { modal = false })
  check("press falls through returns true", d:mousepressed(1, 1, 1) == true)
  check("non-modal overlay dismissed", #d.overlays == 0)
  check("base reached after dismiss", under.mp == 1)

  -- Esc closes the top overlay
  local e = fox.Root.new()
  e:openOverlay(fakeWidget(false), { modal = true })
  check("esc consumed", e:keypressed("escape") == true)
  check("esc closed overlay", #e.overlays == 0)

  -- keypressed routes to focused first
  local k = fox.Root.new()
  local other = k:add(fakeWidget(false))
  local focusedW = k:add(fakeWidget(true))
  k.focused = focusedW
  k:keypressed("a")
  check("key went to focused", focusedW.kp == 1)
  check("key not broadcast past focused", other.kp == 0)

  -- remove drops widget and clears focus
  local rm = fox.Root.new()
  local w1 = rm:add(fakeWidget(false))
  rm.focused = w1
  check("remove returns true", rm:remove(w1) == true)
  check("removed from base", #rm.base == 0)
  check("focus cleared on remove", rm.focused == nil)
end

-- ------------------------------------------------------------------ Panel
do
  print("Panel")
  -- Untitled panel: content origin = (x + padding, y + padding).
  local pad = fox.theme.padding
  local panel = fox.Panel.new{ x = 40, y = 40, w = 200, h = 150 }
  local btn = panel:add(fox.Button.new{ x = 10, y = 10, w = 60, h = 24 })

  -- world click over the child (local 15,15 => world 40+pad+15, 40+pad+15)
  local wx, wy = 40 + pad + 15, 40 + pad + 15
  check("press reaches child in local space", panel:mousepressed(wx, wy, 1) == true)
  check("child registered press", btn.pressed == true)
  panel:mousereleased(wx, wy, 1)

  -- click outside the child (but note panel does not consume empty space)
  check("empty panel area does not consume", panel:mousepressed(41, 41, 1) == false)

  -- nested panel composes offsets
  local outer = fox.Panel.new{ x = 100, y = 100, w = 300, h = 200 }
  local inner = fox.Panel.new{ x = 20, y = 20, w = 200, h = 120 }
  local deep = inner:add(fox.Button.new{ x = 5, y = 5, w = 40, h = 20 })
  outer:add(inner)
  -- world = outer_origin + inner_local(20,20) + inner_origin_pad + child_local(10,10)
  local ox, oy = 100 + pad, 100 + pad          -- outer content origin
  local ix, iy = ox + 20 + pad, oy + 20 + pad  -- inner content origin in world
  check("nested press reaches deep child", outer:mousepressed(ix + 10, iy + 10, 1) == true)
  check("deep child registered press", deep.pressed == true)

  local ok = pcall(function() panel:draw(); fox.Panel.new{ title = "T" }:draw() end)
  check("draw no error", ok)
end

-- ------------------------------------------------------------------ Modal
do
  print("Modal")
  local okd, cancelled = false, false
  local root = fox.Root.new()
  local modal = fox.Modal.new{ w = 300, h = 160, title = "Confirm",
    message = "Sure?",
    buttons = {
      { label = "Cancel", onClick = function() cancelled = true end },
      { label = "OK",     onClick = function() okd = true end },
    } }
  root:openOverlay(modal, { modal = true })
  modal:update(0.016)  -- runs layout, positions buttons
  check("two buttons built", #modal.buttons == 2)

  -- click the OK button (last, bottom-right)
  local ok = modal.buttons[2]
  ok:mousepressed(ok.x + 5, ok.y + 5, 1)
  ok:mousereleased(ok.x + 5, ok.y + 5, 1)
  check("OK onClick ran", okd == true)
  check("modal closed itself", #root.overlays == 0)
  check("cancel not run", cancelled == false)

  -- modal traps input routed through Root
  local r2 = fox.Root.new()
  local baseHit = r2:add((function()
    local w = { pressed = false }
    function w:update() end
    function w:draw() end
    function w:mousepressed() self.pressed = true; return true end
    function w:mousereleased() end
    function w:keypressed() return false end
    function w:textinput() return false end
    return w
  end)())
  r2:openOverlay(fox.Modal.new{ buttons = {} }, { modal = true })
  r2:mousepressed(1, 1, 1)
  check("modal blocks base widget", baseHit.pressed == false)

  local okDraw = pcall(function() modal:draw() end)
  check("draw no error", okDraw)
end

-- --------------------------------------------------------------- Dropdown
do
  print("Dropdown")
  local picked
  local root = fox.Root.new()
  local dd = root:add(fox.Dropdown.new{ x = 50, y = 50, w = 160, h = 30,
    options = { "Red", "Green", "Blue" }, onChange = function(i) picked = i end })
  check("has root ref after add", dd.root == root)
  check("default selected 1", dd.selected == 1)

  -- click trigger opens popup overlay
  check("trigger press consumes", root:mousepressed(60, 60, 1) == true)
  check("popup opened", #root.overlays == 1)

  -- click the second row (popup top y = 50+30 = 80; row 2 spans 110..140)
  root:mousepressed(60, 120, 1)
  check("selected became 2", dd.selected == 2)
  check("onChange got 2", picked == 2)
  check("popup closed after select", #root.overlays == 0)

  -- open again, click outside => dismissed, no selection change
  root:mousepressed(60, 60, 1)
  check("reopened", #root.overlays == 1)
  root:mousepressed(600, 400, 1)
  check("outside click dismisses popup", #root.overlays == 0)
  check("selection unchanged on dismiss", dd.selected == 2)

  local okDraw = pcall(function()
    dd:draw()
    root:mousepressed(60, 60, 1)          -- reopen for popup draw
    root.overlays[1].widget:update(0.016)
    root.overlays[1].widget:draw()
  end)
  check("draw no error", okDraw)
end

-- ---------------------------------------------------------------- Tooltip
do
  print("Tooltip")
  local tip = fox.Tooltip.new{ target = { x = 10, y = 10, w = 40, h = 20 },
    text = "hi", delay = 0.5 }
  love_stub.setMouse(20, 15)  -- inside target
  tip:update(0.3)
  check("not visible before delay", tip.visible == false)
  tip:update(0.3)             -- total 0.6 >= 0.5
  check("visible after delay", tip.visible == true)
  love_stub.setMouse(200, 200)  -- leave target
  tip:update(0.1)
  check("hidden on leave", tip.visible == false)
  check("hover time reset", tip.hoverTime == 0)
  check("never consumes press", tip:mousepressed(20, 15, 1) == false)
  local okDraw = pcall(function() tip.visible = true; tip:draw() end)
  check("draw no error", okDraw)
end

-- ------------------------------------------------------------------- Tabs
do
  print("Tabs")
  -- Panels used as tab bodies; they record whether they were drawn/pressed.
  local function fakePanel()
    local p = { pressed = false }
    function p:update() end
    function p:draw() end
    function p:mousepressed() self.pressed = true; return true end
    function p:mousereleased() end
    function p:keypressed() return false end
    function p:textinput() return false end
    return p
  end
  local p1, p2 = fakePanel(), fakePanel()
  local switched
  local tabs = fox.Tabs.new{ x = 0, y = 0, w = 200, headerH = 30,
    tabs = { { label = "A", panel = p1 }, { label = "B", panel = p2 } },
    onChange = function(i) switched = i end }
  check("default selected 1", tabs.selected == 1)
  check("current is panel 1", tabs:current() == p1)

  -- click the second header segment (x 100..200, y 0..30)
  check("header click consumes", tabs:mousepressed(150, 15, 1) == true)
  check("switched to 2", tabs.selected == 2)
  check("onChange got 2", switched == 2)
  check("current is panel 2", tabs:current() == p2)

  -- click below the header routes to the active panel
  tabs:mousepressed(50, 100, 1)
  check("body press routed to active panel", p2.pressed == true)
  check("inactive panel untouched", p1.pressed == false)

  local ok = pcall(function() tabs:draw() end)
  check("draw no error", ok)
end

-- ---------------------------------------------------------------- ListBox
do
  print("ListBox")
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
end

-- ------------------------------------------------- Focus traversal (Root)
do
  print("Focus traversal")
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

-- ---------------------------------------------- Keyboard activation (widgets)
do
  print("Keyboard activation")
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

-- ------------------------------------------------------ Wheel scroll
do
  print("Wheel scroll")
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

-- ------------------------------------------------------ Hover feedback
do
  print("Hover feedback")
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
end

-- --------------------------------------- Textbox caret-by-click + hscroll
do
  print("Textbox caret/scroll")
  -- Font stub: 7px per char, padding 8. Box x = 0.
  local tb = fox.Textbox.new{ x = 0, y = 0, w = 200, h = 30 }
  tb:mousepressed(5, 5, 1)      -- focus (empty)
  tb:textinput("Hello")         -- caret at 5
  check("caret at end after typing", tb.caret == 5)
  -- Click near character 2: rel = px - pad; caret 2 center = (7 + 14)/2 = 10.5,
  -- caret 3 boundary at (14+21)/2 = 17.5, so px = pad + 14 = 22 lands on caret 2.
  tb:mousepressed(22, 5, 1)
  check("click places caret mid-string", tb.caret == 2)
  -- Click far left snaps caret to 0.
  tb:mousepressed(2, 5, 1)
  check("click far left caret 0", tb.caret == 0)

  -- Horizontal scroll: narrow box, text longer than the view, caret at end.
  local nb = fox.Textbox.new{ x = 0, y = 0, w = 50, h = 30 }
  nb:mousepressed(5, 5, 1)
  nb:textinput("AAAAAAAAAA")     -- 10 chars * 7 = 70px; view = 50 - 16 = 34
  check("scrollX tracks caret past view", nb.scrollX == 70 - 34)
  -- Home resets caret and scroll back to the left.
  nb:keypressed("home")
  check("home scrolls back to start", nb.scrollX == 0)

  local ok = pcall(function() nb.focused = true; nb:draw() end)
  check("draw with scroll no error", ok)
end

-- ------------------------------------------------ ListBox keyboard nav
do
  print("ListBox keyboard")
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

-- ---------------------------------------------- RadioGroup keyboard + hover
do
  print("RadioGroup keyboard")
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

-- --------------------------------------------------- Tabs keyboard
do
  print("Tabs keyboard")
  local function fakePanel(consumeKey)
    local p = { pressed = false }
    function p:update() end
    function p:draw() end
    function p:mousepressed() return false end
    function p:mousereleased() end
    function p:keypressed(k) return consumeKey ~= nil and k == consumeKey end
    function p:textinput() return false end
    return p
  end
  local switched
  local r = fox.Root.new()
  local tabs = r:add(fox.Tabs.new{ x = 0, y = 0, w = 300, headerH = 30,
    tabs = { { label = "A", panel = fakePanel() },
             { label = "B", panel = fakePanel() },
             { label = "C", panel = fakePanel() } },
    onChange = function(i) switched = i end })
  r:setFocus(tabs)
  tabs:keypressed("right")
  check("right switches to 2", tabs.selected == 2 and switched == 2)
  tabs:keypressed("left")
  check("left switches to 1", tabs.selected == 1)
  tabs:keypressed("end")
  check("end selects last", tabs.selected == 3)
  tabs:keypressed("home")
  check("home selects first", tabs.selected == 1)

  -- Active panel gets first refusal: a panel that consumes "right" blocks switch.
  local r2 = fox.Root.new()
  local blocker = r2:add(fox.Tabs.new{ x = 0, y = 0, w = 300, headerH = 30,
    tabs = { { label = "A", panel = fakePanel("right") },
             { label = "B", panel = fakePanel("right") } } })
  r2:setFocus(blocker)
  blocker:keypressed("right")
  check("panel consumes key, no tab switch", blocker.selected == 1)
end

-- ------------------------------------------------ Modal focus trap
do
  print("Modal focus trap")
  local bgClicks, primary = 0, false
  local r = fox.Root.new()
  -- A focusable background button that must NOT receive keys while modal open.
  local bg = r:add(fox.Button.new{ x = 0, y = 0, w = 40, h = 20,
    onClick = function() bgClicks = bgClicks + 1 end })
  r:setFocus(bg)

  local modal = fox.Modal.new{ buttons = {
    { label = "Cancel" },
    { label = "OK", onClick = function() primary = true end },
  } }
  r:openOverlay(modal, { modal = true })
  check("default focus on primary (last) button", modal.focusIndex == 2)

  -- Enter activates the default button, not the background one.
  r:keypressed("return")
  check("enter fired primary", primary == true)
  check("background button not fired", bgClicks == 0)
  check("modal closed after activate", #r.overlays == 0)

  -- Tab cycles focus between buttons; Shift-Tab reverses.
  local r2 = fox.Root.new()
  local m2 = fox.Modal.new{ buttons = {
    { label = "One" }, { label = "Two" }, { label = "Three" } } }
  r2:openOverlay(m2, { modal = true })
  check("starts on last", m2.focusIndex == 3)
  r2:keypressed("tab")
  check("tab wraps to first", m2.focusIndex == 1)
  r2:keypressed("tab")
  check("tab advances", m2.focusIndex == 2)
  love_stub.setKey("lshift", true)
  r2:keypressed("tab")
  check("shift-tab reverses", m2.focusIndex == 1)
  love_stub.setKey("lshift", false)

  -- Space activates the focused (first) button.
  local activated
  local r3 = fox.Root.new()
  local m3 = fox.Modal.new{ buttons = {
    { label = "Go", onClick = function() activated = "go" end },
    { label = "No" } } }
  r3:openOverlay(m3, { modal = true })
  m3.focusIndex = 1
  r3:keypressed("space")
  check("space activates focused button", activated == "go")
end

-- ------------------------------------- Dropdown popup flip + scroll
do
  print("Dropdown popup layout")
  -- Screen is 800x600 in the stub. A dropdown near the bottom flips its popup up.
  local r = fox.Root.new()
  local dd = r:add(fox.Dropdown.new{ x = 10, y = 580, w = 120, h = 30,
    options = { "a", "b", "c" } })
  r:mousepressed(15, 585, 1)          -- open
  local pop = r.overlays[1].widget
  check("popup flipped above trigger", pop.y < dd.y)
  check("popup fits its full height", pop.h == 3 * 30)
  r:closeOverlay()

  -- Many options, fits neither side: height capped and scrollable.
  local many = {}
  for i = 1, 30 do many[i] = "opt" .. i end
  local r2 = fox.Root.new()
  r2:add(fox.Dropdown.new{ x = 10, y = 300, w = 120, h = 30,
    options = many, selected = 1 })
  r2:mousepressed(15, 305, 1)
  local pop2 = r2.overlays[1].widget
  check("popup height capped to gap", pop2.h < pop2.fullH)
  check("popup scrollable", pop2:maxScroll() > 0)

  -- Wheel over the popup scrolls it.
  love_stub.setMouse(15, pop2.y + 10)
  check("wheel scrolls popup", pop2:wheelmoved(0, -1) == true)
  check("scroll advanced", pop2.scroll > 0)

  local ok = pcall(function() pop2:update(0.016); pop2:draw() end)
  check("draw scrolled popup no error", ok)
  love_stub.setMouse(0, 0)
end

print(string.format("\n%d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
