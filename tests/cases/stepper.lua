local h = require("tests.harness")
local fox, check, love_stub = h.fox, h.check, h.love_stub

do
  h.section("Stepper")
  local v
  local st = fox.Stepper.new{ x = 0, y = 0, w = 120, h = 30, value = 5, step = 1,
    min = 0, max = 10, onChange = function(nv) v = nv end }
  check("initial value", st.value == 5)
  -- plus button is the right square (x = 90..120)
  st:mousepressed(105, 10, 1); st:mousereleased(105, 10, 1)
  check("plus increments", st.value == 6)
  check("onChange got 6", v == 6)
  -- minus button is the left square (x = 0..30)
  st:mousepressed(15, 10, 1); st:mousereleased(15, 10, 1)
  check("minus decrements", st.value == 5)
  -- clamp at max
  local cap = fox.Stepper.new{ x = 0, w = 120, h = 30, value = 10, max = 10 }
  cap:mousepressed(105, 10, 1); cap:mousereleased(105, 10, 1)
  check("clamped at max", cap.value == 10)
  local ok = pcall(function() st:draw() end)
  check("draw no error", ok)
end

do
  h.section("Stepper hold/keyboard/disabled")
  local st = fox.Stepper.new{ x = 0, y = 0, w = 120, h = 30, value = 0, step = 1,
    max = 100 }

  -- Press-and-hold on plus: one bump on press, then repeats after the delay.
  st:mousepressed(105, 15, 1)
  check("press bumps once", st.value == 1)
  love_stub.setMouseDown(1, true); love_stub.setMouse(105, 15)
  st:update(0.4)               -- reach REPEAT_DELAY -> one repeat
  check("hold repeats after delay", st.value == 2)
  st:update(0.06 * 3)          -- three more repeats
  check("repeats continue while held", st.value == 5)
  -- Releasing stops the repeat.
  love_stub.setMouseDown(1, false)
  st:mousereleased(105, 15, 1)
  local held = st.value
  st:update(1.0)
  check("no repeat after release", st.value == held)

  -- Cursor leaving the button stops repeat even while the button stays down.
  st:mousepressed(105, 15, 1)  -- bumps once -> held + 1
  love_stub.setMouseDown(1, true); love_stub.setMouse(500, 500)
  st:update(0.5)
  check("repeat stops when cursor leaves", st.value == held + 1)
  love_stub.setMouseDown(1, false); st:mousereleased(500, 500, 1)

  -- Keyboard stepping when focused.
  local r = fox.Root.new()
  local sk = r:add(fox.Stepper.new{ x = 0, y = 0, w = 120, h = 30, value = 0, step = 2 })
  r:setFocus(sk)
  sk:keypressed("up")
  check("up steps by step", sk.value == 2)
  sk:keypressed("down")
  check("down steps by step", sk.value == 0)

  -- setDisabled propagates to the child buttons (constructor only snapshotted it).
  st:setDisabled(true)
  check("stepper disabled", st.disabled == true)
  check("minus button disabled", st.minus.disabled == true)
  check("plus button disabled", st.plus.disabled == true)
  check("disabled press ignored", st:mousepressed(105, 15, 1) == false)
  st:setDisabled(false)
  check("re-enabled propagates to buttons", st.plus.disabled == false)
  love_stub.setMouse(0, 0)
end
