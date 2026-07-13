-- SegmentedControl widget: a row of mutually-exclusive, button-styled options.
--
-- SegmentedControl.new{
--   x, y, w, h,
--   options = { "Day", "Week", "Month" },
--   selected = 1,
--   onChange = function(index) end,
--   theme = <theme table>,
-- }
--
-- Like a RadioGroup rendered as a joined button strip: exactly one segment is
-- active. Clicking a segment selects it; when focused, Left/Right move the
-- selection (wrapping). Fires onChange(index) when the selection changes.
-- Read/write the current index via control.selected.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local SegmentedControl = {}
SegmentedControl.__index = SegmentedControl

function SegmentedControl.new(opts)
  opts = opts or {}
  local self = setmetatable({}, SegmentedControl)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 240
  self.h = opts.h or 32
  self.options = opts.options or {}
  self.selected = opts.selected or 1
  self.onChange = opts.onChange
  self.theme = opts.theme or defaultTheme
  self.hovered = nil   -- hovered segment index, or nil
  self.focusable = true
  return self
end

function SegmentedControl:contains(px, py)
  return util.contains(px, py, self.x, self.y, self.w, self.h)
end

-- Width of one segment (options divide the control evenly).
function SegmentedControl:_segW()
  local n = #self.options
  return n > 0 and self.w / n or self.w
end

-- Segment index under a point, or nil when outside the control.
function SegmentedControl:_indexAt(px, py)
  if not self:contains(px, py) or #self.options == 0 then return nil end
  local i = math.floor((px - self.x) / self:_segW()) + 1
  return math.min(#self.options, math.max(1, i))
end

-- Select index i, firing onChange only when it actually changes.
function SegmentedControl:_select(i)
  if i ~= self.selected and self.options[i] then
    self.selected = i
    if self.onChange then self.onChange(i) end
  end
end

function SegmentedControl:update(dt) end

function SegmentedControl:mousemoved(px, py)
  self.hovered = self:_indexAt(px, py)
end

function SegmentedControl:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  local segW = self:_segW()
  local ty = self.y + (self.h - font:getHeight()) / 2

  -- Base strip.
  love.graphics.setColor(t.color.fg)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)

  for i, opt in ipairs(self.options) do
    local segX = self.x + (i - 1) * segW
    if i == self.selected then
      love.graphics.setColor(t.color.accent)
      love.graphics.rectangle("fill", segX, self.y, segW, self.h, t.radius, t.radius)
    elseif i == self.hovered then
      love.graphics.setColor(t.color.hover)
      love.graphics.rectangle("fill", segX, self.y, segW, self.h, t.radius, t.radius)
    end
    -- Divider before every segment except the first.
    if i > 1 then
      love.graphics.setColor(t.color.border)
      love.graphics.line(segX, self.y, segX, self.y + self.h)
    end
    love.graphics.setColor(i == self.selected and t.color.bg or t.color.text)
    love.graphics.printf(opt, segX, ty, segW, "center")
  end

  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  if util.isFocused(self) then util.focusRing(t, self.x, self.y, self.w, self.h) end

  love.graphics.setColor(r, g, b, a)
end

function SegmentedControl:mousepressed(px, py, btn)
  if btn ~= 1 then return false end
  local i = self:_indexAt(px, py)
  if i then
    self:_select(i)
    return true
  end
  return false
end

function SegmentedControl:mousereleased(px, py, btn) return false end

-- When focused, Left/Right move the selection (wrapping around the ends).
function SegmentedControl:keypressed(key)
  if not util.isFocused(self) then return false end
  local n = #self.options
  if n == 0 then return false end
  if key == "left" then
    self:_select((self.selected - 2) % n + 1); return true
  elseif key == "right" then
    self:_select(self.selected % n + 1); return true
  end
  return false
end

function SegmentedControl:textinput(text) return false end

return SegmentedControl
