-- Dropdown / Select widget: pick one option from a popup list.
--
-- Dropdown.new{
--   x, y, w, h = 32,
--   options = { "One", "Two" },
--   selected = 1,
--   onChange = function(index) end,
--   theme = <theme table>,
-- }
--
-- Closed, it shows the current option and a caret. Clicking opens a popup list
-- as a non-modal overlay anchored below the trigger; the popup is dismissed by
-- clicking outside it (handled by Root). Selecting a row fires onChange(index)
-- and closes. dropdown.selected is readable/writable.
--
-- Must be added to a fox.Root (root:add) so it can open its popup overlay.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local Dropdown = {}
Dropdown.__index = Dropdown

-- ---------------------------------------------------------- popup (internal)

local Popup = {}
Popup.__index = Popup

local function openPopup(dropdown)
  local self = setmetatable({}, Popup)
  self.dropdown = dropdown
  self.x = dropdown.x
  self.y = dropdown.y + dropdown.h
  self.w = dropdown.w
  self.rowH = dropdown.h
  self.theme = dropdown.theme
  self.hover = nil
  return self
end

function Popup:rowBounds(i)
  return self.x, self.y + (i - 1) * self.rowH, self.w, self.rowH
end

function Popup:update(dt)
  local mx, my = love.mouse.getPosition()
  self.hover = nil
  for i = 1, #self.dropdown.options do
    if util.contains(mx, my, self:rowBounds(i)) then self.hover = i; break end
  end
end

function Popup:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  local totalH = self.rowH * #self.dropdown.options
  love.graphics.setColor(t.color.fg)
  love.graphics.rectangle("fill", self.x, self.y, self.w, totalH)

  for i, opt in ipairs(self.dropdown.options) do
    local rx, ry, rw, rh = self:rowBounds(i)
    if i == self.hover then
      love.graphics.setColor(t.color.accent)
      love.graphics.rectangle("fill", rx, ry, rw, rh)
    end
    love.graphics.setColor(t.color.text)
    love.graphics.print(opt, rx + t.padding, ry + (rh - font:getHeight()) / 2)
  end

  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, totalH)

  love.graphics.setColor(r, g, b, a)
end

function Popup:mousepressed(px, py, btn)
  if btn ~= 1 then return false end
  for i = 1, #self.dropdown.options do
    if util.contains(px, py, self:rowBounds(i)) then
      self.dropdown:_select(i)
      if self.dropdown.root then self.dropdown.root:closeOverlay(self) end
      return true
    end
  end
  -- Clicking the trigger again just closes (consume so it does not reopen).
  local d = self.dropdown
  if util.contains(px, py, d.x, d.y, d.w, d.h) then
    if d.root then d.root:closeOverlay(self) end
    return true
  end
  return false  -- outside: let Root dismiss + fall through
end

function Popup:mousereleased(px, py, btn) return false end
function Popup:keypressed(key) return false end
function Popup:textinput(text) return false end

-- ------------------------------------------------------------- dropdown API

function Dropdown.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Dropdown)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 160
  self.h = opts.h or 32
  self.options = opts.options or {}
  self.selected = opts.selected or 1
  self.onChange = opts.onChange
  self.theme = opts.theme or defaultTheme
  self.root = nil  -- set by Root:add
  return self
end

function Dropdown:_select(i)
  if i ~= self.selected then
    self.selected = i
    if self.onChange then self.onChange(i) end
  end
end

function Dropdown:contains(px, py)
  return util.contains(px, py, self.x, self.y, self.w, self.h)
end

function Dropdown:update(dt) end

function Dropdown:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  love.graphics.setColor(t.color.fg)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)
  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  love.graphics.setColor(t.color.text)
  local label = self.options[self.selected] or ""
  local ty = self.y + (self.h - font:getHeight()) / 2
  love.graphics.print(label, self.x + t.padding, ty)

  -- caret: a small downward triangle on the right
  local cx = self.x + self.w - t.padding - 6
  local cy = self.y + self.h / 2
  love.graphics.polygon("fill", cx, cy - 3, cx + 12, cy - 3, cx + 6, cy + 4)

  love.graphics.setColor(r, g, b, a)
end

function Dropdown:mousepressed(px, py, btn)
  if btn ~= 1 then return false end
  if self:contains(px, py) then
    if self.root then
      self.root:openOverlay(openPopup(self), { modal = false })
    end
    return true
  end
  return false
end

function Dropdown:mousereleased(px, py, btn) return false end
function Dropdown:keypressed(key) return false end
function Dropdown:textinput(text) return false end

return Dropdown
