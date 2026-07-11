local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Badge")

  -- Self-sizes to text: font is 7px/char wide, 14px tall; padding is 8.
  -- w = hpad(8) + textW + hpad(8); h = textH(14) + vpad(4)*2.
  local b = fox.Badge.new{ x = 0, y = 0, text = "hi" }
  local mw, mh = b:measure()
  check("measure width fits text", mw == 8 + (#"hi" * 7) + 8)
  check("measure height fits font", mh == 14 + 8)
  check("measure equals w/h fields", mw == b.w and mh == b.h)

  -- setText re-measures.
  b:setText("longer")
  check("setText re-measures width", b.w == 8 + (#"longer" * 7) + 8)

  -- Non-removable badge is inert: consumes nothing.
  check("static press consumes nothing", b:mousepressed(5, 5, 1) == false)
  check("static release consumes nothing", b:mousereleased(5, 5, 1) == false)
  check("static keypressed inert", b:keypressed("space") == false)

  -- Removable chip: × hitbox sits on the right; clicking it fires onRemove.
  local removed = 0
  local chip = fox.Badge.new{ x = 0, y = 0, text = "x", removable = true,
    onRemove = function() removed = removed + 1 end }
  -- × square is textH(14) wide at the right, inset by hpad; centered vertically.
  local cx = chip.w - 8 - 14 / 2   -- center of the × hitbox
  local cy = chip.h / 2
  check("press on x consumes", chip:mousepressed(cx, cy, 1) == true)
  chip:mousereleased(cx, cy, 1)
  check("onRemove fired", removed == 1)

  -- Press on the label body (left of ×) is inert.
  check("press on body inert", chip:mousepressed(3, cy, 1) == false)

  -- Press on x then release outside does not fire.
  chip:mousepressed(cx, cy, 1)
  chip:mousereleased(900, 900, 1)
  check("release outside no remove", removed == 1)

  -- x hover tracked via mousemoved.
  chip:mousemoved(cx, cy)
  check("x hover true", chip.removeHovered == true)
  chip:mousemoved(3, cy)
  check("x hover false off button", chip.removeHovered == false)

  -- Draw does not error (static and removable).
  check("static draw no error", pcall(function() b:draw() end))
  check("removable draw no error", pcall(function() chip:draw() end))
end
