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

  -- Animated fill eases toward the target fraction over update(dt).
  local a = fox.ProgressBar.new{ w = 100, h = 10, value = 0 }
  check("display starts settled", a.display == 0)
  a.value = 1
  check("display not yet moved", a.display == 0)
  a:update(0.1)
  check("display eases up", a.display > 0 and a.display < 1)
  for _ = 1, 100 do a:update(0.1) end
  check("display reaches target", a.display == 1)
  a.value = 0
  for _ = 1, 100 do a:update(0.1) end
  check("display eases back down", a.display == 0)

  -- animated == false snaps instantly.
  local s = fox.ProgressBar.new{ w = 100, h = 10, value = 0, animated = false }
  s.value = 1
  s:update(0.001)
  check("non-animated snaps", s.display == 1)
end
