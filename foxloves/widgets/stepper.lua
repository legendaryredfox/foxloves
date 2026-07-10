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
-- Holding a button auto-repeats after a short delay. When focused, Up/Right and
-- Down/Left step the value. Fires onChange(value) when the value changes.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")
local Button = require("foxloves.widgets.button")

local REPEAT_DELAY = 0.4   -- seconds held before auto-repeat begins
local REPEAT_RATE  = 0.06  -- seconds between repeats once it starts

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
  self.focusable = true
  self:_clamp()

  -- Auto-repeat state: the button being held, its direction, and timers.
  self.holding = nil
  self.holdDir = 0
  self.heldTime = 0
  self.nextRepeat = 0

  -- Child buttons render the ends and track hover/pressed; the Stepper itself
  -- drives every value change (press, hold-repeat, keyboard) so there is no
  -- double-count from a button's own onClick.
  local bw = self.h  -- square end buttons
  self.minus = Button.new{
    x = self.x, y = self.y, w = bw, h = self.h, label = "-",
    disabled = self.disabled, theme = self.theme,
  }
  self.plus = Button.new{
    x = self.x + self.w - bw, y = self.y, w = bw, h = self.h, label = "+",
    disabled = self.disabled, theme = self.theme,
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

-- Enable/disable at runtime, propagating to the child buttons (the constructor
-- only snapshotted the flag, so flipping self.disabled alone would not update
-- them).
function Stepper:setDisabled(disabled)
  self.disabled = disabled and true or false
  self.minus.disabled = self.disabled
  self.plus.disabled = self.disabled
  if self.disabled then self:_stopHold() end
end

function Stepper:_startHold(button, dir)
  self.holding = button
  self.holdDir = dir
  self.heldTime = 0
  self.nextRepeat = REPEAT_DELAY
  button.pressed = true
  self:_bump(dir * self.step)
end

function Stepper:_stopHold()
  if self.holding then self.holding.pressed = false end
  self.holding = nil
  self.holdDir = 0
end

function Stepper:update(dt)
  self.minus:update(dt)
  self.plus:update(dt)
  if not self.holding then return end
  -- Stop if the button was released or the cursor left it.
  local mx, my = love.mouse.getPosition()
  if not love.mouse.isDown(1) or not self.holding:contains(mx, my) then
    self:_stopHold()
    return
  end
  self.heldTime = self.heldTime + dt
  while self.heldTime >= self.nextRepeat do
    self:_bump(self.holdDir * self.step)
    self.nextRepeat = self.nextRepeat + REPEAT_RATE
  end
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

  if util.isFocused(self) then util.focusRing(t, self.x, self.y, self.w, self.h) end

  love.graphics.setColor(r, g, b, a)
end

function Stepper:mousepressed(px, py, btn)
  if self.disabled or btn ~= 1 then return false end
  if self.minus:mousepressed(px, py, btn) then
    self:_startHold(self.minus, -1); return true
  end
  if self.plus:mousepressed(px, py, btn) then
    self:_startHold(self.plus, 1); return true
  end
  return false
end

function Stepper:mousereleased(px, py, btn)
  self:_stopHold()
  local a = self.minus:mousereleased(px, py, btn)
  local b = self.plus:mousereleased(px, py, btn)
  return a or b
end

-- When focused: Up/Right increment, Down/Left decrement by one step.
function Stepper:keypressed(key)
  if self.disabled or not util.isFocused(self) then return false end
  if key == "up" or key == "right" then
    self:_bump(self.step); return true
  elseif key == "down" or key == "left" then
    self:_bump(-self.step); return true
  end
  return false
end
function Stepper:textinput() return false end

return Stepper
