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
-- Rows are clipped to the box. Click a row to select it; drag inside the box to
-- scroll (there is no wheelmoved in the widget contract, so scrolling is by
-- drag). Fires onChange(index) on selection. listbox.selected is readable.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local DRAG_THRESHOLD = 4  -- pixels of movement before a press counts as a drag

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
  return self
end

function ListBox:contains(px, py)
  return util.contains(px, py, self.x, self.y, self.w, self.h)
end

function ListBox:maxScroll()
  return math.max(0, #self.items * self.rowH - self.h)
end

-- Row index under a viewport y, or nil if outside the item range.
function ListBox:rowAt(py)
  local idx = math.floor((py - self.y + self.scroll) / self.rowH) + 1
  if idx >= 1 and idx <= #self.items then return idx end
  return nil
end

function ListBox:update(dt)
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

function ListBox:keypressed(key) return false end
function ListBox:textinput(text) return false end

return ListBox
