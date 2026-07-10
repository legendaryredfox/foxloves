-- Container: shared child-management + relative-coordinate helper for widgets
-- that hold other widgets (Panel, Tabs). Not a standalone widget.
--
--   local c = Container.new(function() return ox, oy end)  -- content origin
--   c:add(child)                                            -- child in local space
--   c:update(dt) / c:draw() / c:mousepressed(px, py, btn) / ...
--
-- Children are positioned relative to the content origin. draw() translates by
-- the origin; input handlers subtract the origin so children see local coords.
-- Nesting composes because each level applies its own offset.

local Container = {}
Container.__index = Container

-- originFn() must return the content origin (ox, oy) in the parent's coord space.
function Container.new(originFn)
  local self = setmetatable({}, Container)
  self.children = {}
  self.originFn = originFn
  return self
end

function Container:add(child)
  table.insert(self.children, child)
  return child
end

function Container:remove(child)
  for i = #self.children, 1, -1 do
    if self.children[i] == child then
      table.remove(self.children, i)
      return true
    end
  end
  return false
end

function Container:update(dt)
  for _, c in ipairs(self.children) do c:update(dt) end
end

function Container:draw()
  local ox, oy = self.originFn()
  love.graphics.push()
  love.graphics.translate(ox, oy)
  for _, c in ipairs(self.children) do c:draw() end
  love.graphics.pop()
end

function Container:mousepressed(px, py, btn)
  local ox, oy = self.originFn()
  local lx, ly = px - ox, py - oy
  for _, c in ipairs(self.children) do
    if c:mousepressed(lx, ly, btn) then return true end
  end
  return false
end

function Container:mousereleased(px, py, btn)
  local ox, oy = self.originFn()
  local lx, ly = px - ox, py - oy
  for _, c in ipairs(self.children) do c:mousereleased(lx, ly, btn) end
end

function Container:keypressed(key)
  for _, c in ipairs(self.children) do
    if c:keypressed(key) then return true end
  end
  return false
end

-- Wheel carries no coordinates; children self-check hover. Optional per child.
function Container:wheelmoved(dx, dy)
  for _, c in ipairs(self.children) do
    if c.wheelmoved and c:wheelmoved(dx, dy) then return true end
  end
  return false
end

function Container:textinput(text)
  for _, c in ipairs(self.children) do
    if c:textinput(text) then return true end
  end
  return false
end

return Container
