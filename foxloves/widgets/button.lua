-- Button widget.
--
-- Button.new{
--   x, y, w, h,           -- bounds
--   label = "OK",          -- text drawn centered
--   onClick = function() end,
--   disabled = false,
--   theme = <theme table>,  -- optional, falls back to default
-- }
--
-- Fires onClick on mouserelease inside bounds when the press also began
-- inside bounds. Input handlers return true when they consume the event.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local Button = {}
Button.__index = Button

function Button.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Button)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 120
  self.h = opts.h or 32
  self.label = opts.label or "Button"
  self.onClick = opts.onClick
  self.disabled = opts.disabled or false
  self.theme = opts.theme or defaultTheme
  self.hovered = false
  self.pressed = false
  self.focusable = true
  return self
end

function Button:contains(px, py)
  return px >= self.x and px <= self.x + self.w
     and py >= self.y and py <= self.y + self.h
end

function Button:update(dt) end

-- Hover is event-driven: coordinates arrive already in this widget's own space
-- (a Container translates before forwarding), so nested buttons hover correctly.
function Button:mousemoved(px, py)
  self.hovered = not self.disabled and self:contains(px, py)
end

function Button:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()

  local fill
  if self.disabled then
    fill = t.color.disabled
  elseif self.pressed and self.hovered then
    fill = t.color.accent
  elseif self.hovered then
    fill = t.color.hover
  else
    fill = t.color.bg
  end

  love.graphics.setColor(fill)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)
  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  if util.isFocused(self) then util.focusRing(t, self.x, self.y, self.w, self.h) end

  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)
  love.graphics.setColor(self.disabled and t.color.textMuted or t.color.text)
  local ty = self.y + (self.h - font:getHeight()) / 2
  love.graphics.printf(self.label, self.x, ty, self.w, "center")

  love.graphics.setColor(r, g, b, a)
end

function Button:mousepressed(px, py, btn)
  if self.disabled or btn ~= 1 then return false end
  if self:contains(px, py) then
    self.pressed = true
    return true
  end
  return false
end

function Button:mousereleased(px, py, btn)
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

-- When focused, Space/Enter activate the button like a click.
function Button:keypressed(key)
  if self.disabled or not util.isFocused(self) then return false end
  if key == "space" or key == "return" or key == "kpenter" then
    if self.onClick then self.onClick(self) end
    return true
  end
  return false
end
function Button:textinput(text) return false end

return Button
