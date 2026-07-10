-- Modal / Dialog widget: a blocking overlay with a title, message, and buttons.
--
-- Modal.new{
--   w = 320, h = 180,
--   title = "",
--   message = nil,
--   buttons = { { label = "OK", onClick = function() end } },
--   theme = <theme table>,
-- }
--
-- Open it with root:openOverlay(modal, { modal = true }); it then traps all
-- input, dims the screen, and centers a panel. Each button runs its onClick
-- and then closes the modal. Esc also closes it (handled by Root).

local defaultTheme = require("foxloves.theme")
local Button = require("foxloves.widgets.button")

local Modal = {}
Modal.__index = Modal

function Modal.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Modal)
  self.w = opts.w or 320
  self.h = opts.h or 180
  self.title = opts.title or ""
  self.message = opts.message
  self.theme = opts.theme or defaultTheme
  self.x, self.y = 0, 0  -- filled by layout()

  self.buttons = {}
  for _, spec in ipairs(opts.buttons or { { label = "OK" } }) do
    local btn = Button.new{
      w = 100, h = 32, label = spec.label or "OK", theme = self.theme,
      onClick = function()
        if spec.onClick then spec.onClick() end
        if self.root then self.root:closeOverlay(self) end
      end,
    }
    table.insert(self.buttons, btn)
  end
  return self
end

-- Center the panel and lay the buttons along its bottom-right.
function Modal:layout()
  local t = self.theme
  local screenW, screenH = love.graphics.getDimensions()
  self.x = math.floor((screenW - self.w) / 2)
  self.y = math.floor((screenH - self.h) / 2)

  local bx = self.x + self.w - t.padding
  local by = self.y + self.h - t.padding - 32
  for i = #self.buttons, 1, -1 do
    local btn = self.buttons[i]
    bx = bx - btn.w
    btn.x, btn.y = bx, by
    bx = bx - t.padding
  end
end

function Modal:update(dt)
  self:layout()
  for _, btn in ipairs(self.buttons) do btn:update(dt) end
end

function Modal:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  local screenW, screenH = love.graphics.getDimensions()

  -- Scrim: dim the whole screen behind the dialog.
  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.rectangle("fill", 0, 0, screenW, screenH)

  -- Dialog panel.
  love.graphics.setColor(t.color.bg)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)
  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  love.graphics.setFont(font)
  love.graphics.setColor(t.color.text)
  love.graphics.print(self.title, self.x + t.padding, self.y + t.padding)
  if self.message then
    love.graphics.setColor(t.color.textMuted)
    love.graphics.printf(self.message, self.x + t.padding,
      self.y + t.padding * 2 + font:getHeight(),
      self.w - t.padding * 2, "left")
  end

  love.graphics.setColor(r, g, b, a)

  for _, btn in ipairs(self.buttons) do btn:draw() end
end

function Modal:mousepressed(px, py, btn)
  for _, b in ipairs(self.buttons) do
    if b:mousepressed(px, py, btn) then return true end
  end
  return false
end

function Modal:mousereleased(px, py, btn)
  for _, b in ipairs(self.buttons) do b:mousereleased(px, py, btn) end
end

function Modal:keypressed(key) return false end
function Modal:textinput(text) return false end

return Modal
