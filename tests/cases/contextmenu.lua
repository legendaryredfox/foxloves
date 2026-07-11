local h = require("tests.harness")
local fox, check, love_stub = h.fox, h.check, h.love_stub

do
  h.section("ContextMenu")
  local ran
  local root = fox.Root.new()
  local menu = root:add(fox.ContextMenu.new{
    target = { x = 100, y = 100, w = 200, h = 150 },
    items = {
      { label = "Cut",   onClick = function() ran = "cut" end },
      { label = "Copy",  onClick = function() ran = "copy" end, enabled = false },
      { separator = true },
      { label = "Paste", onClick = function() ran = "paste" end },
    },
  })
  check("has root ref after add", menu.root == root)

  -- left-click in the target does not open the menu
  check("left-click ignored", root:mousepressed(150, 150, 1) == false)
  check("no overlay from left-click", #root.overlays == 0)

  -- right-click in the target opens the popup at the cursor
  check("right-click consumes", root:mousepressed(150, 150, 2) == true)
  check("popup opened", #root.overlays == 1)
  local pop = root.overlays[1].widget
  check("popup anchored at cursor x", pop.x == 150)
  check("popup anchored at cursor y", pop.y == 150)

  -- click the enabled "Cut" row (first row)
  root:mousepressed(pop.x + 5, pop:rowTop(1) + 2, 1)
  check("Cut ran", ran == "cut")
  check("popup closed after activate", #root.overlays == 0)

  -- disabled row is not selectable and keeps the menu open
  root:mousepressed(150, 150, 2)
  pop = root.overlays[1].widget
  ran = nil
  root:mousepressed(pop.x + 5, pop:rowTop(2) + 2, 1)
  check("disabled row does not run", ran == nil)
  check("menu stays open on disabled click", #root.overlays == 1)

  -- click outside dismisses (Root handles non-modal miss)
  root:mousepressed(700, 500, 1)
  check("outside click dismisses", #root.overlays == 0)
end

do
  h.section("ContextMenu keyboard")
  local ran
  local root = fox.Root.new()
  local menu = root:add(fox.ContextMenu.new{
    items = {
      { label = "One",   onClick = function() ran = 1 end },
      { label = "Two",   onClick = function() ran = 2 end, enabled = false },
      { label = "Three", onClick = function() ran = 3 end },
    },
  })
  menu:openAt(40, 40)
  local pop = root.overlays[1].widget

  -- Down lands on first selectable, Down again skips the disabled row
  root:keypressed("down")
  check("first down highlights row 1", pop.active == 1)
  root:keypressed("down")
  check("second down skips disabled to row 3", pop.active == 3)
  root:keypressed("return")
  check("Enter activates row 3", ran == 3)
  check("popup closed after Enter", #root.overlays == 0)

  -- Esc closes an open menu (Root closes the top overlay)
  menu:openAt(40, 40)
  root:keypressed("escape")
  check("Esc closes menu", #root.overlays == 0)
end

do
  h.section("ContextMenu clamps on screen")
  -- Stub screen is 800x600. Opening near the bottom-right corner shifts the
  -- menu back so it stays fully visible.
  local root = fox.Root.new()
  local menu = root:add(fox.ContextMenu.new{
    items = { { label = "A" }, { label = "B" }, { label = "C" } },
  })
  menu:openAt(790, 590)
  local pop = root.overlays[1].widget
  check("clamped inside right edge", pop.x + pop.w <= 800)
  check("clamped inside bottom edge", pop.y + pop.h <= 600)

  local ok = pcall(function() pop:update(0.016); pop:draw() end)
  check("draw no error", ok)
  root:closeOverlay()
end
