-- fox.Root: the UI manager. Owns a base layer of widgets plus a stack of
-- overlays (modals, dropdowns, tooltips) and routes LÖVE events to them with
-- correct z-order, input capture, and keyboard focus.
--
--   ui = fox.Root.new()
--   ui:add(fox.Button.new{ ... })
--   -- forward LÖVE callbacks:
--   ui:update(dt) / ui:draw()
--   ui:mousepressed(x,y,b) / ui:mousereleased(x,y,b)
--   ui:keypressed(key) / ui:textinput(text)
--
-- Overlays are pushed with root:openOverlay(widget, { modal = bool }) and
-- popped with root:closeOverlay(widget?). A modal overlay traps all input; a
-- non-modal overlay (dropdown/tooltip) is dismissed when a press lands outside
-- it. The existing per-widget contract is unchanged.

local Root = {}
Root.__index = Root

function Root.new()
  local self = setmetatable({}, Root)
  self.base = {}       -- ordered top-level widgets
  self.overlays = {}   -- LIFO of { widget = <w>, modal = <bool> }
  self.focused = nil   -- widget receiving keyboard, or nil
  return self
end

-- --------------------------------------------------------------- base layer

function Root:add(widget)
  widget.root = self  -- backref so widgets (e.g. Dropdown) can open overlays
  table.insert(self.base, widget)
  return widget
end

function Root:remove(widget)
  for i = #self.base, 1, -1 do
    if self.base[i] == widget then
      table.remove(self.base, i)
      if self.focused == widget then self.focused = nil end
      return true
    end
  end
  return false
end

-- ----------------------------------------------------------------- overlays

function Root:openOverlay(widget, opts)
  opts = opts or {}
  widget.root = self  -- so the overlay can close itself
  table.insert(self.overlays, { widget = widget, modal = opts.modal or false })
  return widget
end

-- Close a specific overlay, or the top one when widget is nil.
function Root:closeOverlay(widget)
  if widget == nil then
    local top = table.remove(self.overlays)
    if top and self.focused == top.widget then self.focused = nil end
    return top ~= nil
  end
  for i = #self.overlays, 1, -1 do
    if self.overlays[i].widget == widget then
      table.remove(self.overlays, i)
      if self.focused == widget then self.focused = nil end
      return true
    end
  end
  return false
end

function Root:topOverlay()
  return self.overlays[#self.overlays]
end

-- ------------------------------------------------------------------ update

function Root:update(dt)
  for _, w in ipairs(self.base) do w:update(dt) end
  for _, o in ipairs(self.overlays) do o.widget:update(dt) end
end

-- Base first, then overlays bottom-to-top, so overlays paint on top.
function Root:draw()
  for _, w in ipairs(self.base) do w:draw() end
  for _, o in ipairs(self.overlays) do o.widget:draw() end
end

-- ------------------------------------------------------------------- input

function Root:mousepressed(px, py, btn)
  -- Overlays get first crack, top-down.
  for i = #self.overlays, 1, -1 do
    local o = self.overlays[i]
    if o.widget:mousepressed(px, py, btn) then
      self.focused = o.widget
      return true
    end
    if o.modal then
      -- Modal swallows every press, even a miss on the scrim.
      return true
    end
    -- Non-modal miss: dismiss this overlay, then keep falling through.
    self:closeOverlay(o.widget)
  end
  -- Base layer, first-consume-wins (Tier 1 semantics).
  for _, w in ipairs(self.base) do
    if w:mousepressed(px, py, btn) then
      self.focused = w
      return true
    end
  end
  self.focused = nil
  return false
end

function Root:mousereleased(px, py, btn)
  for _, w in ipairs(self.base) do w:mousereleased(px, py, btn) end
  for _, o in ipairs(self.overlays) do o.widget:mousereleased(px, py, btn) end
end

function Root:keypressed(key)
  -- Esc closes the top overlay before anything else sees the key.
  if key == "escape" and #self.overlays > 0 then
    self:closeOverlay()
    return true
  end
  if self.focused and self.focused:keypressed(key) then return true end

  local top = self:topOverlay()
  if top and top.modal then
    -- Keyboard is confined to the modal subtree.
    return top.widget:keypressed(key)
  end
  for _, w in ipairs(self.base) do
    if w:keypressed(key) then return true end
  end
  for _, o in ipairs(self.overlays) do
    if o.widget:keypressed(key) then return true end
  end
  return false
end

function Root:textinput(text)
  if self.focused and self.focused:textinput(text) then return true end

  local top = self:topOverlay()
  if top and top.modal then
    return top.widget:textinput(text)
  end
  for _, w in ipairs(self.base) do
    if w:textinput(text) then return true end
  end
  for _, o in ipairs(self.overlays) do
    if o.widget:textinput(text) then return true end
  end
  return false
end

return Root
