-- Panel widget: a bordered container that groups child widgets in its own
-- (relative) coordinate space.
--
-- Panel.new{
--   x, y, w, h,
--   title = nil,          -- optional header text
--   theme = <theme table>,
-- }
--
-- panel:add(child) places a child relative to the panel's content area (inside
-- the padding, below the title bar when present). Moving the panel moves its
-- children. Empty areas of the panel do not consume clicks.

local defaultTheme = require("foxloves.theme")
local Container = require("foxloves.container")

local Panel = {}
Panel.__index = Panel

function Panel.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Panel)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 200
  self.h = opts.h or 150
  self.title = opts.title
  self.theme = opts.theme or defaultTheme
  self.container = Container.new(function()
    return self.x + self.theme.padding, self.y + self:headerHeight()
  end)
  return self
end

-- Height reserved at the top for the title bar (just padding when untitled).
function Panel:headerHeight()
  local t = self.theme
  if self.title and self.title ~= "" then
    local font = defaultTheme.getFont(t)
    return font:getHeight() + t.padding * 2
  end
  return t.padding
end

function Panel:add(child)
  return self.container:add(child)
end

function Panel:remove(child)
  return self.container:remove(child)
end

function Panel:update(dt)
  self.container:update(dt)
end

function Panel:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)

  love.graphics.setColor(t.color.bg)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)

  if self.title and self.title ~= "" then
    love.graphics.setFont(font)
    love.graphics.setColor(t.color.text)
    love.graphics.print(self.title, self.x + t.padding, self.y + t.padding)
    -- separator under the title
    local sepY = self.y + self:headerHeight() - t.padding / 2
    love.graphics.setColor(t.color.border)
    love.graphics.rectangle("fill", self.x, sepY, self.w, 1)
  end

  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  love.graphics.setColor(r, g, b, a)

  self.container:draw()
end

function Panel:mousepressed(px, py, btn)
  return self.container:mousepressed(px, py, btn)
end

function Panel:mousereleased(px, py, btn)
  self.container:mousereleased(px, py, btn)
end

function Panel:keypressed(key)
  return self.container:keypressed(key)
end

function Panel:textinput(text)
  return self.container:textinput(text)
end

return Panel
