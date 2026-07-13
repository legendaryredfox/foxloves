local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("NumberField")

  local changed
  local nf = fox.NumberField.new{ x = 0, y = 0, w = 120, h = 32,
    value = 5, min = 0, max = 10, step = 2,
    onChange = function(v) changed = v end }
  check("initial value", nf.value == 5)
  check("initial text", nf.tb.value == "5")

  -- Constructor clamps an out-of-range initial value.
  local clamped = fox.NumberField.new{ value = 99, min = 0, max = 10 }
  check("initial value clamped", clamped.value == 10)

  -- Up/Down step by `step`, clamped to bounds. Needs focus.
  nf.tb.focused = true
  nf:keypressed("up")
  check("up steps by step", nf.value == 7)
  check("up fires onChange", changed == 7)
  nf:keypressed("up")   -- 9
  nf:keypressed("up")   -- would be 11 -> clamp 10
  check("up clamps to max", nf.value == 10)
  nf:keypressed("down"); nf:keypressed("down"); nf:keypressed("down"); nf:keypressed("down")
  nf:keypressed("down"); nf:keypressed("down")  -- drive well below 0
  check("down clamps to min", nf.value == 0)

  -- textinput filter: digits accepted, letters rejected, value unchanged text.
  local nf2 = fox.NumberField.new{ value = 0, min = -100, max = 100 }
  nf2.tb.focused = true
  nf2.tb.value = ""; nf2.tb.caret = 0
  check("digit accepted", nf2:textinput("4") == true and nf2.tb.value == "4")
  check("letter rejected", nf2:textinput("a") == true and nf2.tb.value == "4")
  check("second dot rejected after dot", (function()
    nf2:textinput("."); nf2:textinput("2"); local before = nf2.tb.value
    nf2:textinput("."); return nf2.tb.value == before
  end)())
  -- '-' only at start.
  nf2.tb.value = "5"; nf2.tb.caret = 1
  nf2:textinput("-")
  check("minus rejected mid-number", nf2.tb.value == "5")
  nf2.tb.value = ""; nf2.tb.caret = 0
  nf2:textinput("-")
  check("leading minus accepted", nf2.tb.value == "-")

  -- Commit parses + clamps the typed text on blur.
  local nf3 = fox.NumberField.new{ value = 0, min = 0, max = 50 }
  nf3.tb.focused = true
  nf3.tb.value = "80"
  nf3:setFocused(false)
  check("commit clamps typed value", nf3.value == 50 and nf3.tb.value == "50")

  -- Invalid/empty entry reverts to the last value on commit.
  local nf4 = fox.NumberField.new{ value = 7 }
  nf4.tb.focused = true
  nf4.tb.value = ""
  nf4:setFocused(false)
  check("empty reverts to last value", nf4.value == 7 and nf4.tb.value == "7")

  -- Wheel nudges when focused.
  local nf5 = fox.NumberField.new{ value = 0, step = 3 }
  nf5.tb.focused = true
  check("wheel up nudges", nf5:wheelmoved(0, 1) == true and nf5.value == 3)
  check("wheel down nudges", nf5:wheelmoved(0, -1) == true and nf5.value == 0)

  -- setValue clamps + emits.
  local got
  local nf6 = fox.NumberField.new{ value = 0, min = 0, max = 5,
    onChange = function(v) got = v end }
  nf6:setValue(9)
  check("setValue clamps", nf6.value == 5 and got == 5)

  check("draw no error", pcall(function() nf:draw() end))
end
