-- Checkbox widget: boolean toggle with a check mark and optional label.
--
-- Checkbox.new{
--   x, y,
--   size = 20,            -- box side length
--   label = nil,          -- optional text to the right of the box
--   checked = false,
--   onChange = function(checked) end,
--   disabled = false,
--   theme = <theme table>,
-- }
--
-- Toggles on mouserelease inside when the press also began inside (Button-like).
-- Hit area covers the box and the label. Fires onChange(checked) on toggle.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local Checkbox = {}
Checkbox.__index = Checkbox

function Checkbox.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Checkbox)
  self.x = opts.x or 0
  self.y = opts.y or 0
  self.size = opts.size or 20
  self.label = opts.label
  self.checked = opts.checked or false
  self.onChange = opts.onChange
  self.disabled = opts.disabled or false
  self.theme = opts.theme or defaultTheme
  self.pressed = false
  self.focusable = true
  return self
end

function Checkbox:_toggle()
  self.checked = not self.checked
  if self.onChange then self.onChange(self.checked) end
end

-- Hit rectangle spans the box plus any label text.
function Checkbox:bounds()
  local t = self.theme
  local w = self.size
  if self.label and self.label ~= "" then
    local font = defaultTheme.getFont(t)
    w = w + t.padding + font:getWidth(self.label)
  end
  return self.x, self.y, w, self.size
end

function Checkbox:contains(px, py)
  return util.contains(px, py, self:bounds())
end

function Checkbox:update(dt) end

function Checkbox:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  local box = self.size
  love.graphics.setColor(self.disabled and t.color.disabled or t.color.fg)
  love.graphics.rectangle("fill", self.x, self.y, box, box, t.radius, t.radius)
  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, box, box, t.radius, t.radius)

  if util.isFocused(self) then util.focusRing(t, self.x, self.y, box, box) end

  if self.checked then
    -- Simple check mark: two strokes inside the box.
    love.graphics.setColor(self.disabled and t.color.textMuted or t.color.accent)
    local x, y = self.x, self.y
    love.graphics.line(
      x + box * 0.22, y + box * 0.52,
      x + box * 0.42, y + box * 0.72,
      x + box * 0.78, y + box * 0.28)
  end

  if self.label and self.label ~= "" then
    love.graphics.setColor(self.disabled and t.color.textMuted or t.color.text)
    local ty = self.y + (box - font:getHeight()) / 2
    love.graphics.print(self.label, self.x + box + t.padding, ty)
  end

  love.graphics.setColor(r, g, b, a)
end

function Checkbox:mousepressed(px, py, btn)
  if self.disabled or btn ~= 1 then return false end
  if self:contains(px, py) then
    self.pressed = true
    return true
  end
  return false
end

function Checkbox:mousereleased(px, py, btn)
  if btn ~= 1 then return false end
  local wasPressed = self.pressed
  self.pressed = false
  if self.disabled or not wasPressed then return false end
  if self:contains(px, py) then
    self:_toggle()
    return true
  end
  return false
end

function Checkbox:keypressed(key)
  if self.disabled or not util.isFocused(self) then return false end
  if key == "space" or key == "return" or key == "kpenter" then
    self:_toggle()
    return true
  end
  return false
end
function Checkbox:textinput() return false end

return Checkbox
