-- ContextMenu widget: a right-click popup menu of actions.
--
-- ContextMenu.new{
--   target = { x, y, w, h },   -- optional area that right-click opens the menu
--   items = {
--     { label = "Cut",  onClick = function() end },
--     { label = "Copy", onClick = function() end, enabled = false },
--     { separator = true },
--     { label = "Paste", onClick = function() end },
--   },
--   theme = <theme table>,
-- }
--
-- Right-clicking inside `target` (button 2) opens the menu at the cursor as a
-- non-modal overlay; it is dismissed by clicking outside (handled by Root) or
-- Esc. You can also open it programmatically at any point with
-- menu:openAt(px, py) -- handy for a menu that covers a whole panel or the
-- window. Selecting an enabled row runs its onClick and closes the menu.
-- Up/Down move the highlight (skipping separators and disabled rows),
-- Enter/Space activate, Esc closes.
--
-- Must be added to a fox.Root (root:add) so it can open its popup overlay.

local defaultTheme = require("foxloves.theme")
local util = require("foxloves.util")

local ContextMenu = {}
ContextMenu.__index = ContextMenu

local SEP_H = 9   -- height of a separator row
local EDGE = 4    -- keep this many pixels between the menu and the screen edge

-- ------------------------------------------------------------ popup (internal)

local Popup = {}
Popup.__index = Popup

-- True when item i is a landable target (enabled action, not a separator).
local function selectable(item)
  return not item.separator and item.enabled ~= false
end

local function openPopup(menu, px, py)
  local self = setmetatable({}, Popup)
  self.menu = menu
  self.theme = menu.theme
  self.hover = nil     -- row under the cursor
  self.active = nil    -- keyboard-highlighted row

  local t = menu.theme
  local font = defaultTheme.getFont(t)
  self.rowH = font:getHeight() + t.padding

  -- Width fits the widest label plus padding; height is the sum of rows.
  local w = 0
  local h = 0
  for _, item in ipairs(menu.items) do
    if item.separator then
      h = h + SEP_H
    else
      w = math.max(w, font:getWidth(item.label or ""))
      h = h + self.rowH
    end
  end
  self.w = math.max(w + t.padding * 2, 96)
  self.h = h

  -- Anchor at the cursor, then clamp fully on screen.
  local screenW, screenH = love.graphics.getDimensions()
  self.x = util.clamp(px, EDGE, math.max(EDGE, screenW - self.w - EDGE))
  self.y = util.clamp(py, EDGE, math.max(EDGE, screenH - self.h - EDGE))
  return self
end

-- Top y of row i in screen space (rows stack from self.y).
function Popup:rowTop(i)
  local y = self.y
  for k = 1, i - 1 do
    y = y + (self.menu.items[k].separator and SEP_H or self.rowH)
  end
  return y
end

-- Index of the selectable row at viewport y, or nil.
function Popup:rowAt(py)
  for i, item in ipairs(self.menu.items) do
    local top = self:rowTop(i)
    local rh = item.separator and SEP_H or self.rowH
    if selectable(item) and py >= top and py <= top + rh then return i end
  end
  return nil
end

-- Move the keyboard highlight to the next selectable row in `dir` (+1/-1).
function Popup:_move(dir)
  local n = #self.menu.items
  if n == 0 then return end
  local i = self.active or (dir > 0 and 0 or n + 1)
  for _ = 1, n do
    i = (i - 1 + dir) % n + 1
    if selectable(self.menu.items[i]) then self.active = i; return end
  end
end

function Popup:_activate(i)
  local item = self.menu.items[i]
  if not (item and selectable(item)) then return end
  if self.menu.root then self.menu.root:closeOverlay(self) end
  if item.onClick then item.onClick() end
end

function Popup:update(dt)
  local mx, my = love.mouse.getPosition()
  self.hover = nil
  if util.contains(mx, my, self.x, self.y, self.w, self.h) then
    self.hover = self:rowAt(my)
  end
end

function Popup:draw()
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  love.graphics.setColor(t.color.fg)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, t.radius, t.radius)

  love.graphics.setScissor(self.x, self.y, self.w, self.h)
  for i, item in ipairs(self.menu.items) do
    local top = self:rowTop(i)
    if item.separator then
      love.graphics.setColor(t.color.border)
      love.graphics.line(self.x + t.padding, top + SEP_H / 2,
                         self.x + self.w - t.padding, top + SEP_H / 2)
    else
      if i == self.hover or i == self.active then
        love.graphics.setColor(t.color.hover)
        love.graphics.rectangle("fill", self.x, top, self.w, self.rowH)
      end
      local muted = item.enabled == false
      love.graphics.setColor(muted and t.color.textMuted or t.color.text)
      love.graphics.print(item.label or "", self.x + t.padding,
                          top + (self.rowH - font:getHeight()) / 2)
    end
  end
  love.graphics.setScissor()

  love.graphics.setColor(t.color.border)
  love.graphics.rectangle("line", self.x, self.y, self.w, self.h, t.radius, t.radius)

  love.graphics.setColor(r, g, b, a)
end

function Popup:mousepressed(px, py, btn)
  if not util.contains(px, py, self.x, self.y, self.w, self.h) then
    return false  -- outside: let Root dismiss + fall through
  end
  if btn == 1 then
    local i = self:rowAt(py)
    if i then self:_activate(i) end
  end
  return true  -- press inside the menu is consumed (keeps it open on misses)
end

function Popup:mousereleased(px, py, btn) return false end

function Popup:keypressed(key)
  if key == "up" then self:_move(-1); return true end
  if key == "down" then self:_move(1); return true end
  if (key == "return" or key == "kpenter" or key == "space") and self.active then
    self:_activate(self.active); return true
  end
  return false
end

function Popup:textinput(text) return false end

-- ----------------------------------------------------------- contextmenu API

function ContextMenu.new(opts)
  opts = opts or {}
  local self = setmetatable({}, ContextMenu)
  self.target = opts.target  -- optional { x, y, w, h }
  self.items = opts.items or {}
  self.theme = opts.theme or defaultTheme
  self.root = nil  -- set by Root:add
  self.focusable = false
  return self
end

-- Open the menu at (px, py) as a non-modal overlay.
function ContextMenu:openAt(px, py)
  if self.root then
    return self.root:openOverlay(openPopup(self, px, py), { modal = false })
  end
end

function ContextMenu:update(dt) end
function ContextMenu:draw() end

-- Right-click inside the target opens the menu at the cursor.
function ContextMenu:mousepressed(px, py, btn)
  if btn == 2 and self.target
     and util.contains(px, py, self.target.x, self.target.y,
                       self.target.w, self.target.h) then
    self:openAt(px, py)
    return true
  end
  return false
end

function ContextMenu:mousereleased(px, py, btn) return false end
function ContextMenu:keypressed(key) return false end
function ContextMenu:textinput(text) return false end

return ContextMenu
