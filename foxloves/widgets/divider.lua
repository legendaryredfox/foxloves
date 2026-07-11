-- Divider widget: a static separator line.
--
-- Divider.new{
--   x, y,
--   length = 100,
--   vertical = false,     -- false = horizontal, true = vertical
--   thickness = 1,
--   label = nil,          -- horizontal only: centered "— OR —" text
--   theme = <theme table>,
-- }
--
-- Non-interactive. Draws one line in theme.color.border. With a label (and
-- horizontal), splits the line around centered muted text.

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
  self.label = opts.label
  self.theme = opts.theme or defaultTheme
  return self
end

function Divider:update(dt) end

function Divider:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()

  if self.label and self.label ~= "" and not self.vertical then
    self:_drawLabeled(t)
    love.graphics.setColor(r, g, b, a)
    return
  end

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

-- Horizontal line split around centered muted text ("— OR —").
function Divider:_drawLabeled(t)
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)
  local tw = font:getWidth(self.label)
  local th = font:getHeight()
  local gap = t.padding
  local lineY = self.y + th / 2 - self.thickness / 2
  local textX = self.x + (self.length - tw) / 2

  love.graphics.setColor(t.color.border)
  -- Left segment (skip if the label leaves no room).
  local leftW = (textX - gap) - self.x
  if leftW > 0 then
    love.graphics.rectangle("fill", self.x, lineY, leftW, self.thickness)
  end
  local rightX = textX + tw + gap
  local rightW = (self.x + self.length) - rightX
  if rightW > 0 then
    love.graphics.rectangle("fill", rightX, lineY, rightW, self.thickness)
  end

  love.graphics.setColor(t.color.textMuted)
  love.graphics.print(self.label, textX, self.y)
end

function Divider:mousepressed(px, py, btn) return false end
function Divider:mousereleased(px, py, btn) return false end
function Divider:keypressed(key) return false end
function Divider:textinput(text) return false end

return Divider
