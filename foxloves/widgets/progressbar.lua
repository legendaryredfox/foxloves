-- ProgressBar widget: read-only value display.
--
-- ProgressBar.new{
--   x, y, w, h,
--   value = 0,
--   min = 0,
--   max = 1,
--   theme = <theme table>,
-- }
--
-- Non-interactive. Draws a background track with an accent fill sized to
-- clamp((value - min) / (max - min), 0, 1). Set bar.value to update.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar.new(opts)
  opts = opts or {}
  local self = setmetatable({}, ProgressBar)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w or 200
  self.h = opts.h or 16
  self.value = opts.value or 0
  self.min = opts.min or 0
  self.max = opts.max or 1
  self.theme = opts.theme or defaultTheme
  return self
end

-- Fraction filled, in [0, 1].
function ProgressBar:fraction()
  local span = self.max - self.min
  if span == 0 then return 0 end
  return util.clamp((self.value - self.min) / span, 0, 1)
end

function ProgressBar:update(dt) end

function ProgressBar:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()

  love.graphics.setColor(t.color.fg)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)

  local fillW = self.w * self:fraction()
  if fillW > 0 then
    love.graphics.setColor(t.color.accent)
    love.graphics.rectangle("fill", self.x, self.y, fillW, self.h, t.radius, t.radius)
  end

  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  love.graphics.setColor(r, g, b, a)
end

function ProgressBar:mousepressed(px, py, btn) return false end
function ProgressBar:mousereleased(px, py, btn) return false end
function ProgressBar:keypressed(key) return false end
function ProgressBar:textinput(text) return false end

return ProgressBar
