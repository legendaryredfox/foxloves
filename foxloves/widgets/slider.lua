-- Slider widget: drag a handle to pick a value in a range.
--
-- Slider.new{
--   x, y, w,
--   h = 20,
--   value = 0, min = 0, max = 1,
--   step = nil,           -- optional snap increment
--   onChange = function(value) end,
--   disabled = false,
--   theme = <theme table>,
-- }
--
-- mousepressed on the track begins a drag and jumps the value to the cursor;
-- while dragging, update() follows the cursor as long as the left button is
-- held (no mousemoved callback needed); mousereleased ends the drag. Fires
-- onChange(value) whenever the value changes.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local Slider = {}
Slider.__index = Slider

function Slider.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Slider)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 200
  self.h = opts.h or 20
  self.min = opts.min or 0
  self.max = opts.max or 1
  self.step = opts.step
  self.value = util.clamp(opts.value or self.min, self.min, self.max)
  self.onChange = opts.onChange
  self.disabled = opts.disabled or false
  self.theme = opts.theme or defaultTheme
  self.dragging = false
  self.handleR = self.h / 2
  self.focusable = true
  return self
end

function Slider:contains(px, py)
  return util.contains(px, py, self.x, self.y, self.w, self.h)
end

-- Fraction of the range currently selected, in [0, 1].
function Slider:fraction()
  local span = self.max - self.min
  if span == 0 then return 0 end
  return (self.value - self.min) / span
end

-- Map a cursor X to a value, snapped to step and clamped, then apply it.
function Slider:_setFromX(px)
  local trackLeft = self.x + self.handleR
  local trackW = self.w - self.handleR * 2
  local frac = trackW > 0 and util.clamp((px - trackLeft) / trackW, 0, 1) or 0
  local value = self.min + frac * (self.max - self.min)
  if self.step then
    value = self.min + math.floor((value - self.min) / self.step + 0.5) * self.step
  end
  self:_apply(value)
end

-- Clamp and set the value, firing onChange only when it actually changes.
function Slider:_apply(value)
  value = util.clamp(value, self.min, self.max)
  if value ~= self.value then
    self.value = value
    if self.onChange then self.onChange(value) end
  end
end

-- Keyboard/wheel increment: explicit step, else a tenth of the range.
function Slider:_delta()
  return self.step or (self.max - self.min) / 10
end

function Slider:update(dt)
  if not self.dragging then return end
  if love.mouse.isDown(1) then
    local mx = love.mouse.getPosition()
    self:_setFromX(mx)
  else
    self.dragging = false
  end
end

function Slider:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()

  local midY = self.y + self.h / 2
  local trackH = math.max(4, self.h / 4)
  love.graphics.setColor(t.color.fg)
  love.graphics.rectangle("fill", self.x, midY - trackH / 2, self.w, trackH, trackH / 2, trackH / 2)

  local handleX = self.x + self.handleR + (self.w - self.handleR * 2) * self:fraction()
  love.graphics.setColor(self.disabled and t.color.disabled or t.color.accent)
  love.graphics.rectangle("fill", self.x, midY - trackH / 2,
    handleX - self.x, trackH, trackH / 2, trackH / 2)

  love.graphics.setColor(self.disabled and t.color.textMuted or t.color.text)
  love.graphics.circle("fill", handleX, midY, self.handleR)
  love.graphics.setColor(t.color.border)
  love.graphics.circle("line", handleX, midY, self.handleR)

  if util.isFocused(self) then util.focusRing(t, self.x, self.y, self.w, self.h) end

  love.graphics.setColor(r, g, b, a)
end

function Slider:mousepressed(px, py, btn)
  if self.disabled or btn ~= 1 then return false end
  if self:contains(px, py) then
    self.dragging = true
    self:_setFromX(px)
    return true
  end
  return false
end

function Slider:mousereleased(px, py, btn)
  if btn ~= 1 then return false end
  if self.dragging then
    self.dragging = false
    return true
  end
  return false
end

-- When focused: arrows nudge by one step, Home/End jump to the ends.
function Slider:keypressed(key)
  if self.disabled or not util.isFocused(self) then return false end
  if key == "left" or key == "down" then
    self:_apply(self.value - self:_delta()); return true
  elseif key == "right" or key == "up" then
    self:_apply(self.value + self:_delta()); return true
  elseif key == "home" then
    self:_apply(self.min); return true
  elseif key == "end" then
    self:_apply(self.max); return true
  end
  return false
end

function Slider:textinput() return false end

-- Scroll wheel over the track nudges the value.
function Slider:wheelmoved(dx, dy)
  if self.disabled or dy == 0 then return false end
  local mx, my = love.mouse.getPosition()
  if not self:contains(mx, my) then return false end
  self:_apply(self.value + dy * self:_delta())
  return true
end

return Slider
