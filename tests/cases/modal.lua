local h = require("tests.harness")
local fox, check, love_stub = h.fox, h.check, h.love_stub

do
  h.section("Modal")
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

do
  h.section("Modal focus trap")
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

do
  h.section("Modal closable ×")
  local root = fox.Root.new()
  local m = fox.Modal.new{ w = 300, h = 160, title = "Info", closable = true }
  root:openOverlay(m, { modal = true })
  m:update(0.016)                       -- runs layout, positions the panel
  check("overlay open", #root.overlays == 1)

  local cx, cy, cw, ch = m:_closeRect()
  check("close rect exists when closable", cx ~= nil)
  -- a press on the × dismisses the modal
  root:mousepressed(cx + cw / 2, cy + ch / 2, 1)
  check("× press closes modal", #root.overlays == 0)

  -- non-closable modal exposes no close rect
  local plain = fox.Modal.new{ closable = false }
  check("no close rect when not closable", plain:_closeRect() == nil)

  local ok = pcall(function()
    local r2 = fox.Root.new()
    local m2 = fox.Modal.new{ closable = true, title = "X" }
    r2:openOverlay(m2, { modal = true })
    m2:update(0.016); m2:draw()
  end)
  check("draw closable no error", ok)
end
