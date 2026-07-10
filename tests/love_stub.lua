-- Minimal headless stub of the LÖVE API, enough to exercise foxloves widgets
-- without a window. Only the calls widgets actually make are implemented.

local stub = {}

local fakeFont = {
  getHeight = function() return 14 end,
  getWidth  = function(_, s) return #(s or "") * 7 end,
}

local mouse = { x = 0, y = 0, down = {} }

stub.install = function()
  local G = {}
  function G.getColor() return 1, 1, 1, 1 end
  function G.setColor() end
  function G.rectangle() end
  function G.print() end
  function G.printf() end
  function G.line() end
  function G.circle() end
  function G.polygon() end
  function G.draw() end
  function G.setFont() end
  function G.getFont() return fakeFont end
  function G.clear() end
  function G.push() end
  function G.pop() end
  function G.translate() end
  function G.setScissor() end
  function G.getDimensions() return 800, 600 end

  love = {
    graphics = G,
    mouse = {
      getPosition = function() return mouse.x, mouse.y end,
      isDown = function(btn) return mouse.down[btn or 1] == true end,
    },
    keyboard = {
      setKeyRepeat = function() end,
    },
    event = { quit = function() end },
  }
end

-- Move the fake cursor (drives hover in update).
stub.setMouse = function(x, y) mouse.x, mouse.y = x, y end

-- Set whether a mouse button is held (drives Slider drag polling in update).
stub.setMouseDown = function(btn, isDown) mouse.down[btn] = isDown end

return stub
