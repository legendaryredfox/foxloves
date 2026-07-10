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
