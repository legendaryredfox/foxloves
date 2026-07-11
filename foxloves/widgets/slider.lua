-- Slider widget: drag a handle to pick a value in a range.
--
-- Slider.new{
--   x, y, w,
--   h = 20,
--   value = 0, min = 0, max = 1,
--   step = nil,           -- optional snap increment
--   onChange = function(value) end,
--   disabled = false,
--   showValue = false,    -- draw a value bubble above the handle while dragging
--   format = nil,         -- function(value) -> string for that bubble
--   vertical = false,     -- true = vertical track (min bottom, max top)
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
  self.showValue = opts.showValue or false
  self.format = opts.format
  self.theme = opts.theme or defaultTheme
  self.vertical = opts.vertical or false
  self.dragging = false
  self.hovered = false
  self.grabOffsetX = 0  -- handle-center minus cursor, captured at grab
  self.grabOffsetY = 0
  self.screenDX = 0     -- global mouse minus local, captured at press
  self.screenDY = 0
  -- Handle radius comes from the short (perpendicular) axis.
  self.handleR = (self.vertical and self.w or self.h) / 2
  self.focusable = true
  return self
end

function Slider:contains(px, py)
  return util.contains(px, py, self.x, self.y, self.w, self.h)
end

-- Center (x, y) of the handle in screen space. Vertical runs min at the bottom
-- to max at the top; horizontal runs min left to max right.
function Slider:_handlePos()
  local frac = self:fraction()
  if self.vertical then
    local travel = self.h - self.handleR * 2
    return self.x + self.w / 2, self.y + self.h - self.handleR - travel * frac
  end
  local travel = self.w - self.handleR * 2
  return self.x + self.handleR + travel * frac, self.y + self.h / 2
end

-- True when (px, py) lands on the handle circle.
function Slider:_onHandle(px, py)
  local hx, hy = self:_handlePos()
  local dx, dy = px - hx, py - hy
  return dx * dx + dy * dy <= self.handleR * self.handleR
end

-- Fraction of the range currently selected, in [0, 1].
function Slider:fraction()
  local span = self.max - self.min
  if span == 0 then return 0 end
  return (self.value - self.min) / span
end

-- Map a cursor position to a value, snapped to step and clamped, then apply it.
-- Reads the main axis (X horizontal, Y vertical); the other coord is ignored.
function Slider:_setFromPos(px, py)
  local frac
  if self.vertical then
    local travel = self.h - self.handleR * 2
    frac = travel > 0
      and util.clamp((self.y + self.h - self.handleR - py) / travel, 0, 1) or 0
  else
    local travel = self.w - self.handleR * 2
    frac = travel > 0
      and util.clamp((px - (self.x + self.handleR)) / travel, 0, 1) or 0
  end
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

-- Text shown in the value bubble: custom format, else integer when whole and
-- two decimals otherwise.
function Slider:_valueText()
  if self.format then return self.format(self.value) end
  if self.value == math.floor(self.value) then
    return tostring(math.floor(self.value))
  end
  return string.format("%.2f", self.value)
end

function Slider:update(dt)
  if not self.dragging then return end
  if love.mouse.isDown(1) then
    -- Global mouse position, mapped back into the slider's local space via the
    -- delta captured at press so it works inside translated containers.
    local mx, my = love.mouse.getPosition()
    self:_setFromPos(mx - self.screenDX + self.grabOffsetX,
      my - self.screenDY + self.grabOffsetY)
  else
    self.dragging = false
  end
end

function Slider:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()

  local handleX, handleY = self:_handlePos()
  local trackT = math.max(4, (self.vertical and self.w or self.h) / 4)
  love.graphics.setColor(t.color.fg)
  love.graphics.setColor(self.disabled and t.color.disabled or t.color.accent)
  if self.vertical then
    local midX = self.x + self.w / 2
    love.graphics.setColor(t.color.fg)
    love.graphics.rectangle("fill", midX - trackT / 2, self.y, trackT, self.h, trackT / 2, trackT / 2)
    -- Filled portion runs from the bottom (min) up to the handle.
    love.graphics.setColor(self.disabled and t.color.disabled or t.color.accent)
    love.graphics.rectangle("fill", midX - trackT / 2, handleY,
      trackT, self.y + self.h - handleY, trackT / 2, trackT / 2)
  else
    local midY = self.y + self.h / 2
    love.graphics.setColor(t.color.fg)
    love.graphics.rectangle("fill", self.x, midY - trackT / 2, self.w, trackT, trackT / 2, trackT / 2)
    love.graphics.setColor(self.disabled and t.color.disabled or t.color.accent)
    love.graphics.rectangle("fill", self.x, midY - trackT / 2,
      handleX - self.x, trackT, trackT / 2, trackT / 2)
  end

  -- Ball brightens on hover/drag; its outline picks up the focus accent.
  local active = not self.disabled and (self.hovered or self.dragging)
  love.graphics.setColor(self.disabled and t.color.textMuted
    or (active and t.color.focus or t.color.text))
  love.graphics.circle("fill", handleX, handleY, self.handleR)
  love.graphics.setColor(active and t.color.accent or t.color.border)
  love.graphics.circle("line", handleX, handleY, self.handleR)

  if self.showValue and self.dragging then
    local font = defaultTheme.getFont(t)
    love.graphics.setFont(font)
    local txt = self:_valueText()
    local pad = t.padding
    local bw = font:getWidth(txt) + pad
    local bh = font:getHeight() + pad / 2
    -- Horizontal: above the handle. Vertical: to the right of it.
    local bx, by
    if self.vertical then
      bx = self.x + self.w + 4
      by = handleY - bh / 2
    else
      bx = handleX - bw / 2
      by = self.y - bh - 4
    end
    love.graphics.setColor(t.color.fg)
    love.graphics.rectangle("fill", bx, by, bw, bh, t.radius, t.radius)
    love.graphics.setColor(t.color.border)
    love.graphics.rectangle("line", bx, by, bw, bh, t.radius, t.radius)
    love.graphics.setColor(t.color.text)
    love.graphics.print(txt, bx + pad / 2, by + pad / 4)
  end

  if util.isFocused(self) then util.focusRing(t, self.x, self.y, self.w, self.h) end

  love.graphics.setColor(r, g, b, a)
end

function Slider:mousepressed(px, py, btn)
  if self.disabled or btn ~= 1 then return false end
  if self:contains(px, py) then
    self.dragging = true
    -- Remember how the global cursor maps to this local coord so update() can
    -- follow the mouse even when the slider lives inside a translated container.
    local gmx, gmy = love.mouse.getPosition()
    self.screenDX = gmx - px
    self.screenDY = gmy - py
    -- Grabbing the ball keeps its offset from the cursor so it holds still
    -- until the pointer moves; clicking the track centers it on the cursor.
    if self:_onHandle(px, py) then
      local hx, hy = self:_handlePos()
      self.grabOffsetX = hx - px
      self.grabOffsetY = hy - py
    else
      self.grabOffsetX = 0
      self.grabOffsetY = 0
      self:_setFromPos(px, py)
    end
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

-- Hover the ball so it can highlight; screen-space coords (a Container
-- translates before forwarding), matching the other widgets' hover model.
function Slider:mousemoved(px, py)
  self.hovered = not self.disabled and self:_onHandle(px, py)
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
