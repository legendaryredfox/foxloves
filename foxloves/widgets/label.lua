-- Label widget: static, non-interactive text.
--
-- Label.new{
--   x, y,
--   w = nil,             -- optional; enables alignment (uses printf)
--   h = nil,             -- optional; enables vertical alignment within h
--   text = "",
--   align = "left",      -- "left" | "center" | "right" (needs w)
--   valign = "top",      -- "top" | "middle" | "bottom" (needs h)
--   color = nil,         -- table; overrides theme color
--   muted = false,       -- shortcut for theme.color.textMuted
--   truncate = false,    -- with w: clip to one line, ellipsis on overflow
--   theme = <theme table>,
-- }
--
-- With w set, draws via printf (wraps at w, honors align). With truncate = true
-- it stays on one line and appends "…" when the text is wider than w. Without w,
-- draws a single line via print. text is mutable at runtime (label.text = "...").

local defaultTheme = require("foxloves.theme")

local Label = {}
Label.__index = Label

function Label.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Label)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w
  self.h = opts.h
  self.text = opts.text or ""
  self.align = opts.align or "left"
  self.valign = opts.valign or "top"
  self.color = opts.color
  self.muted = opts.muted or false
  self.truncate = opts.truncate or false
  self.theme = opts.theme or defaultTheme
  return self
end

function Label:setText(text)
  self.text = text or ""
end

-- Cut text to fit width w in the given font, appending "…" when it overflows.
function Label:_truncate(font, text)
  if font:getWidth(text) <= self.w then return text end
  local ell = "\226\128\166"  -- "…" (U+2026)
  local ellW = font:getWidth(ell)
  for i = #text, 1, -1 do
    local s = text:sub(1, i)
    if font:getWidth(s) + ellW <= self.w then return s .. ell end
  end
  return ell
end

-- Draw Y after applying vertical alignment within h. Without h, returns self.y.
-- Text height is the wrapped line count when w is set, else one line.
function Label:_offsetY(font)
  if not self.h then return self.y end
  local textH
  if self.w and not self.truncate then
    local _, lines = font:getWrap(self.text, self.w)
    textH = math.max(1, #lines) * font:getHeight()
  else
    textH = font:getHeight()
  end
  if self.valign == "middle" then
    return self.y + (self.h - textH) / 2
  elseif self.valign == "bottom" then
    return self.y + self.h - textH
  end
  return self.y
end

function Label:update(dt) end

function Label:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  local color = self.color or (self.muted and t.color.textMuted) or t.color.text
  love.graphics.setColor(color)

  local dy = self:_offsetY(font)
  if self.w and self.truncate then
    love.graphics.printf(self:_truncate(font, self.text), self.x, dy, self.w, self.align)
  elseif self.w then
    love.graphics.printf(self.text, self.x, dy, self.w, self.align)
  else
    love.graphics.print(self.text, self.x, dy)
  end

  love.graphics.setColor(r, g, b, a)
end

-- Non-interactive: never consumes input.
function Label:mousepressed(px, py, btn) return false end
function Label:mousereleased(px, py, btn) return false end
function Label:keypressed(key) return false end
function Label:textinput(text) return false end

return Label
