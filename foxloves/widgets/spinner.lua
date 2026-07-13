-- Spinner widget: an animated busy indicator for unknown-duration work.
--
-- Spinner.new{
--   x, y,
--   size = 24,          -- bounding box (square) in pixels
--   dots = 8,           -- number of dots around the ring
--   speed = 1,          -- revolutions per second
--   color = nil,        -- dot color override (table); default theme.color.accent
--   theme = <theme table>,
-- }
--
-- Non-interactive. A ring of dots fades in a rotating trail; advance it by
-- calling update(dt). Exposes self.w/self.h and :measure() (both = size) so
-- layout containers can place it.

local defaultTheme = require("foxloves.theme")

local Spinner = {}
Spinner.__index = Spinner

function Spinner.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Spinner)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.size = opts.size or 24
  self.dots = opts.dots or 8
  self.speed = opts.speed or 1
  self.color = opts.color
  self.theme = opts.theme or defaultTheme
  self.w, self.h = self.size, self.size
  self.phase = 0   -- rotation, in [0, 1)
  return self
end

-- Intrinsic size (w, h) for layout containers.
function Spinner:measure()
  return self.size, self.size
end

function Spinner:update(dt)
  self.phase = (self.phase + (dt or 0) * self.speed) % 1
end

function Spinner:draw()
  local t = self.theme
  local pr, pg, pb, pa = love.graphics.getColor()
  local color = self.color or t.color.accent

  local cx, cy = self.x + self.size / 2, self.y + self.size / 2
  local dotR = self.size / 8
  local ringR = self.size / 2 - dotR
  -- The brightest dot is the rotating head; the rest fade around the ring, so
  -- the trail reads as motion even in a single still frame.
  local head = self.phase * self.dots
  for i = 0, self.dots - 1 do
    local angle = (i / self.dots) * math.pi * 2 - math.pi / 2
    -- Distance behind the head (0 = head), wrapped into [0, dots).
    local behind = (head - i) % self.dots
    local alpha = 0.15 + 0.85 * (1 - behind / self.dots)
    love.graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * alpha)
    love.graphics.circle("fill", cx + math.cos(angle) * ringR,
      cy + math.sin(angle) * ringR, dotR)
  end

  love.graphics.setColor(pr, pg, pb, pa)
end

-- Inert to all input.
function Spinner:mousepressed(px, py, btn) return false end
function Spinner:mousereleased(px, py, btn) return false end
function Spinner:keypressed(key) return false end
function Spinner:textinput(text) return false end

return Spinner
