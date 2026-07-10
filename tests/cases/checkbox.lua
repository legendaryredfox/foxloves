local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Checkbox")
  local changed
  local c = fox.Checkbox.new{ x = 0, y = 0, size = 20, label = "on",
    onChange = function(v) changed = v end }
  check("starts unchecked", c.checked == false)
  check("press inside consumes", c:mousepressed(5, 5, 1) == true)
  c:mousereleased(5, 5, 1)
  check("toggled on", c.checked == true)
  check("onChange got true", changed == true)
  c:mousepressed(5, 5, 1); c:mousereleased(5, 5, 1)
  check("toggled off", c.checked == false)
  -- press inside, release outside: no toggle
  c:mousepressed(5, 5, 1); c:mousereleased(900, 900, 1)
  check("release outside no toggle", c.checked == false)
  -- disabled ignores
  local dc = fox.Checkbox.new{ disabled = true }
  check("disabled press ignored", dc:mousepressed(5, 5, 1) == false)
  local ok = pcall(function() c.checked = true; c:draw() end)
  check("draw no error", ok)
end
