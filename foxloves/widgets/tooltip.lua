-- Tooltip widget: a hover-triggered floating hint.
--
-- Tooltip.new{
--   target = { x, y, w, h },   -- area that triggers the hint
--   text = "",
--   delay = 0.6,                -- seconds of hover before showing
--   theme = <theme table>,
-- }
--
-- Polls the mouse each update; once the cursor has hovered the target for
-- `delay` seconds, a small box appears near the cursor. Non-blocking: it never
-- captures input. Add it after the widgets it annotates so it draws on top.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local Tooltip = {}
Tooltip.__index = Tooltip

function Tooltip.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Tooltip)
  self.target = opts.target or { x = 0, y = 0, w = 0, h = 0 }
  self.text = opts.text or ""
  self.delay = opts.delay or 0.6
  self.theme = opts.theme or defaultTheme
  self.hoverTime = 0
  self.visible = false
  self.mx, self.my = 0, 0
  return self
end

function Tooltip:update(dt)
  local mx, my = love.mouse.getPosition()
  self.mx, self.my = mx, my
  local t = self.target
  if util.contains(mx, my, t.x, t.y, t.w, t.h) then
    self.hoverTime = self.hoverTime + dt
    self.visible = self.hoverTime >= self.delay
  else
    self.hoverTime = 0
    self.visible = false
  end
end

function Tooltip:draw()
  if not self.visible then return end
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  local pad = t.padding
  local boxW = font:getWidth(self.text) + pad * 2
  local boxH = font:getHeight() + pad
  local bx = self.mx + 12
  local by = self.my + 12

  love.graphics.setColor(t.color.fg)
  love.graphics.rectangle("fill", bx, by, boxW, boxH, t.radius, t.radius)
  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", bx, by, boxW, boxH, t.radius, t.radius)
  love.graphics.setColor(t.color.text)
  love.graphics.print(self.text, bx + pad, by + pad / 2)

  love.graphics.setColor(r, g, b, a)
end

-- Non-blocking: never consumes input.
function Tooltip:mousepressed(px, py, btn) return false end
function Tooltip:mousereleased(px, py, btn) return false end
function Tooltip:keypressed(key) return false end
function Tooltip:textinput(text) return false end

return Tooltip
