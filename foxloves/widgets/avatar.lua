-- Avatar / Image widget: a framed image, circle or rounded square, with an
-- initials fallback when no image is given.
--
-- Avatar.new{
--   x, y,
--   size = 40,            -- square; w = h = size
--   image = nil,          -- love Image; cover-scaled and cropped to the frame
--   name = nil,           -- derives fallback initials ("Red Fox" -> "RF")
--   initials = nil,       -- explicit override; wins over name
--   shape = "circle",     -- "circle" | "rounded"
--   color = nil,          -- fallback fill when there is no image; default accent
--   textColor = nil,      -- initials color; default theme.color.bg
--   theme = <theme table>,
-- }
--
-- Non-interactive. Exposes self.w/self.h (= size) and :measure() so layout
-- containers can place it.

local defaultTheme = require("foxloves.theme")

local Avatar = {}
Avatar.__index = Avatar

-- First letter of up to the first two whitespace-separated words, uppercased.
local function initialsFromName(name)
  if not name then return "" end
  local parts = {}
  for word in tostring(name):gmatch("%S+") do
    parts[#parts + 1] = word:sub(1, 1):upper()
    if #parts == 2 then break end
  end
  return table.concat(parts)
end

function Avatar.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Avatar)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.size = opts.size or 40
  self.w, self.h = self.size, self.size
  self.image = opts.image
  self.initials = opts.initials or initialsFromName(opts.name)
  self.shape = opts.shape or "circle"
  self.color = opts.color
  self.textColor = opts.textColor
  self.theme = opts.theme or defaultTheme
  return self
end

-- Intrinsic size (w, h) for layout containers.
function Avatar:measure()
  return self.w, self.h
end

function Avatar:update(dt) end

-- Draw the frame outline for the current shape.
local function frameOutline(self, mode)
  local t = self.theme
  local s = self.size
  if self.shape == "circle" then
    love.graphics.circle(mode, self.x + s / 2, self.y + s / 2, s / 2)
  else
    love.graphics.rectangle(mode, self.x, self.y, s, s, t.radius, t.radius)
  end
end

-- Cover-scale the image to fill the frame, center-cropped, clipped to shape.
local function drawImage(self)
  local s = self.size
  local iw, ih = self.image:getWidth(), self.image:getHeight()
  local scale = s / math.min(iw, ih)
  local drawW, drawH = iw * scale, ih * scale
  local ox = self.x + (s - drawW) / 2
  local oy = self.y + (s - drawH) / 2

  if self.shape == "circle" then
    love.graphics.stencil(function() frameOutline(self, "fill") end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.draw(self.image, ox, oy, 0, scale, scale)
    love.graphics.setStencilTest()
  else
    love.graphics.setScissor(self.x, self.y, s, s)
    love.graphics.draw(self.image, ox, oy, 0, scale, scale)
    love.graphics.setScissor()
  end
end

function Avatar:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()

  if self.image then
    love.graphics.setColor(1, 1, 1, 1)
    drawImage(self)
  else
    -- Fallback: filled shape with centered initials.
    love.graphics.setColor(self.color or t.color.accent)
    frameOutline(self, "fill")
    if self.initials ~= "" then
      local font = defaultTheme.getFont(t)
      love.graphics.setFont(font)
      love.graphics.setColor(self.textColor or t.color.bg)
      local tw = font:getWidth(self.initials)
      local th = font:getHeight()
      love.graphics.print(self.initials,
        self.x + (self.size - tw) / 2, self.y + (self.size - th) / 2)
    end
  end

  love.graphics.setColor(t.color.border)
  frameOutline(self, "line")

  love.graphics.setColor(r, g, b, a)
end

-- Non-interactive: never consumes input.
function Avatar:mousepressed(px, py, btn) return false end
function Avatar:mousereleased(px, py, btn) return false end
function Avatar:keypressed(key) return false end
function Avatar:textinput(text) return false end

return Avatar
