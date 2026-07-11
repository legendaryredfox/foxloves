# foxloves

A small, dependency-free UI design system (widget library) for
[LÖVE (love2d)](https://love2d.org/), written in Lua. It gives your game or tool
a themeable set of composable widgets that share one input and drawing
lifecycle.

## Features

- **Controls:** Button, Textbox, Label, Badge, Avatar, Divider, ProgressBar,
  Checkbox, Toggle, RadioGroup, Slider, Stepper, IconButton.
- **Containers & overlays:** Panel, Modal, Dropdown, Tooltip, Tabs, ListBox —
  coordinated by `fox.Root` (z-order, input capture, keyboard focus).
- **Themeable:** every widget reads colors and metrics from a shared theme.
- **No dependencies:** pure Lua, LÖVE 11.x.
- **Headless tests:** the suite mocks the LÖVE API and runs without a window.

## Requirements

- LÖVE 11.x
- Lua 5.1 / LuaJIT semantics (what LÖVE ships)

## Install

Copy the `foxloves/` folder into your project so it sits on the require path:

```lua
local fox = require("foxloves")
```

## Quick start

```lua
local fox = require("foxloves")
local ui

function love.load()
  ui = fox.Root.new()
  local name = ui:add(fox.Textbox.new{ x = 40, y = 40, w = 240, h = 34,
    placeholder = "your name" })
  ui:add(fox.Button.new{ x = 296, y = 40, w = 120, h = 34, label = "Greet",
    onClick = function() print("Hello, " .. name.value) end })
end

function love.update(dt)              ui:update(dt) end
function love.draw()                  ui:draw() end
function love.mousepressed(x, y, b)   ui:mousepressed(x, y, b) end
function love.mousereleased(x, y, b)  ui:mousereleased(x, y, b) end
function love.textinput(t)            ui:textinput(t) end
function love.keypressed(key)
  if ui:keypressed(key) then return end
  if key == "escape" then love.event.quit() end
end
```

See [USAGE.md](USAGE.md) for the full widget reference.

## Running the demo

From the project root:

```
love .
```

## Running the tests

Headless, no window required:

```
luajit tests/run.lua
```

Exit code is non-zero if any check fails, so it drops straight into CI.

## Documentation

- [USAGE.md](USAGE.md) — full widget reference and theming guide.
- [CONTRIBUTING.md](CONTRIBUTING.md) — widget contract, conventions, workflow.
- [AGENTS.md](AGENTS.md) — instructions for AI agents working on the project.

## License

See repository for license details.
