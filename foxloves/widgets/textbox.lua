-- Textbox widget: single-line text input with a blinking caret.
--
-- Textbox.new{
--   x, y, w, h,
--   value = "",
--   placeholder = "Type here...",
--   onChange = function(newValue) end,
--   maxLength = nil,          -- optional cap
--   theme = <theme table>,
-- }
--
-- Click to focus, click elsewhere to blur. Supports text entry, backspace,
-- and caret movement with left/right. Fires onChange(newValue) on any edit.

local defaultTheme = require("foxloves.theme")

local BLINK_PERIOD = 0.5

local Textbox = {}
Textbox.__index = Textbox

function Textbox.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Textbox)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 200
  self.h = opts.h or 32
  self.value = opts.value or ""
  self.placeholder = opts.placeholder or ""
  self.onChange = opts.onChange
  self.maxLength = opts.maxLength
  self.theme = opts.theme or defaultTheme
  self.focused = false
  self.caret = #self.value      -- caret position, in bytes (ASCII-safe)
  self.blink = 0
  self.blinkOn = true
  return self
end

function Textbox:contains(px, py)
  return px >= self.x and px <= self.x + self.w
     and py >= self.y and py <= self.y + self.h
end

function Textbox:update(dt)
  if not self.focused then
    self.blinkOn = false
    return
  end
  self.blink = self.blink + dt
  if self.blink >= BLINK_PERIOD then
    self.blink = self.blink - BLINK_PERIOD
    self.blinkOn = not self.blinkOn
  end
end

function Textbox:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  love.graphics.setColor(t.color.fg)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)
  love.graphics.setColor(self.focused and t.color.accent or t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  local pad = t.padding
  local textY = self.y + (self.h - font:getHeight()) / 2

  if self.value == "" and not self.focused then
    love.graphics.setColor(t.color.textMuted)
    love.graphics.print(self.placeholder, self.x + pad, textY)
  else
    love.graphics.setColor(t.color.text)
    love.graphics.print(self.value, self.x + pad, textY)
  end

  if self.focused and self.blinkOn then
    local caretX = self.x + pad + font:getWidth(self.value:sub(1, self.caret))
    love.graphics.setColor(t.color.text)
    love.graphics.rectangle("fill", caretX, textY, 1, font:getHeight())
  end

  love.graphics.setColor(r, g, b, a)
end

function Textbox:_emitChange()
  if self.onChange then self.onChange(self.value) end
end

function Textbox:mousepressed(px, py, btn)
  if btn ~= 1 then return false end
  local inside = self:contains(px, py)
  self.focused = inside
  if inside then
    self.caret = #self.value
    self.blink, self.blinkOn = 0, true
    return true
  end
  return false
end

function Textbox:mousereleased(px, py, btn) return false end

function Textbox:keypressed(key)
  if not self.focused then return false end
  if key == "backspace" then
    if self.caret > 0 then
      self.value = self.value:sub(1, self.caret - 1) .. self.value:sub(self.caret + 1)
      self.caret = self.caret - 1
      self:_emitChange()
    end
    return true
  elseif key == "left" then
    self.caret = math.max(0, self.caret - 1)
    return true
  elseif key == "right" then
    self.caret = math.min(#self.value, self.caret + 1)
    return true
  end
  return false
end

function Textbox:textinput(text)
  if not self.focused then return false end
  if self.maxLength and #self.value >= self.maxLength then return true end
  self.value = self.value:sub(1, self.caret) .. text .. self.value:sub(self.caret + 1)
  self.caret = self.caret + #text
  self:_emitChange()
  return true
end

return Textbox
