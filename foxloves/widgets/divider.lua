-- Divider widget: a static separator line.
--
-- Divider.new{
--   x, y,
--   length = 100,
--   vertical = false,     -- false = horizontal, true = vertical
--   thickness = 1,
--   theme = <theme table>,
-- }
--
-- Non-interactive. Draws one line in theme.color.border.

local defaultTheme = require("foxloves.theme")

local Divider = {}
Divider.__index = Divider

function Divider.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Divider)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.length = opts.length or 100
  self.vertical = opts.vertical or false
  self.thickness = opts.thickness or 1
  self.theme = opts.theme or defaultTheme
  return self
end

function Divider:update(dt) end

function Divider:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(t.color.border)

  local w, h
  if self.vertical then
    w, h = self.thickness, self.length
  else
    w, h = self.length, self.thickness
  end
  love.graphics.rectangle("fill", self.x, self.y, w, h)

  love.graphics.setColor(r, g, b, a)
end

function Divider:mousepressed(px, py, btn) return false end
function Divider:mousereleased(px, py, btn) return false end
function Divider:keypressed(key) return false end
function Divider:textinput(text) return false end

return Divider
