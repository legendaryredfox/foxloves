local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("ProgressBar")
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
