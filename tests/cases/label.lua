local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Label")
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

do
  h.section("Label truncation")
  -- Stub font is 7px/char. A 40px box holds ~5 chars; a long string truncates.
  local ell = "\226\128\166"  -- "…"
  local long = fox.Label.new{ x = 0, y = 0, w = 40, text = "abcdefghij", truncate = true }
  local f = love.graphics.getFont()
  local out = long:_truncate(f, long.text)
  check("truncated ends with ellipsis", out:sub(-#ell) == ell)
  check("truncated fits width", f:getWidth(out) <= long.w)

  -- Short text within width is returned unchanged.
  local short = fox.Label.new{ x = 0, y = 0, w = 200, text = "hi", truncate = true }
  check("short text unchanged", short:_truncate(f, short.text) == "hi")

  local ok = pcall(function() long:draw() end)
  check("draw truncated no error", ok)
end
