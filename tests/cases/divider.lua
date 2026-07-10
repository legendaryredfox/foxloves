local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Divider")
  local d = fox.Divider.new{ x = 0, y = 0, length = 50 }
  check("mousepressed ignored", d:mousepressed(0, 0, 1) == false)
  local ok = pcall(function() d:draw(); fox.Divider.new{ vertical = true }:draw() end)
  check("draw no error", ok)
end
