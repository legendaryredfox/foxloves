-- foxloves demo / playground. Everything is driven through a single fox.Root.
local fox = require("foxloves")

local ui
local status = "interact with the widgets"

-- A tiny solid icon so IconButton has something to draw.
local function makeIcon()
  local size = 16
  local data = love.image.newImageData(size, size)
  data:mapPixel(function(x, y)
    local border = x == 0 or y == 0 or x == size - 1 or y == size - 1
    if border then return 0.94, 0.95, 0.97, 1 end
    return 0.90, 0.55, 0.25, 1
  end)
  return love.graphics.newImage(data)
end

local function setStatus(s) status = s end

function love.load()
  love.keyboard.setKeyRepeat(true)
  ui = fox.Root.new()

  -- Top row: a name field and a greet button. The field supports Shift+arrows/
  -- click to select and Ctrl+A/C/X/V for clipboard.
  local name = fox.Textbox.new{ x = 40, y = 56, w = 240, h = 34,
    placeholder = "your name" }
  ui:add(name)
  ui:add(fox.Button.new{ x = 296, y = 56, w = 120, h = 34, label = "Greet",
    onClick = function()
      setStatus(name.value ~= "" and ("Hello, " .. name.value .. "!")
        or "type a name first")
    end })

  -- A toast host stacks transient messages in the corner; Notify pushes one,
  -- cycling through the four kinds so each stripe color shows.
  local toasts = fox.ToastHost.new{ corner = "br" }
  local kinds = { "info", "success", "warning", "error" }
  local nextKind = 1
  ui:add(fox.Button.new{ x = 40, y = 100, w = 120, h = 34, label = "Notify",
    onClick = function()
      local kind = kinds[nextKind]
      nextKind = nextKind % #kinds + 1
      toasts:show(kind .. " notification", { kind = kind })
      setStatus("toast: " .. kind)
    end })

  -- A dropdown and a button that opens a modal dialog.
  local colors = { "Red", "Green", "Blue" }
  ui:add(fox.Dropdown.new{ x = 440, y = 56, w = 160, h = 34, options = colors,
    onChange = function(i) setStatus("color: " .. colors[i]) end })
  ui:add(fox.Button.new{ x = 440, y = 100, w = 160, h = 34, label = "About…",
    onClick = function()
      ui:openOverlay(fox.Modal.new{ w = 340, h = 170, title = "About foxloves",
        message = "A small, themeable UI widget library for LOVE.",
        buttons = {
          { label = "Close" },
          { label = "OK", onClick = function() setStatus("dialog: OK") end },
        } }, { modal = true })
    end })

  -- Left panel groups Tier 1 controls in its own coordinate space.
  local panel = fox.Panel.new{ x = 40, y = 150, w = 300, h = 328, title = "Controls" }
  panel:add(fox.Checkbox.new{ x = 12, y = 12, label = "enable feature",
    indeterminate = true,
    onChange = function(on) setStatus("checkbox: " .. tostring(on)) end })
  panel:add(fox.Toggle.new{ x = 12, y = 48,
    onChange = function(on) setStatus("toggle: " .. tostring(on)) end })
  panel:add(fox.RadioGroup.new{ x = 12, y = 84, options = { "small", "medium", "large" },
    onChange = function(i) setStatus("radio: " .. i) end })

  local progress = fox.ProgressBar.new{ x = 12, y = 178, w = 260, h = 16, value = 0.3 }
  panel:add(progress)
  panel:add(fox.Slider.new{ x = 12, y = 204, w = 260, value = 0.3,
    onChange = function(v) progress.value = v end })
  -- Vertical slider (right of the panel) also drives the progress bar.
  ui:add(fox.Slider.new{ x = 356, y = 172, w = 24, h = 200, vertical = true,
    value = 0.3, onChange = function(v) progress.value = v end })
  -- Stepper and icon share a row: same height and top, matching bottom margin.
  panel:add(fox.Stepper.new{ x = 12, y = 228, w = 140, h = 34, value = 3, min = 0, max = 9,
    onChange = function(v) setStatus("stepper: " .. v) end })
  panel:add(fox.IconButton.new{ x = 160, y = 228, w = 34, h = 34, image = makeIcon(),
    onClick = function() setStatus("icon clicked") end })
  -- Indeterminate bar: unknown-duration work, a chunk cycles across the track.
  panel:add(fox.ProgressBar.new{ x = 12, y = 270, w = 260, h = 12, indeterminate = true })
  ui:add(panel)

  -- Right column: a scrollable list of rows.
  local items = {}
  for i = 1, 24 do items[i] = "row " .. i end
  ui:add(fox.Label.new{ x = 440, y = 150, text = "ListBox (drag scroll, right-click)", muted = true })
  ui:add(fox.ListBox.new{ x = 440, y = 172, w = 240, h = 196, items = items,
    onChange = function(i) setStatus("selected " .. items[i]) end })

  -- Right-clicking the list opens a context menu over its rect.
  ui:add(fox.ContextMenu.new{ target = { x = 440, y = 172, w = 240, h = 196 },
    items = {
      { label = "Refresh",   onClick = function() setStatus("menu: refresh") end },
      { label = "Duplicate", onClick = function() setStatus("menu: duplicate") end },
      { separator = true },
      { label = "Delete",    onClick = function() setStatus("menu: delete") end },
    } })

  -- Two avatars beside the list label: an image (circle) and an initials
  -- fallback (rounded).
  ui:add(fox.Avatar.new{ x = 700, y = 146, size = 34,
    image = love.graphics.newImage("assets/avatar.jpg") })
  ui:add(fox.Avatar.new{ x = 700, y = 186, size = 34, name = "Red Fox",
    shape = "rounded" })

  -- Labeled divider ("— OR —" style) between the list and the badge row.
  ui:add(fox.Divider.new{ x = 440, y = 382, length = 240, label = "OR" })

  -- Vertically-centered label inside a fixed-height slot next to the badges.
  ui:add(fox.Label.new{ x = 700, y = 396, w = 90, h = 24, text = "centered",
    valign = "middle", align = "center", muted = true })

  -- A row of badges under the list: two static, one removable chip.
  ui:add(fox.Badge.new{ x = 440, y = 404, text = "New" })
  ui:add(fox.Badge.new{ x = 494, y = 404, text = "Beta",
    color = fox.theme.color.border })
  local chip = fox.Badge.new{ x = 560, y = 404, text = "remove me", removable = true }
  chip.onRemove = function(self)
    self.x = -1000 -- drop it off-screen; the demo has no list removal
    setStatus("chip removed")
  end
  ui:add(chip)

  -- A tooltip over the dropdown, drawn on top because it is added last.
  ui:add(fox.Tooltip.new{ target = { x = 440, y = 56, w = 160, h = 34 },
    text = "pick an accent color" })

  -- Added last: floats over every widget and never captures input.
  ui:add(toasts)
end

function love.update(dt) ui:update(dt) end

function love.draw()
  love.graphics.clear(0.10, 0.11, 0.13)
  love.graphics.setColor(fox.theme.color.text)
  love.graphics.print("foxloves", 40, 24)
  love.graphics.setColor(fox.theme.color.textMuted)
  love.graphics.print(status, 40, 492)
  ui:draw()
end

function love.mousepressed(x, y, b)  ui:mousepressed(x, y, b) end
function love.mousereleased(x, y, b) ui:mousereleased(x, y, b) end
function love.mousemoved(x, y, dx, dy) ui:mousemoved(x, y, dx, dy) end
function love.wheelmoved(dx, dy)     ui:wheelmoved(dx, dy) end
function love.textinput(t)           ui:textinput(t) end

function love.keypressed(key)
  if ui:keypressed(key) then return end
  if key == "escape" then love.event.quit() end
end
