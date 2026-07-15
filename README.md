# foxloves

A small, dependency-free UI design system (widget library) for
[LÖVE (love2d)](https://love2d.org/), written in Lua. It gives your game or tool
a themeable set of composable widgets that share one input and drawing
lifecycle — you wire LÖVE's callbacks into a single `Root` and it dispatches
z-order, input capture, and keyboard focus for you.

**Version 1.0.0** — pure Lua, LÖVE 11.x, 24 widgets, 478 headless tests.

📖 **[Read the manual →](https://romulofer.github.io/foxloves_manual/)**

## Why foxloves

- **One lifecycle.** Every widget speaks the same `update / draw / mousepressed /
  keypressed / textinput` contract. `fox.Root` owns the tree and routes events so
  overlays (modals, dropdowns, tooltips, toasts) capture input correctly.
- **Themeable.** Colors, radius, padding, and font live in a shared theme table.
  Override globally or per-widget by passing `theme = {...}`.
- **No dependencies.** Pure Lua on the semantics LÖVE ships (Lua 5.1 / LuaJIT).
  Drop the folder in and require it.
- **Testable.** The suite mocks the LÖVE API and runs headless — no window, CI
  friendly, non-zero exit on failure.

## Widgets

**Controls** — Button, IconButton, Textbox, NumberField, Label, Badge, Avatar,
Divider, ProgressBar, Spinner, Checkbox, Toggle, RadioGroup, SegmentedControl,
Slider, Stepper.

**Containers & overlays** — Panel, Modal, Dropdown, Tooltip, Tabs, ListBox,
ContextMenu, ToastHost.

Overlays are coordinated by `fox.Root`: z-order stacking, modal input capture,
and keyboard-focus traversal are handled centrally so widgets stay simple.

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

`Root:keypressed` returns `true` when a widget consumed the key (an open modal, a
focused textbox), so guard your own shortcuts behind that check.

## Theming

Every widget reads colors and metrics from a theme table. Override per-widget:

```lua
ui:add(fox.Button.new{ x = 40, y = 40, w = 120, h = 34, label = "Danger",
  theme = { color = { accent = {0.86, 0.32, 0.30, 1.0} } } })
```

The default theme ("fox orange" accent) lives in `foxloves/theme.lua`. See the
[manual](https://romulofer.github.io/foxloves_manual/) for the full color and
metric keys.

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

- 📖 **[Online manual](https://romulofer.github.io/foxloves_manual/)** — full guide,
  widget reference, theming.
- [USAGE.md](USAGE.md) — offline widget reference and theming guide.
- [CONTRIBUTING.md](CONTRIBUTING.md) — widget contract, conventions, workflow.
- [AGENTS.md](AGENTS.md) — instructions for AI agents working on the project.

## License

See repository for license details.
