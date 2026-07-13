local h = require("tests.harness")
local fox, check, love_stub = h.fox, h.check, h.love_stub

do
  h.section("Dropdown")
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
  root:closeOverlay()
end

do
  h.section("Dropdown popup layout")
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

do
  h.section("Dropdown placeholder")
  -- selected out of range shows the muted placeholder, not an empty label.
  local dd = fox.Dropdown.new{ x = 0, y = 0, options = { "One", "Two" },
    selected = 0, placeholder = "Pick one" }  -- 0 = out of range = nothing chosen
  local text, muted = dd:_displayLabel()
  check("placeholder shown when unselected", text == "Pick one")
  check("placeholder is muted", muted == true)

  -- A valid selection shows the option in normal (non-muted) text.
  dd.selected = 2
  text, muted = dd:_displayLabel()
  check("option shown when selected", text == "Two")
  check("selected option not muted", muted == false)

  -- Out-of-range index (past the end) also falls back to the placeholder.
  dd.selected = 9
  text, muted = dd:_displayLabel()
  check("out-of-range falls back to placeholder", text == "Pick one" and muted == true)

  check("draw with placeholder no error", pcall(function()
    dd.selected = nil; dd:draw()
  end))
end
