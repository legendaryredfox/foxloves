local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Button")
  local clicks = 0
  local b = fox.Button.new{ x = 10, y = 10, w = 100, h = 30,
    onClick = function() clicks = clicks + 1 end }

  check("contains inside", b:contains(20, 20))
  check("contains outside", not b:contains(200, 200))

  -- press + release inside fires onClick
  check("press inside consumes", b:mousepressed(20, 20, 1) == true)
  check("pressed state set", b.pressed == true)
  b:mousereleased(20, 20, 1)
  check("onClick fired once", clicks == 1)
  check("pressed cleared", b.pressed == false)

  -- press inside, release outside: no click
  b:mousepressed(20, 20, 1)
  b:mousereleased(500, 500, 1)
  check("release outside no click", clicks == 1)

  -- right button ignored
  check("right button ignored", b:mousepressed(20, 20, 2) == false)

  -- hover is event-driven via mousemoved (local coordinates)
  b:mousemoved(20, 20)
  check("hover true over widget", b.hovered == true)
  b:mousemoved(300, 300)
  check("hover false off widget", b.hovered == false)

  -- disabled swallows nothing
  local db = fox.Button.new{ x = 0, y = 0, w = 50, h = 20,
    disabled = true, onClick = function() clicks = clicks + 1 end }
  check("disabled press ignored", db:mousepressed(10, 10, 1) == false)
  db:mousereleased(10, 10, 1)
  check("disabled no click", clicks == 1)
  db:mousemoved(10, 10)
  check("disabled never hovers", db.hovered == false)

  -- draw smoke test (must not error)
  local okDraw = pcall(function() b:draw() end)
  check("draw does not error", okDraw)
end
