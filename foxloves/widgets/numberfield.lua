-- NumberField widget: an editable numeric input with clamping and step arrows.
--
-- NumberField.new{
--   x, y, w, h,
--   value = 0,
--   min = nil, max = nil,   -- optional bounds; nil = unbounded on that side
--   step = 1,               -- Up/Down (and wheel) increment
--   onChange = function(value) end,   -- fired when the numeric value changes
--   theme = <theme table>,
-- }
--
-- Click to focus and type a number; only digits, one leading '-', and one '.'
-- are accepted. Up/Down arrows (and the scroll wheel while hovered) nudge by
-- step. The text is parsed, clamped to [min, max], and reformatted on Enter or
-- blur; an empty or invalid entry reverts to the last valid value. Read/write
-- the number via numberfield.value / :setValue(n).

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")
local Textbox = require("foxloves.widgets.textbox")

local NumberField = {}
NumberField.__index = NumberField

function NumberField.new(opts)
  opts = opts or {}
  local self = setmetatable({}, NumberField)
  self.min = opts.min
  self.max = opts.max
  self.step = opts.step or 1
  self.onChange = opts.onChange
  self.theme = opts.theme or defaultTheme
  self.value = self:_clamp(opts.value or 0)
  self.focusable = true

  -- The inner Textbox owns caret/selection/clipboard editing; this widget adds
  -- numeric filtering, stepping, and commit-on-blur around it.
  self.tb = Textbox.new{
    x = opts.x or 0, y = opts.y or 0, w = opts.w or 120, h = opts.h or 32,
    value = self:_format(self.value), theme = self.theme,
    onSubmit = function()
      self:_commit()
      if self.root then self.root:setFocus(nil) end
    end,
  }
  self.x, self.y = self.tb.x, self.tb.y
  self.w, self.h = self.tb.w, self.tb.h
  return self
end

-- Clamp n into the configured bounds (either side may be nil = unbounded).
function NumberField:_clamp(n)
  if self.min and n < self.min then n = self.min end
  if self.max and n > self.max then n = self.max end
  return n
end

-- Numeric value as display text. Whole numbers show without a decimal point.
function NumberField:_format(n)
  if n == math.floor(n) then return tostring(math.floor(n)) end
  return tostring(n)
end

-- Root focus sync: forward to the inner Textbox, committing on blur.
function NumberField:setFocused(on)
  if not on then self:_commit() end
  self.tb:setFocused(on)
end

-- Parse the edited text, clamp it, and adopt it; invalid/empty reverts. Fires
-- onChange only when the numeric value actually changes.
function NumberField:_commit()
  local n = tonumber(self.tb.value)
  if n then self:_set(self:_clamp(n)) else self:_set(self.value) end
end

-- Set the numeric value, refresh the text, and emit onChange when it changed.
function NumberField:_set(n)
  local changed = n ~= self.value
  self.value = n
  self.tb.value = self:_format(n)
  self.tb.caret = #self.tb.value
  self.tb.anchor = nil
  self.tb:_ensureCaretVisible()
  if changed and self.onChange then self.onChange(n) end
end

-- Public setter (clamps, reformats, emits).
function NumberField:setValue(n)
  self:_set(self:_clamp(n))
end

-- Step the value from the current edited text (so typing then arrowing works).
function NumberField:_bump(dir)
  local base = tonumber(self.tb.value) or self.value
  self:_set(self:_clamp(base + dir * self.step))
end

function NumberField:contains(px, py)
  return self.tb:contains(px, py)
end

function NumberField:update(dt) self.tb:update(dt) end
function NumberField:draw() self.tb:draw() end

function NumberField:mousepressed(px, py, btn)
  return self.tb:mousepressed(px, py, btn)
end
function NumberField:mousereleased(px, py, btn)
  return self.tb:mousereleased(px, py, btn)
end
function NumberField:mousemoved(px, py, dx, dy) end

function NumberField:keypressed(key)
  if not self.tb.focused then return false end
  if key == "up" then self:_bump(1); return true
  elseif key == "down" then self:_bump(-1); return true
  end
  return self.tb:keypressed(key)
end

-- Accept a character only if it keeps the field a valid partial number: digits
-- always, a single leading '-', and a single '.'.
function NumberField:_accepts(text)
  if text:match("^%d$") then return true end
  if text == "-" then
    return self.tb.caret == 0 and not self.tb.value:find("%-")
  end
  if text == "." then
    return not self.tb.value:find("%.")
  end
  return false
end

function NumberField:textinput(text)
  if not self.tb.focused then return false end
  if not self:_accepts(text) then return true end  -- swallow non-numeric input
  return self.tb:textinput(text)
end

-- Scroll wheel over the field nudges by step when focused.
function NumberField:wheelmoved(dx, dy)
  if dy == 0 or not self.tb.focused then return false end
  self:_bump(dy > 0 and 1 or -1)
  return true
end

return NumberField
