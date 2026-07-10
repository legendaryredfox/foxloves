-- Stepper widget: numeric value with - / + buttons.
--
-- Stepper.new{
--   x, y, w,
--   h = 32,
--   value = 0, min = nil, max = nil, step = 1,
--   onChange = function(value) end,
--   disabled = false,
--   theme = <theme table>,
-- }
--
-- Composes two Buttons flanking a printed numeric readout. The readout is not
-- editable (keyboard entry is deferred). Value is clamped to min/max when set.
-- Fires onChange(value) when the value changes.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")
local Button = require("foxloves.widgets.button")

local Stepper = {}
Stepper.__index = Stepper

function Stepper.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Stepper)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 140
  self.h = opts.h or 32
  self.value = opts.value or 0
  self.min = opts.min
  self.max = opts.max
  self.step = opts.step or 1
  self.onChange = opts.onChange
  self.disabled = opts.disabled or false
  self.theme = opts.theme or defaultTheme
  self:_clamp()

  local bw = self.h  -- square end buttons
  self.minus = Button.new{
    x = self.x, y = self.y, w = bw, h = self.h, label = "-",
    disabled = self.disabled, theme = self.theme,
    onClick = function() self:_bump(-self.step) end,
  }
  self.plus = Button.new{
    x = self.x + self.w - bw, y = self.y, w = bw, h = self.h, label = "+",
    disabled = self.disabled, theme = self.theme,
    onClick = function() self:_bump(self.step) end,
  }
  return self
end

function Stepper:_clamp()
  if self.min then self.value = math.max(self.min, self.value) end
  if self.max then self.value = math.min(self.max, self.value) end
end

function Stepper:_bump(delta)
  local before = self.value
  self.value = self.value + delta
  self:_clamp()
  if self.value ~= before and self.onChange then
    self.onChange(self.value)
  end
end

function Stepper:update(dt)
  self.minus:update(dt)
  self.plus:update(dt)
end

function Stepper:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)

  self.minus:draw()
  self.plus:draw()

  love.graphics.setFont(font)
  love.graphics.setColor(self.disabled and t.color.textMuted or t.color.text)
  local ty = self.y + (self.h - font:getHeight()) / 2
  love.graphics.printf(tostring(self.value), self.x, ty, self.w, "center")

  love.graphics.setColor(r, g, b, a)
end

function Stepper:mousepressed(px, py, btn)
  if self.minus:mousepressed(px, py, btn) then return true end
  if self.plus:mousepressed(px, py, btn) then return true end
  return false
end

function Stepper:mousereleased(px, py, btn)
  local a = self.minus:mousereleased(px, py, btn)
  local b = self.plus:mousereleased(px, py, btn)
  return a or b
end

function Stepper:keypressed() return false end
function Stepper:textinput() return false end

return Stepper
