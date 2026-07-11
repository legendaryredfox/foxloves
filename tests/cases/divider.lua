local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Divider")
  local d = fox.Divider.new{ x = 0, y = 0, length = 50 }
  check("mousepressed ignored", d:mousepressed(0, 0, 1) == false)
  local ok = pcall(function() d:draw(); fox.Divider.new{ vertical = true }:draw() end)
  check("draw no error", ok)
end

do
  h.section("Divider label")
  local d = fox.Divider.new{ x = 0, y = 0, length = 200, label = "OR" }
  check("holds label", d.label == "OR")
  -- Draws split-line + text path, and a too-short line still draws cleanly.
  local ok = pcall(function()
    d:draw()
    fox.Divider.new{ x = 0, y = 0, length = 10, label = "very long label" }:draw()
    -- Vertical ignores the label and takes the plain path.
    fox.Divider.new{ x = 0, y = 0, length = 50, vertical = true, label = "OR" }:draw()
  end)
  check("draw labeled no error", ok)
end
