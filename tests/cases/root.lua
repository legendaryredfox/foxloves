local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Root")

  -- A minimal contract-satisfying widget that records calls and can be told
  -- whether to consume input.
  local function fakeWidget(consume)
    local w = { consume = consume or false,
      up = 0, dr = 0, mp = 0, mr = 0, kp = 0, ti = 0 }
    function w:update() self.up = self.up + 1 end
    function w:draw() self.dr = self.dr + 1 end
    function w:mousepressed() self.mp = self.mp + 1; return self.consume end
    function w:mousereleased() self.mr = self.mr + 1; return false end
    function w:keypressed() self.kp = self.kp + 1; return self.consume end
    function w:textinput() self.ti = self.ti + 1; return self.consume end
    return w
  end

  -- update/draw forwarding
  local r = fox.Root.new()
  local a = r:add(fakeWidget(false))
  r:update(0.016); r:draw()
  check("forwards update", a.up == 1)
  check("forwards draw", a.dr == 1)

  -- press consumed sets focus
  local b = fox.Root.new()
  local hit = b:add(fakeWidget(true))
  check("consumed press returns true", b:mousepressed(1, 1, 1) == true)
  check("focus set to consumer", b.focused == hit)

  -- press hitting nothing clears focus
  b.focused = hit
  local miss = fox.Root.new()
  miss:add(fakeWidget(false))
  check("unconsumed press returns false", miss:mousepressed(1, 1, 1) == false)
  check("focus cleared on miss", miss.focused == nil)

  -- modal overlay traps input: base never sees the press
  local m = fox.Root.new()
  local baseW = m:add(fakeWidget(true))
  local modalW = fakeWidget(false)
  m:openOverlay(modalW, { modal = true })
  check("openOverlay sets root ref", modalW.root == m)
  check("modal miss still returns true", m:mousepressed(1, 1, 1) == true)
  check("modal traps base", baseW.mp == 0)
  check("modal widget got press", modalW.mp == 1)

  -- non-modal overlay miss dismisses and falls through to base
  local d = fox.Root.new()
  local under = d:add(fakeWidget(true))
  local pop = fakeWidget(false)
  d:openOverlay(pop, { modal = false })
  check("press falls through returns true", d:mousepressed(1, 1, 1) == true)
  check("non-modal overlay dismissed", #d.overlays == 0)
  check("base reached after dismiss", under.mp == 1)

  -- Esc closes the top overlay
  local e = fox.Root.new()
  e:openOverlay(fakeWidget(false), { modal = true })
  check("esc consumed", e:keypressed("escape") == true)
  check("esc closed overlay", #e.overlays == 0)

  -- keypressed routes to focused first
  local k = fox.Root.new()
  local other = k:add(fakeWidget(false))
  local focusedW = k:add(fakeWidget(true))
  k.focused = focusedW
  k:keypressed("a")
  check("key went to focused", focusedW.kp == 1)
  check("key not broadcast past focused", other.kp == 0)

  -- remove drops widget and clears focus
  local rm = fox.Root.new()
  local w1 = rm:add(fakeWidget(false))
  rm.focused = w1
  check("remove returns true", rm:remove(w1) == true)
  check("removed from base", #rm.base == 0)
  check("focus cleared on remove", rm.focused == nil)
end
