-- Tabs widget: switch between panels via a header row.
--
-- Tabs.new{
--   x, y, w,
--   headerH = 32,
--   tabs = { { label = "One", panel = <widget> }, ... },
--   selected = 1,
--   onChange = function(index) end,
--   theme = <theme table>,
-- }
--
-- Draws a row of clickable tab labels; below it, the selected tab's `panel`
-- (any widget, typically a fox.Panel) is drawn and receives input. Position
-- each panel below the header yourself. Switching fires onChange(index).

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local Tabs = {}
Tabs.__index = Tabs

function Tabs.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Tabs)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 300
  self.headerH = opts.headerH or 32
  self.tabs = opts.tabs or {}
  self.selected = opts.selected or 1
  self.onChange = opts.onChange
  self.theme = opts.theme or defaultTheme
  self.hoverTab = nil  -- header segment under the cursor, or nil
  return self
end

-- Bounds of tab header segment i.
function Tabs:tabBounds(i)
  local n = math.max(1, #self.tabs)
  local segW = self.w / n
  return self.x + (i - 1) * segW, self.y, segW, self.headerH
end

function Tabs:current()
  local entry = self.tabs[self.selected]
  return entry and entry.panel or nil
end

function Tabs:update(dt)
  local mx, my = love.mouse.getPosition()
  self.hoverTab = nil
  for i = 1, #self.tabs do
    if util.contains(mx, my, self:tabBounds(i)) then self.hoverTab = i; break end
  end
  local panel = self:current()
  if panel then panel:update(dt) end
end

function Tabs:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  for i, entry in ipairs(self.tabs) do
    local tx, ty, tw, th = self:tabBounds(i)
    local segColor = t.color.fg
    if i == self.selected then
      segColor = t.color.accent
    elseif i == self.hoverTab then
      segColor = t.color.hover
    end
    love.graphics.setColor(segColor)
    love.graphics.rectangle("fill", tx, ty, tw, th)
    love.graphics.setColor(t.color.border)
    love.graphics.rectangle("line", tx, ty, tw, th)
    love.graphics.setColor(t.color.text)
    local ly = ty + (th - font:getHeight()) / 2
    love.graphics.printf(entry.label, tx, ly, tw, "center")
  end

  love.graphics.setColor(r, g, b, a)

  local panel = self:current()
  if panel then panel:draw() end
end

function Tabs:mousepressed(px, py, btn)
  if btn == 1 then
    for i = 1, #self.tabs do
      if util.contains(px, py, self:tabBounds(i)) then
        if i ~= self.selected then
          self.selected = i
          if self.onChange then self.onChange(i) end
        end
        return true
      end
    end
  end
  local panel = self:current()
  if panel then return panel:mousepressed(px, py, btn) end
  return false
end

function Tabs:mousereleased(px, py, btn)
  local panel = self:current()
  if panel then panel:mousereleased(px, py, btn) end
end

function Tabs:keypressed(key)
  local panel = self:current()
  if panel then return panel:keypressed(key) end
  return false
end

function Tabs:textinput(text)
  local panel = self:current()
  if panel then return panel:textinput(text) end
  return false
end

function Tabs:wheelmoved(dx, dy)
  local panel = self:current()
  if panel and panel.wheelmoved then return panel:wheelmoved(dx, dy) end
  return false
end

return Tabs
