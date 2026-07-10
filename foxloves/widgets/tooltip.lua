-- Tooltip widget: a hover-triggered floating hint.
--
-- Tooltip.new{
--   target = { x, y, w, h },   -- area that triggers the hint
--   text = "",
--   delay = 0.6,                -- seconds of hover before showing
--   maxWidth = nil,             -- wrap text at this pixel width (multi-line)
--   theme = <theme table>,
-- }
--
-- Polls the mouse each update; once the cursor has hovered the target for
-- `delay` seconds, a small box fades in near the cursor. The box is kept on
-- screen (clamped to the window) and fades out when the cursor leaves.
-- Non-blocking: it never captures input. Add it after the widgets it annotates
-- so it draws on top.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local FADE_SPEED = 12  -- alpha units per second toward the target
local EDGE = 4         -- keep this many pixels between the box and the screen

local Tooltip = {}
Tooltip.__index = Tooltip

function Tooltip.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Tooltip)
  self.target = opts.target or { x = 0, y = 0, w = 0, h = 0 }
  self.text = opts.text or ""
  self.delay = opts.delay or 0.6
  self.maxWidth = opts.maxWidth
  self.theme = opts.theme or defaultTheme
  self.hoverTime = 0
  self.visible = false
  self.alpha = 0
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
  -- Ease alpha toward the target so show/hide fade instead of popping.
  local target = self.visible and 1 or 0
  if self.alpha < target then
    self.alpha = math.min(target, self.alpha + FADE_SPEED * dt)
  elseif self.alpha > target then
    self.alpha = math.max(target, self.alpha - FADE_SPEED * dt)
  end
end

-- Measure the hint box: single-line by default, wrapped when maxWidth is set.
function Tooltip:_measure(font)
  local pad = self.theme.padding
  if self.maxWidth then
    local wrapW, lines = font:getWrap(self.text, self.maxWidth)
    return wrapW + pad * 2, #lines * font:getHeight() + pad, wrapW
  end
  return font:getWidth(self.text) + pad * 2, font:getHeight() + pad, nil
end

function Tooltip:draw()
  if self.alpha <= 0.01 then return end
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  local pad = t.padding
  local boxW, boxH, wrapW = self:_measure(font)

  -- Anchor near the cursor, then clamp fully on screen.
  local screenW, screenH = love.graphics.getDimensions()
  local bx = math.min(self.mx + 12, screenW - boxW - EDGE)
  local by = math.min(self.my + 12, screenH - boxH - EDGE)
  bx = math.max(EDGE, bx)
  by = math.max(EDGE, by)

  local al = self.alpha
  local function setColor(c) love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * al) end

  setColor(t.color.fg)
  love.graphics.rectangle("fill", bx, by, boxW, boxH, t.radius, t.radius)
  setColor(t.color.border)
  love.graphics.rectangle("line", bx, by, boxW, boxH, t.radius, t.radius)
  setColor(t.color.text)
  if wrapW then
    love.graphics.printf(self.text, bx + pad, by + pad / 2, wrapW, "left")
  else
    love.graphics.print(self.text, bx + pad, by + pad / 2)
  end

  love.graphics.setColor(r, g, b, a)
end

-- Non-blocking: never consumes input.
function Tooltip:mousepressed(px, py, btn) return false end
function Tooltip:mousereleased(px, py, btn) return false end
function Tooltip:keypressed(key) return false end
function Tooltip:textinput(text) return false end

return Tooltip
