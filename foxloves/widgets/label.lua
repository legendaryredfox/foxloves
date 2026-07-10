-- Label widget: static, non-interactive text.
--
-- Label.new{
--   x, y,
--   w = nil,             -- optional; enables alignment (uses printf)
--   text = "",
--   align = "left",      -- "left" | "center" | "right" (needs w)
--   color = nil,         -- table; overrides theme color
--   muted = false,       -- shortcut for theme.color.textMuted
--   theme = <theme table>,
-- }
--
-- With w set, draws via printf (wraps at w, honors align). Without w, draws a
-- single line via print. text is mutable at runtime (label.text = "...").

local defaultTheme = require("foxloves.theme")

local Label = {}
Label.__index = Label

function Label.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Label)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.w = opts.w
  self.text = opts.text or ""
  self.align = opts.align or "left"
  self.color = opts.color
  self.muted = opts.muted or false
  self.theme = opts.theme or defaultTheme
  return self
end

function Label:setText(text)
  self.text = text or ""
end

function Label:update(dt) end

function Label:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  local color = self.color or (self.muted and t.color.textMuted) or t.color.text
  love.graphics.setColor(color)

  if self.w then
    love.graphics.printf(self.text, self.x, self.y, self.w, self.align)
  else
    love.graphics.print(self.text, self.x, self.y)
  end

  love.graphics.setColor(r, g, b, a)
end

-- Non-interactive: never consumes input.
function Label:mousepressed(px, py, btn) return false end
function Label:mousereleased(px, py, btn) return false end
function Label:keypressed(key) return false end
function Label:textinput(text) return false end

return Label
