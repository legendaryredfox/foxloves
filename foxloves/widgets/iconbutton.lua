-- IconButton widget: a square button drawing an image instead of a label.
--
-- IconButton.new{
--   x, y, w, h,
--   image = <love Image>,   -- drawn centered, scaled to fit with padding
--   onClick = function(self) end,
--   disabled = false,
--   theme = <theme table>,
-- }
--
-- Same interaction model as Button (normal/hover/press/disabled). Fires onClick
-- on mouserelease inside bounds when the press also began inside.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local IconButton = {}
IconButton.__index = IconButton

function IconButton.new(opts)
  opts = opts or {}
  local self = setmetatable({}, IconButton)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 32
  self.h = opts.h or 32
  self.image = opts.image
  self.onClick = opts.onClick
  self.disabled = opts.disabled or false
  self.theme = opts.theme or defaultTheme
  self.hovered = false
  self.pressed = false
  return self
end

function IconButton:contains(px, py)
  return util.contains(px, py, self.x, self.y, self.w, self.h)
end

function IconButton:update(dt)
  if self.disabled then
    self.hovered = false
    return
  end
  local mx, my = love.mouse.getPosition()
  self.hovered = self:contains(mx, my)
end

function IconButton:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()

  local fill
  if self.disabled then
    fill = t.color.disabled
  elseif self.pressed and self.hovered then
    fill = t.color.accent
  elseif self.hovered then
    fill = t.color.fg
  else
    fill = t.color.bg
  end

  love.graphics.setColor(fill)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)
  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  if self.image then
    -- Scale the image to fit inside the padding box, centered.
    local pad = t.padding
    local availW, availH = self.w - pad * 2, self.h - pad * 2
    local iw, ih = self.image:getWidth(), self.image:getHeight()
    local scale = math.min(availW / iw, availH / ih)
    local drawW, drawH = iw * scale, ih * scale
    local ox = self.x + (self.w - drawW) / 2
    local oy = self.y + (self.h - drawH) / 2
    love.graphics.setColor(self.disabled and t.color.textMuted or t.color.text)
    love.graphics.draw(self.image, ox, oy, 0, scale, scale)
  end

  love.graphics.setColor(r, g, b, a)
end

function IconButton:mousepressed(px, py, btn)
  if self.disabled or btn ~= 1 then return false end
  if self:contains(px, py) then
    self.pressed = true
    return true
  end
  return false
end

function IconButton:mousereleased(px, py, btn)
  if btn ~= 1 then return false end
  local wasPressed = self.pressed
  self.pressed = false
  if self.disabled or not wasPressed then return false end
  if self:contains(px, py) then
    if self.onClick then self.onClick(self) end
    return true
  end
  return false
end

function IconButton:keypressed() return false end
function IconButton:textinput() return false end

return IconButton
