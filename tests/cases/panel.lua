local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Panel")
  -- Untitled panel: content origin = (x + padding, y + padding).
  local pad = fox.theme.padding
  local panel = fox.Panel.new{ x = 40, y = 40, w = 200, h = 150 }
  local btn = panel:add(fox.Button.new{ x = 10, y = 10, w = 60, h = 24 })

  -- world click over the child (local 15,15 => world 40+pad+15, 40+pad+15)
  local wx, wy = 40 + pad + 15, 40 + pad + 15
  check("press reaches child in local space", panel:mousepressed(wx, wy, 1) == true)
  check("child registered press", btn.pressed == true)
  panel:mousereleased(wx, wy, 1)

  -- click outside the child (but note panel does not consume empty space)
  check("empty panel area does not consume", panel:mousepressed(41, 41, 1) == false)

  -- nested panel composes offsets
  local outer = fox.Panel.new{ x = 100, y = 100, w = 300, h = 200 }
  local inner = fox.Panel.new{ x = 20, y = 20, w = 200, h = 120 }
  local deep = inner:add(fox.Button.new{ x = 5, y = 5, w = 40, h = 20 })
  outer:add(inner)
  -- world = outer_origin + inner_local(20,20) + inner_origin_pad + child_local(10,10)
  local ox, oy = 100 + pad, 100 + pad          -- outer content origin
  local ix, iy = ox + 20 + pad, oy + 20 + pad  -- inner content origin in world
  check("nested press reaches deep child", outer:mousepressed(ix + 10, iy + 10, 1) == true)
  check("deep child registered press", deep.pressed == true)

  local ok = pcall(function() panel:draw(); fox.Panel.new{ title = "T" }:draw() end)
  check("draw no error", ok)
end
