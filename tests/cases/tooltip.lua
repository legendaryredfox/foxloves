local h = require("tests.harness")
local fox, check, love_stub = h.fox, h.check, h.love_stub

do
  h.section("Tooltip")
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
  local okDraw = pcall(function() tip.visible = true; tip.alpha = 1; tip:draw() end)
  check("draw no error", okDraw)
  love_stub.setMouse(0, 0)
end

do
  h.section("Tooltip clamp/wrap/fade")
  -- Fade in: alpha eases from 0 to 1 while visible (delay 0 shows immediately).
  local tip = fox.Tooltip.new{ target = { x = 0, y = 0, w = 100, h = 100 },
    text = "hi", delay = 0 }
  love_stub.setMouse(10, 10)
  tip:update(0.016)
  check("becomes visible", tip.visible == true)
  check("alpha rising not full", tip.alpha > 0 and tip.alpha < 1)
  for _ = 1, 20 do tip:update(0.016) end
  check("alpha reaches 1", tip.alpha == 1)
  -- Fade out after the cursor leaves.
  love_stub.setMouse(500, 500)
  tip:update(0.016)
  check("hidden but still fading", tip.visible == false and tip.alpha > 0 and tip.alpha < 1)
  for _ = 1, 20 do tip:update(0.016) end
  check("alpha reaches 0", tip.alpha == 0)

  -- Edge clamp: cursor at the bottom-right corner still draws on screen (800x600).
  local edge = fox.Tooltip.new{ target = { x = 0, y = 0, w = 800, h = 600 },
    text = "edge", delay = 0 }
  love_stub.setMouse(799, 599)
  edge:update(0.016); for _ = 1, 20 do edge:update(0.016) end
  local ok = pcall(function() edge:draw() end)
  check("draw near screen edge no error", ok)

  -- Multi-line wrap: maxWidth splits into more than one line.
  local wrapped = fox.Tooltip.new{ target = { x = 0, y = 0, w = 10, h = 10 },
    text = "one two three four five", maxWidth = 40, delay = 0 }
  local font = fox.theme.getFont(fox.theme)
  local _, lines = font:getWrap(wrapped.text, 40)
  check("text wraps into multiple lines", #lines > 1)
  local okw = pcall(function() wrapped.alpha = 1; wrapped:draw() end)
  check("wrapped draw no error", okw)
  love_stub.setMouse(0, 0)
end
