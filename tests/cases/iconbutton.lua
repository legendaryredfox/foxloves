local h = require("tests.harness")
local fox, check, love_stub = h.fox, h.check, h.love_stub

do
  h.section("IconButton")
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
