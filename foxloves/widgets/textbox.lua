-- Textbox widget: single-line text input with a blinking caret.
--
-- Textbox.new{
--   x, y, w, h,
--   value = "",
--   placeholder = "Type here...",
--   onChange = function(newValue) end,
--   onSubmit = function(value) end,   -- fired on Enter (then blurs)
--   maxLength = nil,          -- optional cap
--   theme = <theme table>,
-- }
--
-- Click to focus, click elsewhere to blur. Supports text entry, backspace,
-- forward delete, and caret movement with left/right/Home/End. Fires
-- onChange(newValue) on any edit; Enter fires onSubmit(value) and blurs.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

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
  self.onSubmit = opts.onSubmit
  self.maxLength = opts.maxLength
  self.theme = opts.theme or defaultTheme
  self.focused = false
  self.caret = #self.value      -- caret position, in bytes (ASCII-safe)
  self.scrollX = 0              -- horizontal pixel offset to keep caret in view
  self.blink = 0
  self.blinkOn = true
  self.focusable = true
  return self
end

-- Root calls this when keyboard focus moves here (Tab) or away.
function Textbox:setFocused(on)
  self.focused = on
  if on then self.blink, self.blinkOn = 0, true else self.blinkOn = false end
end

-- Pixel width of the value up to a caret index, in the current font.
function Textbox:_textWidth(caret)
  local font = defaultTheme.getFont(self.theme)
  return font:getWidth(self.value:sub(1, caret))
end

-- Nearest caret index to a viewport x (accounts for padding + scroll).
function Textbox:_caretFromX(px)
  local rel = px - (self.x + self.theme.padding) + self.scrollX
  if rel <= 0 then return 0 end
  for i = 1, #self.value do
    local mid = (self:_textWidth(i - 1) + self:_textWidth(i)) / 2
    if rel < mid then return i - 1 end
  end
  return #self.value
end

-- Keep the caret inside the visible inner box by adjusting scrollX.
function Textbox:_ensureCaretVisible()
  local viewW = self.w - self.theme.padding * 2
  local caretPx = self:_textWidth(self.caret)
  if caretPx - self.scrollX > viewW then
    self.scrollX = caretPx - viewW
  elseif caretPx - self.scrollX < 0 then
    self.scrollX = caretPx
  end
  if self.scrollX < 0 then self.scrollX = 0 end
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
  -- Clip text/caret to the inner box so long content and scroll never overflow.
  local innerX, innerW = self.x + pad, self.w - pad * 2
  love.graphics.setScissor(innerX, self.y, innerW, self.h)

  if self.value == "" and not self.focused then
    love.graphics.setColor(t.color.textMuted)
    love.graphics.print(self.placeholder, innerX, textY)
  else
    love.graphics.setColor(t.color.text)
    love.graphics.print(self.value, innerX - self.scrollX, textY)
  end

  if self.focused and self.blinkOn then
    local caretX = innerX - self.scrollX + self:_textWidth(self.caret)
    love.graphics.setColor(t.color.text)
    love.graphics.rectangle("fill", caretX, textY, 1, font:getHeight())
  end

  love.graphics.setScissor()
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
    self.caret = self:_caretFromX(px)
    self:_ensureCaretVisible()
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
      self:_ensureCaretVisible()
      self:_emitChange()
    end
    return true
  elseif key == "delete" then
    if self.caret < #self.value then
      self.value = self.value:sub(1, self.caret) .. self.value:sub(self.caret + 2)
      self:_ensureCaretVisible()
      self:_emitChange()
    end
    return true
  elseif key == "return" or key == "kpenter" then
    if self.onSubmit then self.onSubmit(self.value) end
    -- Blur through Root when managed so keyboard focus clears too.
    if self.root then self.root:setFocus(nil) else self:setFocused(false) end
    return true
  elseif key == "left" then
    self.caret = math.max(0, self.caret - 1)
    self:_ensureCaretVisible()
    return true
  elseif key == "right" then
    self.caret = math.min(#self.value, self.caret + 1)
    self:_ensureCaretVisible()
    return true
  elseif key == "home" then
    self.caret = 0
    self:_ensureCaretVisible()
    return true
  elseif key == "end" then
    self.caret = #self.value
    self:_ensureCaretVisible()
    return true
  end
  return false
end

function Textbox:textinput(text)
  if not self.focused then return false end
  if self.maxLength and #self.value >= self.maxLength then return true end
  self.value = self.value:sub(1, self.caret) .. text .. self.value:sub(self.caret + 1)
  self.caret = self.caret + #text
  self:_ensureCaretVisible()
  self:_emitChange()
  return true
end

return Textbox
