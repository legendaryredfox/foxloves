-- Toggle / Switch widget: sliding on/off control.
--
-- Toggle.new{
--   x, y,
--   w = 44, h = 24,
--   on = false,
--   onChange = function(on) end,
--   disabled = false,
--   theme = <theme table>,
-- }
--
-- Click toggles on/off. update(dt) animates the knob sliding between ends.
-- Fires onChange(on) when toggled.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local SLIDE_SPEED = 8  -- knob eases toward target at this rate

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Toggle)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 44
  self.h = opts.h or 24
  self.on = opts.on or false
  self.onChange = opts.onChange
  self.disabled = opts.disabled or false
  self.theme = opts.theme or defaultTheme
  self.pressed = false
  self.hovered = false
  self.anim = self.on and 1 or 0  -- 0 = off end, 1 = on end
  self.focusable = true
  return self
end

function Toggle:_toggle()
  self.on = not self.on
  if self.onChange then self.onChange(self.on) end
end

function Toggle:contains(px, py)
  return util.contains(px, py, self.x, self.y, self.w, self.h)
end

-- Hover fill on the off-state track (event-driven, local coords; see Container).
function Toggle:mousemoved(px, py)
  self.hovered = not self.disabled and self:contains(px, py)
end

function Toggle:update(dt)
  local target = self.on and 1 or 0
  local step = SLIDE_SPEED * dt
  if self.anim < target then
    self.anim = math.min(target, self.anim + step)
  elseif self.anim > target then
    self.anim = math.max(target, self.anim - step)
  end
end

function Toggle:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()

  local radius = self.h / 2
  local trackColor
  if self.disabled then
    trackColor = t.color.disabled
  elseif self.on then
    trackColor = t.color.accent
  elseif self.hovered then
    trackColor = t.color.hover
  else
    trackColor = t.color.fg
  end
  love.graphics.setColor(trackColor)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, radius, radius)
  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, radius, radius)

  local knobR = radius - 3
  local leftX = self.x + radius
  local rightX = self.x + self.w - radius
  local knobX = leftX + (rightX - leftX) * self.anim
  love.graphics.setColor(self.disabled and t.color.textMuted or t.color.text)
  love.graphics.circle("fill", knobX, self.y + radius, knobR)

  if util.isFocused(self) then util.focusRing(t, self.x, self.y, self.w, self.h) end

  love.graphics.setColor(r, g, b, a)
end

function Toggle:mousepressed(px, py, btn)
  if self.disabled or btn ~= 1 then return false end
  if self:contains(px, py) then
    self.pressed = true
    return true
  end
  return false
end

function Toggle:mousereleased(px, py, btn)
  if btn ~= 1 then return false end
  local wasPressed = self.pressed
  self.pressed = false
  if self.disabled or not wasPressed then return false end
  if self:contains(px, py) then
    self:_toggle()
    return true
  end
  return false
end

function Toggle:keypressed(key)
  if self.disabled or not util.isFocused(self) then return false end
  if key == "space" or key == "return" or key == "kpenter" then
    self:_toggle()
    return true
  end
  return false
end
function Toggle:textinput() return false end

return Toggle
