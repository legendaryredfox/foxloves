-- Minimal headless stub of the LÖVE API, enough to exercise foxloves widgets
-- without a window. Only the calls widgets actually make are implemented.

local stub = {}

local fakeFont
fakeFont = {
  getHeight = function() return 14 end,
  getWidth  = function(_, s) return #(s or "") * 7 end,
  -- Naive word-wrap at 7px/char, honoring existing newlines. Returns the
  -- widest line width and the list of lines, like love's Font:getWrap.
  getWrap   = function(_, text, limit)
    local lines, width = {}, 0
    for para in (tostring(text) .. "\n"):gmatch("(.-)\n") do
      local cur = ""
      for word in para:gmatch("%S+") do
        local trial = cur == "" and word or (cur .. " " .. word)
        if #trial * 7 > limit and cur ~= "" then
          lines[#lines + 1] = cur; width = math.max(width, #cur * 7); cur = word
        else
          cur = trial
        end
      end
      lines[#lines + 1] = cur; width = math.max(width, #cur * 7)
    end
    return width, lines
  end,
}

local mouse = { x = 0, y = 0, down = {} }
local keys = {}
local clipboard = ""

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
  function G.stencil(fn) if fn then fn() end end
  function G.setStencilTest() end
  function G.getDimensions() return 800, 600 end

  love = {
    graphics = G,
    mouse = {
      getPosition = function() return mouse.x, mouse.y end,
      isDown = function(btn) return mouse.down[btn or 1] == true end,
    },
    keyboard = {
      setKeyRepeat = function() end,
      isDown = function(...)
        for _, k in ipairs({ ... }) do
          if keys[k] then return true end
        end
        return false
      end,
    },
    event = { quit = function() end },
    system = {
      getClipboardText = function() return clipboard end,
      setClipboardText = function(text) clipboard = text or "" end,
    },
  }
end

-- Move the fake cursor (drives hover in update).
stub.setMouse = function(x, y) mouse.x, mouse.y = x, y end

-- Set whether a mouse button is held (drives Slider drag polling in update).
stub.setMouseDown = function(btn, isDown) mouse.down[btn] = isDown end

-- Set whether a key is held (drives Shift-Tab reverse traversal).
stub.setKey = function(key, isDown) keys[key] = isDown end

return stub
