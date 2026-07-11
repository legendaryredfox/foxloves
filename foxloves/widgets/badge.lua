-- Badge / Tag / Chip widget: a small rounded label for counts or status.
-- Self-sizes to its text (pill-shaped); optionally removable as a chip.
--
-- Badge.new{
--   x, y,
--   text = "",
--   color = nil,          -- fill override (table); default theme.color.accent
--   textColor = nil,      -- label color override; default theme.color.bg
--   removable = false,    -- draw a × hitbox on the right; fires onRemove on click
--   onRemove = function(self) end,
--   theme = <theme table>,
-- }
--
-- Non-interactive unless `removable`. Exposes computed self.w/self.h and a
-- :measure() returning w,h so layout containers can place it. `text` is mutable
-- via setText, which re-measures.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local Badge = {}
Badge.__index = Badge

-- Recompute w/h from the current text and font metrics.
local function measureSelf(self)
  local t = self.theme
  local font = defaultTheme.getFont(t)
  local textW = font:getWidth(self.text)
  local textH = font:getHeight()
  local hpad = t.padding
  local vpad = math.floor(t.padding / 2)
  self.textH = textH
  self.h = textH + vpad * 2
  -- The × hitbox is a square the height of the text, gapped from the label.
  self.removeSize = textH
  local removeArea = self.removable and (vpad + self.removeSize) or 0
  self.w = hpad + textW + removeArea + hpad
end

function Badge.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Badge)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.text = opts.text or ""
  self.color = opts.color
  self.textColor = opts.textColor
  self.removable = opts.removable or false
  self.onRemove = opts.onRemove
  self.theme = opts.theme or defaultTheme
  self.removeHovered = false
  self.removePressed = false
  measureSelf(self)
  return self
end

function Badge:setText(text)
  self.text = text or ""
  measureSelf(self)
end

-- Returns the badge's intrinsic size (w, h) for layout containers.
function Badge:measure()
  return self.w, self.h
end

-- Bounds of the × hitbox (removable only), in the badge's own coord space.
function Badge:removeRect()
  local t = self.theme
  local size = self.removeSize
  local rx = self.x + self.w - t.padding - size
  local ry = self.y + (self.h - size) / 2
  return rx, ry, size, size
end

function Badge:update(dt) end

function Badge:mousemoved(px, py)
  if not self.removable then return end
  local rx, ry, rw, rh = self:removeRect()
  self.removeHovered = util.contains(px, py, rx, ry, rw, rh)
end

function Badge:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  local radius = self.h / 2
  love.graphics.setColor(self.color or t.color.accent)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, radius, radius)

  local vpad = math.floor(t.padding / 2)
  love.graphics.setColor(self.textColor or t.color.bg)
  love.graphics.print(self.text, self.x + t.padding, self.y + vpad)

  if self.removable then
    local rx, ry, rw, rh = self:removeRect()
    -- Brighter × on hover for affordance; muted otherwise.
    love.graphics.setColor(self.removeHovered and t.color.text or t.color.textMuted)
    local pad = rw * 0.28
    love.graphics.line(rx + pad, ry + pad, rx + rw - pad, ry + rh - pad)
    love.graphics.line(rx + rw - pad, ry + pad, rx + pad, ry + rh - pad)
  end

  love.graphics.setColor(r, g, b, a)
end

function Badge:mousepressed(px, py, btn)
  if not self.removable or btn ~= 1 then return false end
  local rx, ry, rw, rh = self:removeRect()
  if util.contains(px, py, rx, ry, rw, rh) then
    self.removePressed = true
    return true
  end
  return false
end

function Badge:mousereleased(px, py, btn)
  if btn ~= 1 then return false end
  local wasPressed = self.removePressed
  self.removePressed = false
  if not self.removable or not wasPressed then return false end
  local rx, ry, rw, rh = self:removeRect()
  if util.contains(px, py, rx, ry, rw, rh) then
    if self.onRemove then self.onRemove(self) end
    return true
  end
  return false
end

-- Inert to the keyboard: removal is pointer-only.
function Badge:keypressed(key) return false end
function Badge:textinput(text) return false end

return Badge
