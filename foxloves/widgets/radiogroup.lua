-- RadioGroup widget: mutually exclusive option set.
--
-- RadioGroup.new{
--   x, y,
--   options = { "One", "Two" },  -- labels, top to bottom
--   selected = 1,                 -- 1-based index of the active option
--   spacing = 28,                 -- vertical distance between rows
--   onChange = function(index) end,
--   disabled = false,
--   theme = <theme table>,
-- }
--
-- One widget owns all rows so exclusivity is trivial. Clicking a row selects it
-- and clears the others. group.selected is readable/writable.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local RadioGroup = {}
RadioGroup.__index = RadioGroup

function RadioGroup.new(opts)
  opts = opts or {}
  local self = setmetatable({}, RadioGroup)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.options = opts.options or {}
  self.selected = opts.selected or 1
  self.spacing = opts.spacing or 28
  self.onChange = opts.onChange
  self.disabled = opts.disabled or false
  self.theme = opts.theme or defaultTheme
  self.diameter = 18
  self.pressed = nil  -- index pressed this cycle, or nil
  self.hover = nil    -- row index under the cursor, or nil
  self.focusable = true
  return self
end

-- Set selection to index i, firing onChange when it changes.
function RadioGroup:_select(i)
  if i ~= self.selected and self.options[i] then
    self.selected = i
    if self.onChange then self.onChange(i) end
  end
end

-- Hit rectangle for row i (circle plus its label).
function RadioGroup:rowBounds(i)
  local t = self.theme
  local font = defaultTheme.getFont(t)
  local label = self.options[i] or ""
  local w = self.diameter + t.padding + font:getWidth(label)
  local y = self.y + (i - 1) * self.spacing
  return self.x, y, w, self.diameter
end

-- Index of the row containing (px, py), or nil.
function RadioGroup:rowAt(px, py)
  for i = 1, #self.options do
    if util.contains(px, py, self:rowBounds(i)) then return i end
  end
  return nil
end

function RadioGroup:update(dt) end

-- Hover is event-driven; coordinates arrive in local space (see Container).
function RadioGroup:mousemoved(px, py)
  self.hover = self.disabled and nil or self:rowAt(px, py)
end

function RadioGroup:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  local d = self.diameter
  local focused = util.isFocused(self)
  for i = 1, #self.options do
    local rx, ry, rw = self:rowBounds(i)
    local cx, cy = rx + d / 2, ry + d / 2

    -- Focus ring highlights the active row while the group holds focus.
    if focused and i == self.selected then
      util.focusRing(t, rx, ry, rw, d)
    end

    local fill = t.color.fg
    if self.disabled then fill = t.color.disabled
    elseif i == self.hover and i ~= self.selected then fill = t.color.hover end
    love.graphics.setColor(fill)
    love.graphics.circle("fill", cx, cy, d / 2)
    love.graphics.setColor(t.color.border)
    love.graphics.circle("line", cx, cy, d / 2)

    if i == self.selected then
      love.graphics.setColor(self.disabled and t.color.textMuted or t.color.accent)
      love.graphics.circle("fill", cx, cy, d / 2 - 4)
    end

    love.graphics.setColor(self.disabled and t.color.textMuted or t.color.text)
    local ty = ry + (d - font:getHeight()) / 2
    love.graphics.print(self.options[i], rx + d + t.padding, ty)
  end

  love.graphics.setColor(r, g, b, a)
end

function RadioGroup:mousepressed(px, py, btn)
  if self.disabled or btn ~= 1 then return false end
  local i = self:rowAt(px, py)
  if i then
    self.pressed = i
    return true
  end
  return false
end

function RadioGroup:mousereleased(px, py, btn)
  if btn ~= 1 then return false end
  local pressed = self.pressed
  self.pressed = nil
  if self.disabled or not pressed then return false end
  local i = self:rowAt(px, py)
  if i and i == pressed then
    if i ~= self.selected then
      self.selected = i
      if self.onChange then self.onChange(i) end
    end
    return true
  end
  return false
end

-- When focused: Up/Left and Down/Right move selection with wrap-around;
-- Home/End jump to the first/last option.
function RadioGroup:keypressed(key)
  if self.disabled or not util.isFocused(self) then return false end
  local n = #self.options
  if n == 0 then return false end
  local cur = self.selected or 1
  if key == "up" or key == "left" then
    self:_select((cur - 2) % n + 1); return true
  elseif key == "down" or key == "right" then
    self:_select(cur % n + 1); return true
  elseif key == "home" then
    self:_select(1); return true
  elseif key == "end" then
    self:_select(n); return true
  end
  return false
end
function RadioGroup:textinput() return false end

return RadioGroup
