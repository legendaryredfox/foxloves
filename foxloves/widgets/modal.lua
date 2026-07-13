-- Modal / Dialog widget: a blocking overlay with a title, message, and buttons.
--
-- Modal.new{
--   w = 320, h = 180,
--   title = "",
--   message = nil,
--   buttons = { { label = "OK", onClick = function() end } },
--   closable = false,        -- draw a top-right × that dismisses the modal
--   dismissOnScrim = false,  -- click the dimmed backdrop (outside the panel) to close
--   theme = <theme table>,
-- }
--
-- Open it with root:openOverlay(modal, { modal = true }); it then traps all
-- input, dims the screen, and centers a panel. Each button runs its onClick
-- and then closes the modal. Esc also closes it (handled by Root); with
-- closable = true a corner × closes it too, and dismissOnScrim = true lets a
-- click on the backdrop outside the panel dismiss it.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")
local Button = require("foxloves.widgets.button")

local ANIM_SPEED = 6  -- entrance ease rate (anim units per second; ~0.17s to open)

local Modal = {}
Modal.__index = Modal

function Modal.new(opts)
  opts = opts or {}
  local self = setmetatable({}, Modal)
  self.w = opts.w or 320
  self.h = opts.h or 180
  self.title = opts.title or ""
  self.message = opts.message
  self.closable = opts.closable or false
  self.dismissOnScrim = opts.dismissOnScrim or false
  self.theme = opts.theme or defaultTheme
  self.x, self.y = 0, 0  -- filled by layout()
  -- Entrance animation: anim eases 0->1 in update; draw fades scrim + panel by
  -- it. animated = false snaps straight to fully shown.
  self.anim = opts.animated == false and 1 or 0

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
  -- Default focus is the primary (rightmost) button, which Enter activates.
  self.focusIndex = #self.buttons > 0 and #self.buttons or nil
  return self
end

-- Fire the button at index i (runs its onClick, which also closes the modal).
function Modal:_activate(i)
  local btn = self.buttons[i]
  if btn and btn.onClick then btn.onClick(btn) end
end

-- Hit rect of the close × (x, y, w, h) in screen space, or nil when not
-- closable. Depends on the panel position from the latest layout().
function Modal:_closeRect()
  if not self.closable then return nil end
  local t = self.theme
  local s = 18
  return self.x + self.w - t.padding - s, self.y + t.padding, s, s
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
  if self.anim < 1 then
    self.anim = math.min(1, self.anim + (dt or 0) * ANIM_SPEED)
  end
  for _, btn in ipairs(self.buttons) do btn:update(dt) end
end

function Modal:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  local screenW, screenH = love.graphics.getDimensions()
  local anim = self.anim
  -- Fade scrim + panel by the entrance progress. tint() applies anim as alpha
  -- to a theme color so the dialog eases in together with the scrim.
  local function tint(c) return c[1], c[2], c[3], (c[4] or 1) * anim end

  -- Scrim: dim the whole screen behind the dialog.
  love.graphics.setColor(0, 0, 0, 0.55 * anim)
  love.graphics.rectangle("fill", 0, 0, screenW, screenH)

  -- Dialog panel.
  love.graphics.setColor(tint(t.color.bg))
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)
  love.graphics.setColor(tint(t.color.border))
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  love.graphics.setFont(font)
  love.graphics.setColor(tint(t.color.text))
  love.graphics.print(self.title, self.x + t.padding, self.y + t.padding)
  if self.message then
    love.graphics.setColor(tint(t.color.textMuted))
    love.graphics.printf(self.message, self.x + t.padding,
      self.y + t.padding * 2 + font:getHeight(),
      self.w - t.padding * 2, "left")
  end

  -- Close × in the top-right corner.
  if self.closable then
    local cx, cy, cw, ch = self:_closeRect()
    love.graphics.setColor(tint(t.color.textMuted))
    love.graphics.line(cx + 4, cy + 4, cx + cw - 4, cy + ch - 4)
    love.graphics.line(cx + cw - 4, cy + 4, cx + 4, cy + ch - 4)
  end

  love.graphics.setColor(r, g, b, a)

  for _, btn in ipairs(self.buttons) do btn:draw() end

  -- Focus ring on the trapped focus target.
  local fb = self.focusIndex and self.buttons[self.focusIndex]
  if fb then
    util.focusRing(t, fb.x, fb.y, fb.w, fb.h)
    love.graphics.setColor(r, g, b, a)
  end
end

function Modal:mousepressed(px, py, btn)
  if self.closable and btn == 1 then
    local cx, cy, cw, ch = self:_closeRect()
    if util.contains(px, py, cx, cy, cw, ch) then
      if self.root then self.root:closeOverlay(self) end
      return true
    end
  end
  for _, b in ipairs(self.buttons) do
    if b:mousepressed(px, py, btn) then return true end
  end
  -- A left-click on the backdrop (outside the panel) dismisses when enabled;
  -- clicks inside the panel body are swallowed by Root's modal trap.
  if self.dismissOnScrim and btn == 1
     and not util.contains(px, py, self.x, self.y, self.w, self.h) then
    if self.root then self.root:closeOverlay(self) end
    return true
  end
  return false
end

function Modal:mousereleased(px, py, btn)
  for _, b in ipairs(self.buttons) do b:mousereleased(px, py, btn) end
end

-- Buttons sit in screen space (the modal is an overlay), so motion passes
-- through unchanged, like mousepressed.
function Modal:mousemoved(px, py, dx, dy)
  for _, b in ipairs(self.buttons) do b:mousemoved(px, py, dx, dy) end
end

-- Focus is trapped inside the modal (Root routes all keys here while it is the
-- top modal overlay). Tab/Shift-Tab and Left/Right cycle the buttons;
-- Enter/Space activate the focused one (Enter defaults to the primary button).
function Modal:keypressed(key)
  local n = #self.buttons
  if n == 0 then return false end
  local cur = self.focusIndex or n
  if key == "tab" then
    local reverse = love.keyboard.isDown("lshift", "rshift")
    self.focusIndex = reverse and ((cur - 2) % n + 1) or (cur % n + 1)
    return true
  elseif key == "left" then
    self.focusIndex = (cur - 2) % n + 1; return true
  elseif key == "right" then
    self.focusIndex = cur % n + 1; return true
  elseif key == "return" or key == "kpenter" or key == "space" then
    self:_activate(self.focusIndex or n); return true
  end
  return false
end
function Modal:textinput(text) return false end

return Modal
