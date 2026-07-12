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
--
-- Selection & clipboard: hold Shift with arrows/Home/End (or Shift-click) to
-- select a range; Ctrl+A selects all; Ctrl+C/X/V copy/cut/paste via the system
-- clipboard. Typing, Backspace, Delete, or paste replaces the active selection.

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
  self.anchor = nil             -- selection anchor (byte index); nil = no selection
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

-- True when a non-empty selection exists.
function Textbox:_hasSelection()
  return self.anchor ~= nil and self.anchor ~= self.caret
end

-- Sorted selection bounds (lo, hi) in bytes, or nil when there is no selection.
function Textbox:_selRange()
  if not self:_hasSelection() then return nil end
  local a, c = self.anchor, self.caret
  if a < c then return a, c end
  return c, a
end

-- Modifier queries (guarded so headless callers without love.keyboard are safe).
function Textbox:_isShift()
  return love.keyboard and love.keyboard.isDown("lshift", "rshift")
end
function Textbox:_isCtrl()
  return love.keyboard and love.keyboard.isDown("lctrl", "rctrl", "lgui", "rgui")
end

-- Move the caret, extending the selection when `keepSel`, else collapsing it.
function Textbox:_moveCaret(to, keepSel)
  if keepSel then
    if not self.anchor then self.anchor = self.caret end
  else
    self.anchor = nil
  end
  self.caret = to
  self:_ensureCaretVisible()
end

-- Remove the selected range (if any). Returns true when text was deleted.
function Textbox:_deleteSelection()
  local lo, hi = self:_selRange()
  if not lo then return false end
  self.value = self.value:sub(1, lo) .. self.value:sub(hi + 1)
  self.caret = lo
  self.anchor = nil
  self:_ensureCaretVisible()
  return true
end

-- Text currently selected, or "" when nothing is selected.
function Textbox:_selectedText()
  local lo, hi = self:_selRange()
  if not lo then return "" end
  return self.value:sub(lo + 1, hi)
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
    -- Selection highlight sits behind the glyphs.
    if self.focused then
      local lo, hi = self:_selRange()
      if lo then
        local selX = innerX - self.scrollX + self:_textWidth(lo)
        local selW = self:_textWidth(hi) - self:_textWidth(lo)
        love.graphics.setColor(t.color.selection or t.color.accent)
        love.graphics.rectangle("fill", selX, textY, selW, font:getHeight())
      end
    end
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
    -- Shift-click extends the selection from the current caret; a plain click
    -- collapses it and drops the caret at the clicked character.
    self:_moveCaret(self:_caretFromX(px), self:_isShift())
    self.blink, self.blinkOn = 0, true
    return true
  end
  return false
end

function Textbox:mousereleased(px, py, btn) return false end

function Textbox:keypressed(key)
  if not self.focused then return false end

  -- Clipboard / select-all shortcuts (Ctrl or Cmd held).
  if self:_isCtrl() then
    if key == "a" then
      self.anchor, self.caret = 0, #self.value
      self:_ensureCaretVisible()
      return true
    elseif key == "c" then
      if self:_hasSelection() then love.system.setClipboardText(self:_selectedText()) end
      return true
    elseif key == "x" then
      if self:_hasSelection() then
        love.system.setClipboardText(self:_selectedText())
        self:_deleteSelection()
        self:_emitChange()
      end
      return true
    elseif key == "v" then
      local paste = love.system.getClipboardText() or ""
      if paste ~= "" then self:_insert(paste); self:_emitChange() end
      return true
    end
  end

  local shift = self:_isShift()
  if key == "backspace" then
    if self:_deleteSelection() then
      self:_emitChange()
    elseif self.caret > 0 then
      self.value = self.value:sub(1, self.caret - 1) .. self.value:sub(self.caret + 1)
      self.caret = self.caret - 1
      self:_ensureCaretVisible()
      self:_emitChange()
    end
    return true
  elseif key == "delete" then
    if self:_deleteSelection() then
      self:_emitChange()
    elseif self.caret < #self.value then
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
    if self:_hasSelection() and not shift then
      self:_moveCaret((self:_selRange()), false)   -- collapse to selection start
    else
      self:_moveCaret(math.max(0, self.caret - 1), shift)
    end
    return true
  elseif key == "right" then
    if self:_hasSelection() and not shift then
      local _, hi = self:_selRange()
      self:_moveCaret(hi, false)                    -- collapse to selection end
    else
      self:_moveCaret(math.min(#self.value, self.caret + 1), shift)
    end
    return true
  elseif key == "home" then
    self:_moveCaret(0, shift)
    return true
  elseif key == "end" then
    self:_moveCaret(#self.value, shift)
    return true
  end
  return false
end

-- Insert text at the caret, replacing any selection first. Honors maxLength.
function Textbox:_insert(text)
  self:_deleteSelection()
  if self.maxLength then
    local room = self.maxLength - #self.value
    if room <= 0 then return end
    if #text > room then text = text:sub(1, room) end
  end
  self.value = self.value:sub(1, self.caret) .. text .. self.value:sub(self.caret + 1)
  self.caret = self.caret + #text
  self:_ensureCaretVisible()
end

function Textbox:textinput(text)
  if not self.focused then return false end
  -- Typing over a selection replaces it, even when at the maxLength cap.
  if not self:_hasSelection() and self.maxLength and #self.value >= self.maxLength then
    return true
  end
  self:_insert(text)
  self:_emitChange()
  return true
end

return Textbox
