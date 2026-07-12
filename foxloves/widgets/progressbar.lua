-- ProgressBar widget: read-only value display.
--
-- ProgressBar.new{
--   x, y, w, h,
--   value = 0,
--   min = 0,
--   max = 1,
--   animated = true,          -- ease the fill toward value in update(dt)
--   indeterminate = false,    -- unknown-progress mode: a chunk slides across the track
--   label = nil,              -- true = "NN%", a string, or function(value,min,max,frac)
--   theme = <theme table>,
-- }
--
-- Non-interactive. Draws a background track with an accent fill sized to
-- clamp((value - min) / (max - min), 0, 1). Set bar.value to update; the fill
-- eases toward the new fraction unless animated == false. In indeterminate mode
-- value/min/max are ignored and a fixed-width chunk cycles across the track to
-- signal ongoing work of unknown duration (set bar.indeterminate to toggle).

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local FILL_SPEED = 4     -- fill eases toward the target fraction at this rate (per second)
local INDET_SPEED = 0.9  -- indeterminate chunk cycles across the track (cycles/second)
local INDET_FRAC = 0.3   -- indeterminate chunk width as a fraction of the track

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
  self.animated = opts.animated ~= false
  self.indeterminate = opts.indeterminate or false
  self.label = opts.label
  self.theme = opts.theme or defaultTheme
  self.display = self:fraction()  -- eased fill fraction; starts settled on value
  self.phase = 0                  -- indeterminate chunk position, in [0, 1)
  return self
end

-- Text for the overlay label: true = whole percent, a function is called with
-- (value, min, max, fraction), anything else is shown as-is.
function ProgressBar:_labelText()
  if self.label == true then
    if self.indeterminate then return "" end  -- percent is meaningless here
    return string.format("%d%%", math.floor(self:fraction() * 100 + 0.5))
  elseif type(self.label) == "function" then
    return self.label(self.value, self.min, self.max, self:fraction())
  end
  return tostring(self.label)
end

-- Target fraction filled, in [0, 1].
function ProgressBar:fraction()
  local span = self.max - self.min
  if span == 0 then return 0 end
  return util.clamp((self.value - self.min) / span, 0, 1)
end

function ProgressBar:update(dt)
  if self.indeterminate then
    self.phase = (self.phase + dt * INDET_SPEED) % 1
    return
  end
  local target = self:fraction()
  if not self.animated then
    self.display = target
    return
  end
  local step = FILL_SPEED * dt
  if self.display < target then
    self.display = math.min(target, self.display + step)
  elseif self.display > target then
    self.display = math.max(target, self.display - step)
  end
end

function ProgressBar:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()

  love.graphics.setColor(t.color.fg)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)

  if self.indeterminate then
    -- A fixed-width chunk slides left-to-right and wraps, clipped to the track.
    local chunkW = self.w * INDET_FRAC
    local chunkX = self.x - chunkW + self.phase * (self.w + chunkW)
    love.graphics.setScissor(self.x, self.y, self.w, self.h)
    love.graphics.setColor(t.color.accent)
    love.graphics.rectangle("fill", chunkX, self.y, chunkW, self.h, t.radius, t.radius)
    love.graphics.setScissor()
  else
    local fillW = self.w * self.display
    if fillW > 0 then
      love.graphics.setColor(t.color.accent)
      love.graphics.rectangle("fill", self.x, self.y, fillW, self.h, t.radius, t.radius)
    end
  end

  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  if self.label ~= nil then
    local font = defaultTheme.getFont(t)
    love.graphics.setFont(font)
    local txt = self:_labelText()
    if txt ~= "" then
      love.graphics.setColor(t.color.text)
      love.graphics.print(txt, self.x + (self.w - font:getWidth(txt)) / 2,
                          self.y + (self.h - font:getHeight()) / 2)
    end
  end

  love.graphics.setColor(r, g, b, a)
end

function ProgressBar:mousepressed(px, py, btn) return false end
function ProgressBar:mousereleased(px, py, btn) return false end
function ProgressBar:keypressed(key) return false end
function ProgressBar:textinput(text) return false end

return ProgressBar
