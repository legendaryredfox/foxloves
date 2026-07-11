local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Avatar")

  local a = fox.Avatar.new{ x = 0, y = 0, size = 48, name = "Red Fox" }
  check("w equals size", a.w == 48)
  check("h equals size", a.h == 48)
  local mw, mh = a:measure()
  check("measure returns size", mw == 48 and mh == 48)
  check("initials from name", a.initials == "RF")

  -- Single-word name yields one initial.
  check("single word initial", fox.Avatar.new{ name = "Fox" }.initials == "F")
  -- Explicit initials override the name.
  check("explicit initials win", fox.Avatar.new{ name = "Red Fox", initials = "ZZ" }.initials == "ZZ")
  -- No name and no initials: empty fallback, still valid.
  check("empty initials default", fox.Avatar.new{}.initials == "")

  -- Non-interactive: consumes nothing.
  check("press inert", a:mousepressed(5, 5, 1) == false)
  check("release inert", a:mousereleased(5, 5, 1) == false)
  check("keypressed inert", a:keypressed("space") == false)

  -- Draw does not error across shapes and image/initials paths.
  local fakeImage = {
    getWidth = function() return 32 end,
    getHeight = function() return 20 end,
  }
  check("draw initials circle", pcall(function() a:draw() end))
  check("draw image circle", pcall(function()
    fox.Avatar.new{ size = 40, image = fakeImage }:draw()
  end))
  check("draw image rounded", pcall(function()
    fox.Avatar.new{ size = 40, image = fakeImage, shape = "rounded" }:draw()
  end))
  check("draw initials rounded", pcall(function()
    fox.Avatar.new{ size = 40, name = "Red Fox", shape = "rounded" }:draw()
  end))
end
