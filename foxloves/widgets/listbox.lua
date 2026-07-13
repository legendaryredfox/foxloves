-- ListBox widget: a scrollable, selectable list of rows.
--
-- ListBox.new{
--   x, y, w, h,
--   items = { "a", "b", ... },
--   selected = nil,
--   rowH = 24,
--   onChange = function(index) end,
--   theme = <theme table>,
-- }
--
-- Rows are clipped to the box. Click a row to select it; drag inside the box or
-- use the scroll wheel to scroll. When the list overflows, a scrollbar track and
-- thumb are drawn on the right edge to show position and extent. Fires
-- onChange(index) on selection. listbox.selected is readable.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local DRAG_THRESHOLD = 4  -- pixels of movement before a press counts as a drag
local TYPEAHEAD_TIMEOUT = 1.0  -- seconds of idle before the type-ahead buffer resets

local ListBox = {}
ListBox.__index = ListBox

function ListBox.new(opts)
  opts = opts or {}
  local self = setmetatable({}, ListBox)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 200
  self.h = opts.h or 160
  self.items = opts.items or {}
  self.selected = opts.selected
  self.rowH = opts.rowH or 24
  self.onChange = opts.onChange
  self.theme = opts.theme or defaultTheme
  self.scroll = 0
  self.dragging = false
  self.moved = false
  self.pressY = 0
  self.lastY = 0
  self.hover = nil  -- row index under the cursor, or nil
  self.focusable = true
  self._taBuffer = ""   -- accumulated type-ahead search string
  self._taTimer = 0     -- seconds since the last type-ahead keystroke
  return self
end

-- Number of whole rows visible in the box (for PageUp/PageDown paging).
function ListBox:visibleRows()
  return math.max(1, math.floor(self.h / self.rowH))
end

-- Scroll so the selected row is fully within the viewport.
function ListBox:_scrollToSelected()
  if not self.selected then return end
  local top = (self.selected - 1) * self.rowH
  local bottom = top + self.rowH
  if top < self.scroll then
    self.scroll = top
  elseif bottom > self.scroll + self.h then
    self.scroll = bottom - self.h
  end
  self.scroll = util.clamp(self.scroll, 0, self:maxScroll())
end

-- Move selection to index i (clamped), scroll it into view, fire onChange.
function ListBox:_select(i)
  if #self.items == 0 then return end
  i = util.clamp(i, 1, #self.items)
  if i ~= self.selected then
    self.selected = i
    self:_scrollToSelected()
    if self.onChange then self.onChange(i) end
  end
end

function ListBox:contains(px, py)
  return util.contains(px, py, self.x, self.y, self.w, self.h)
end

function ListBox:maxScroll()
  return math.max(0, #self.items * self.rowH - self.h)
end

-- Scrollbar geometry (track + thumb) on the right edge, or nil when the content
-- fits and no bar is needed. Thumb height is proportional to the visible extent;
-- its position tracks the scroll fraction.
function ListBox:_scrollbar()
  local maxS = self:maxScroll()
  if maxS <= 0 then return nil end
  local total = #self.items * self.rowH
  local w = 6
  local trackX = self.x + self.w - w - 2
  local trackY = self.y + 2
  local trackH = self.h - 4
  local thumbH = math.max(20, trackH * (self.h / total))
  local thumbY = trackY + (trackH - thumbH) * (self.scroll / maxS)
  return { x = trackX, y = thumbY, w = w, h = thumbH,
           trackX = trackX, trackY = trackY, trackH = trackH }
end

-- Row index under a viewport y, or nil if outside the item range.
function ListBox:rowAt(py)
  local idx = math.floor((py - self.y + self.scroll) / self.rowH) + 1
  if idx >= 1 and idx <= #self.items then return idx end
  return nil
end

function ListBox:update(dt)
  self._taTimer = self._taTimer + (dt or 0)
  local mx, my = love.mouse.getPosition()
  if self.dragging then
    if love.mouse.isDown(1) then
      local dy = my - self.lastY
      self.lastY = my
      if math.abs(my - self.pressY) > DRAG_THRESHOLD then self.moved = true end
      self.scroll = util.clamp(self.scroll - dy, 0, self:maxScroll())
    end
    self.hover = nil
  elseif self:contains(mx, my) then
    self.hover = self:rowAt(my)
  else
    self.hover = nil
  end
end

-- Scroll wheel over the box scrolls by one row per notch.
function ListBox:wheelmoved(dx, dy)
  if dy == 0 or self:maxScroll() == 0 then return false end
  local mx, my = love.mouse.getPosition()
  if not self:contains(mx, my) then return false end
  self.scroll = util.clamp(self.scroll - dy * self.rowH, 0, self:maxScroll())
  return true
end

function ListBox:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  love.graphics.setColor(t.color.fg)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)

  love.graphics.setScissor(self.x, self.y, self.w, self.h)
  for i, item in ipairs(self.items) do
    local ry = self.y + (i - 1) * self.rowH - self.scroll
    if ry + self.rowH > self.y and ry < self.y + self.h then
      if i == self.selected then
        love.graphics.setColor(t.color.accent)
        love.graphics.rectangle("fill", self.x, ry, self.w, self.rowH)
      elseif i == self.hover then
        love.graphics.setColor(t.color.hover)
        love.graphics.rectangle("fill", self.x, ry, self.w, self.rowH)
      end
      love.graphics.setColor(t.color.text)
      love.graphics.print(item, self.x + t.padding, ry + (self.rowH - font:getHeight()) / 2)
    end
  end
  love.graphics.setScissor()

  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  -- Scrollbar affordance: a track + thumb showing position/extent when the list
  -- overflows the box.
  local sb = self:_scrollbar()
  if sb then
    love.graphics.setColor(t.color.bg)
    love.graphics.rectangle("fill", sb.trackX, sb.trackY, sb.w, sb.trackH, sb.w / 2, sb.w / 2)
    love.graphics.setColor(t.color.textMuted)
    love.graphics.rectangle("fill", sb.x, sb.y, sb.w, sb.h, sb.w / 2, sb.w / 2)
  end

  if util.isFocused(self) then util.focusRing(t, self.x, self.y, self.w, self.h) end

  love.graphics.setColor(r, g, b, a)
end

function ListBox:mousepressed(px, py, btn)
  if btn ~= 1 or not self:contains(px, py) then return false end
  self.dragging = true
  self.moved = false
  self.pressY = py
  self.lastY = py
  return true
end

function ListBox:mousereleased(px, py, btn)
  if btn ~= 1 or not self.dragging then return false end
  self.dragging = false
  if not self.moved then
    local idx = self:rowAt(py)
    if idx and idx ~= self.selected then
      self.selected = idx
      if self.onChange then self.onChange(idx) end
    end
  end
  return true
end

-- When focused: arrows/Home/End/Page move the selection (scrolling it into
-- view); Enter re-confirms the current selection. First arrow with no
-- selection lands on row 1.
function ListBox:keypressed(key)
  if not util.isFocused(self) or #self.items == 0 then return false end
  local cur = self.selected or 1
  if key == "up" then
    self:_select(self.selected and cur - 1 or 1); return true
  elseif key == "down" then
    self:_select(self.selected and cur + 1 or 1); return true
  elseif key == "home" then
    self:_select(1); return true
  elseif key == "end" then
    self:_select(#self.items); return true
  elseif key == "pageup" then
    self:_select(cur - self:visibleRows()); return true
  elseif key == "pagedown" then
    self:_select(cur + self:visibleRows()); return true
  elseif key == "return" or key == "kpenter" or key == "space" then
    if self.selected and self.onChange then self.onChange(self.selected) end
    return true
  end
  return false
end
-- Type-ahead: while focused, typing letters jumps the selection to a matching
-- row. Fast keystrokes build a prefix buffer ("bl" -> first item starting "bl");
-- after TYPEAHEAD_TIMEOUT of idle the buffer resets. Pressing the same single
-- letter repeatedly cycles through all items starting with it. Matching is
-- case-insensitive. Returns true when a keystroke is consumed.
function ListBox:textinput(text)
  if not util.isFocused(self) or #self.items == 0 then return false end
  if self._taTimer > TYPEAHEAD_TIMEOUT then self._taBuffer = "" end
  self._taTimer = 0
  self._taBuffer = self._taBuffer .. text:lower()

  -- A buffer of one repeated character searches for that single letter starting
  -- past the current selection, so repeats cycle; a mixed buffer refines from
  -- the current selection so a longer prefix can narrow the match in place.
  local first = self._taBuffer:sub(1, 1)
  local repeated = self._taBuffer == first:rep(#self._taBuffer)
  local query = repeated and first or self._taBuffer
  local from = repeated and (self.selected or 0) + 1 or (self.selected or 1)

  local n = #self.items
  for offset = 0, n - 1 do
    local i = (from - 1 + offset) % n + 1
    if self.items[i]:lower():sub(1, #query) == query then
      self:_select(i)
      return true
    end
  end
  return true  -- consumed even when nothing matched, so the buffer stays coherent
end

return ListBox
