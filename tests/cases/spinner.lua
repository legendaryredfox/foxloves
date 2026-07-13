local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Spinner")

  local s = fox.Spinner.new{ x = 0, y = 0, size = 24, dots = 8, speed = 1 }
  check("measure equals size", (function() local w, hh = s:measure(); return w == 24 and hh == 24 end)())
  check("w/h fields match size", s.w == 24 and s.h == 24)
  check("phase starts at zero", s.phase == 0)

  -- update advances phase by speed*dt, wrapping at 1.
  s:update(0.5)
  check("phase advanced", math.abs(s.phase - 0.5) < 1e-9)
  s:update(0.75)
  check("phase wraps past 1", math.abs(s.phase - 0.25) < 1e-9)

  -- speed scales the advance.
  local fast = fox.Spinner.new{ speed = 2 }
  fast:update(0.25)
  check("speed scales phase", math.abs(fast.phase - 0.5) < 1e-9)

  -- Non-interactive: consumes nothing.
  check("press inert", s:mousepressed(5, 5, 1) == false)
  check("keypressed inert", s:keypressed("space") == false)

  -- Draw does not error at a few phases.
  check("draw no error", pcall(function()
    s.phase = 0; s:draw(); s.phase = 0.4; s:draw()
  end))
end
