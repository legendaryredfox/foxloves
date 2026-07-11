# foxloves — Usage Guide

**foxloves** is a small, dependency-free UI design system (widget library) for
[LÖVE (love2d)](https://love2d.org/). It gives your game or tool a themeable set
of composable widgets that all share one input and drawing lifecycle.

## Requirements

- LÖVE 11.x
- Lua 5.1 / LuaJIT semantics (what LÖVE ships)

## Install

Copy the `foxloves/` folder into your project so it sits on the require path.
Then:

```lua
local fox = require("foxloves")
```

`require("foxloves")` returns a table exposing every widget plus the manager,
active theme, and shared helpers. Controls: `fox.Button`, `fox.Textbox`,
`fox.Label`, `fox.Badge`, `fox.Avatar`, `fox.Divider`, `fox.ProgressBar`, `fox.Checkbox`, `fox.Toggle`,
`fox.RadioGroup`, `fox.Slider`, `fox.Stepper`, `fox.IconButton`. Containers and
overlays: `fox.Root`, `fox.Panel`, `fox.Modal`, `fox.Dropdown`, `fox.Tooltip`,
`fox.Tabs`, `fox.ListBox`. Plus `fox.theme` and `fox.util`.

## Quick start

Create widgets in `love.load`, then forward LÖVE's callbacks to them.

```lua
local fox = require("foxloves")
local widgets = {}

function love.load()
  local name = fox.Textbox.new{
    x = 40, y = 60, w = 240, h = 34,
    placeholder = "your name",
  }
  local go = fox.Button.new{
    x = 300, y = 60, w = 120, h = 34,
    label = "Greet",
    onClick = function() print("Hello, " .. name.value) end,
  }
  widgets = { name, go }
end

function love.update(dt)
  for _, w in ipairs(widgets) do w:update(dt) end
end

function love.draw()
  for _, w in ipairs(widgets) do w:draw() end
end

function love.mousepressed(x, y, b)
  for _, w in ipairs(widgets) do
    if w:mousepressed(x, y, b) then break end
  end
end

function love.mousereleased(x, y, b)
  for _, w in ipairs(widgets) do w:mousereleased(x, y, b) end
end

function love.keypressed(key)
  for _, w in ipairs(widgets) do
    if w:keypressed(key) then return end
  end
end

function love.textinput(t)
  for _, w in ipairs(widgets) do
    if w:textinput(t) then break end
  end
end
```

## Widget lifecycle

Every widget follows the same contract so the host can drive them in a loop:

- `widget:update(dt)` — per-frame logic (hover, caret blink).
- `widget:draw()` — render with `love.graphics`; restores prior color state.
- `widget:mousepressed(x, y, btn)` — returns `true` if it consumed the event.
- `widget:mousereleased(x, y, btn)`
- `widget:keypressed(key)`
- `widget:textinput(text)`
- `widget:wheelmoved(dx, dy)` — *optional*; scrollable widgets (ListBox, Slider,
  Dropdown popup) implement it. Forward `love.wheelmoved` to your Root or list.

Input handlers return `true` when they consume the event, so the caller can
stop propagation (see the `break` / `return` in the callbacks above).

### Keyboard focus

Interactive widgets set `widget.focusable = true`. When driven by a `fox.Root`,
**Tab** / **Shift-Tab** move focus between focusable widgets, a focus ring is
drawn on the focused one, and **Space/Enter** (or arrows, per widget) activate it
without the mouse. Focus is also set by clicking. See
[Managing widgets with fox.Root](#managing-widgets-with-foxroot).

## Button

```lua
fox.Button.new{
  x, y, w, h,          -- bounds
  label = "OK",        -- centered text
  onClick = function(self) end,
  disabled = false,
  theme = <theme>,     -- optional
}
```

States: normal, hovered, pressed, disabled. Fires `onClick` on mouse release
inside bounds when the press also began inside bounds. When focused (via Tab in a
Root), **Space/Enter** activate it.

## Textbox

```lua
fox.Textbox.new{
  x, y, w, h,
  value = "",
  placeholder = "Type here...",
  onChange = function(newValue) end,
  maxLength = nil,     -- optional cap
  theme = <theme>,
}
```

Single-line input with a blinking caret. Click to focus (the caret lands at the
clicked character), click elsewhere to blur. Supports text entry, backspace,
caret movement with left/right, and **Home/End**. Text longer than the box
scrolls horizontally and is clipped so the caret stays visible. Fires
`onChange(newValue)` on every edit. Read the current text via `textbox.value`.

Note: the caret is byte-indexed, so non-ASCII (multibyte UTF-8) input is not
yet handled correctly.

## Label

```lua
fox.Label.new{
  x, y,
  w = nil,             -- optional; enables alignment (uses printf)
  text = "",
  align = "left",      -- "left" | "center" | "right" (needs w)
  color = nil,         -- table; overrides theme color
  muted = false,       -- shortcut for theme.color.textMuted
  theme = <theme>,
}
```

Static text. With `w` set it draws via `printf` (wraps at `w`, honors `align`);
without `w` it draws a single line via `print`. `text` is mutable at runtime
(`label.text = "..."` or `label:setText(s)`). Non-interactive.

## Badge

```lua
fox.Badge.new{
  x, y,
  text = "",
  color = nil,          -- fill override (table); default theme.color.accent
  textColor = nil,      -- label color override; default theme.color.bg
  removable = false,    -- draw a × hitbox; fires onRemove when clicked (chip)
  onRemove = function(self) end,
  theme = <theme>,
}
```

A small pill-shaped label for counts or status. Self-sizes to its text —
`self.w`/`self.h` are computed on construction and `badge:measure()` returns
`w, h` for layout containers. `text` is mutable via `badge:setText(s)` (re-
measures). Inert unless `removable`, in which case clicking the × fires
`onRemove` and consumes the event; the rest of the badge stays inert.

## Avatar

```lua
fox.Avatar.new{
  x, y,
  size = 40,            -- square; w = h = size
  image = nil,          -- love Image; cover-scaled and cropped to the frame
  name = nil,           -- derives fallback initials ("Red Fox" -> "RF")
  initials = nil,       -- explicit override; wins over name
  shape = "circle",     -- "circle" | "rounded"
  color = nil,          -- fallback fill when there is no image; default accent
  textColor = nil,      -- initials color; default theme.color.bg
  theme = <theme>,
}
```

A framed image. With an `image` it is cover-scaled and cropped to the frame
(circle clip via stencil, rounded via scissor); without one it fills the shape
and centers initials derived from `name` (or an explicit `initials`). Self-sizes
to `size` — `self.w`/`self.h` and `avatar:measure()` return `size, size`.
Non-interactive.

## Divider

```lua
fox.Divider.new{ x, y, length = 100, vertical = false, thickness = 1, theme }
```

A separator line in `theme.color.border`. Non-interactive.

## ProgressBar

```lua
fox.ProgressBar.new{ x, y, w, h, value = 0, min = 0, max = 1, theme }
```

Read-only fill sized to `clamp((value - min) / (max - min), 0, 1)`. Set
`bar.value` to update. Non-interactive.

## Checkbox

```lua
fox.Checkbox.new{
  x, y, size = 20, label = nil, checked = false,
  onChange = function(checked) end, disabled = false, theme,
}
```

Boolean toggle with a check mark and optional label. Toggles on release inside
when the press also began inside, or on **Space/Enter** when focused. Fires
`onChange(checked)`.

## Toggle

```lua
fox.Toggle.new{
  x, y, w = 44, h = 24, on = false,
  onChange = function(on) end, disabled = false, theme,
}
```

Sliding on/off switch. `update(dt)` animates the knob. Toggles on click or, when
focused, on **Space/Enter**. Fires `onChange(on)`.

## RadioGroup

```lua
fox.RadioGroup.new{
  x, y, options = { "One", "Two" }, selected = 1, spacing = 28,
  onChange = function(index) end, disabled = false, theme,
}
```

One widget owning a vertical stack of mutually exclusive options. Selecting a
row clears the others; the hovered row is highlighted. When focused, **Up/Left**
and **Down/Right** move the selection (wrapping around), **Home/End** jump to the
first/last. Read/write `group.selected`. Fires `onChange(index)`.

## Slider

```lua
fox.Slider.new{
  x, y, w, h = 20, value = 0, min = 0, max = 1, step = nil,
  onChange = function(value) end, disabled = false, theme,
}
```

Drag the handle to pick a value. Pressing the track jumps the value to the
cursor; while dragging, `update` follows the cursor as long as the left button
is held (no `mousemoved` callback is needed). Snaps to `step` when set. When
focused, **arrows** nudge by one step and **Home/End** jump to the ends; the
scroll wheel over the track also nudges. Fires `onChange(value)`.

## Stepper

```lua
fox.Stepper.new{
  x, y, w, h = 32, value = 0, min = nil, max = nil, step = 1,
  onChange = function(value) end, disabled = false, theme,
}
```

Numeric value with − / + buttons and a printed readout (the readout is not
text-editable). Clamps to `min`/`max` when set. Holding a button auto-repeats
after a short delay; when focused, **Up/Right** and **Down/Left** step the value.
Call `stepper:setDisabled(bool)` to enable/disable at runtime (it propagates to
the − / + buttons). Fires `onChange(value)`.

## IconButton

```lua
fox.IconButton.new{
  x, y, w, h, image = <love Image>,
  onClick = function(self) end, disabled = false, theme,
}
```

A square button drawing `image` (scaled to fit, centered) instead of a label.
Same states, click, and **Space/Enter** activation as Button.

## Managing widgets with fox.Root

For simple screens you can drive a flat list of widgets yourself (see Quick
start). Once you need overlays (dropdowns, dialogs, tooltips) or containers,
use `fox.Root` — it owns the widgets and handles z-order, input capture, and
keyboard focus for you.

```lua
function love.load()
  ui = fox.Root.new()
  ui:add(fox.Button.new{ ... })          -- base layer, drawn in add order
end

function love.update(dt)  ui:update(dt) end
function love.draw()      ui:draw() end
function love.mousepressed(x, y, b)  ui:mousepressed(x, y, b) end
function love.mousereleased(x, y, b) ui:mousereleased(x, y, b) end
function love.wheelmoved(dx, dy)     ui:wheelmoved(dx, dy) end
function love.textinput(t)           ui:textinput(t) end
function love.keypressed(key)
  if ui:keypressed(key) then return end
  if key == "escape" then love.event.quit() end
end
```

- `ui:add(widget)` / `ui:remove(widget)` — manage the base layer.
- `ui:openOverlay(widget, { modal = bool })` / `ui:closeOverlay(widget?)` —
  push/pop overlays. A modal overlay traps all input (including keys, so a
  background-focused widget never sees them); a non-modal one is dismissed when a
  press lands outside it. `Esc` closes the top overlay.
- `ui:wheelmoved(dx, dy)` routes the scroll wheel to overlays then the base
  layer (first to consume wins).
- **Tab** / **Shift-Tab** move keyboard focus between focusable base widgets;
  `ui:setFocus(widget)` sets it programmatically.
- Widgets added to a Root get a `widget.root` backref (used for the focus ring,
  keyboard activation, and — for Dropdown — opening its popup).

## Panel

```lua
local panel = fox.Panel.new{ x, y, w, h, title = nil, theme }
panel:add(fox.Button.new{ x = 10, y = 10, ... })   -- coords relative to panel
```

A bordered container. Children are positioned relative to the panel's content
area (inside the padding, below the title bar), so moving the panel moves its
children. Panels nest. Empty panel areas do not consume clicks.

## Modal

```lua
local dlg = fox.Modal.new{
  w = 320, h = 180, title = "Confirm", message = "Sure?",
  buttons = {
    { label = "Cancel" },
    { label = "OK", onClick = function() ... end },
  },
}
ui:openOverlay(dlg, { modal = true })
```

Blocking dialog: dims the screen, centers a panel with title/message/buttons,
and traps input. Each button runs its `onClick` then closes the dialog; `Esc`
also closes it. Focus is trapped over the buttons: **Tab/Shift-Tab** (or
**Left/Right**) cycle them, **Enter** activates the default (primary, rightmost)
button, and **Space** the focused one.

## Dropdown

```lua
fox.Dropdown.new{
  x, y, w, h = 32, options = { "One", "Two" }, selected = 1,
  onChange = function(index) end, theme,
}
```

Shows the current option and a caret; clicking (or **Space/Enter/Down** when
focused) opens a popup list. The popup anchors below the trigger, flips above
when it would run off the bottom of the screen, and caps its height with a
scroll wheel when it fits neither side; the current selection is highlighted
distinctly from the hovered row. Selecting a row fires `onChange(index)` and
closes; clicking outside dismisses. Must be added to a `fox.Root`.
`dropdown.selected` is readable/writable.

## Tooltip

```lua
fox.Tooltip.new{ target = { x, y, w, h }, text = "hint", delay = 0.6,
  maxWidth = nil, theme }
```

Shows a floating box near the cursor after hovering `target` for `delay`
seconds; it fades in and out and is clamped to stay on screen. Set `maxWidth` to
wrap long text over multiple lines. Non-blocking. Add it after the widgets it
annotates so it draws on top.

## Tabs

```lua
fox.Tabs.new{
  x, y, w, headerH = 32,
  tabs = { { label = "One", panel = <widget> }, ... },
  selected = 1, onChange = function(index) end, theme,
}
```

Header row of clickable labels; the selected tab's `panel` (usually a
`fox.Panel`) is drawn below and receives input. Position each panel below the
header yourself. Hovered headers are highlighted; when focused, **Left/Right**
switch tabs and **Home/End** jump to the first/last (the active panel gets first
refusal on keys, so a focused child keeps its arrows). Switching fires
`onChange(index)`.

## ListBox

```lua
fox.ListBox.new{
  x, y, w, h, items = { ... }, selected = nil, rowH = 24,
  onChange = function(index) end, theme,
}
```

Scrollable, selectable rows, clipped to the box. Click a row to select it; drag
inside the box or use the scroll wheel to scroll; the hovered row is highlighted.
When focused, **Up/Down** move the selection (scrolling it into view),
**Home/End** jump to the ends, **PageUp/PageDown** page by the visible row count,
and **Enter** re-confirms. Fires `onChange(index)`. `listbox.selected` is
readable.

## Theming

Widgets read all colors and metrics from a theme table and fall back to the
default in `foxloves/theme.lua`. Override globally by editing that file, or
per-widget by passing `theme` in the options. Minimum keys:

```lua
{
  color = {
    bg, fg, accent, border, disabled, text, textMuted,
    hover,   -- fill for hovered controls / rows (distinct from fg)
    focus,   -- keyboard focus ring (defaults to accent if omitted)
  },
  radius = 4,
  padding = 8,
  font = <love Font>,   -- optional; defaults to current font
}
```

## Running the demo

From the project root:

```
love .
```

Type a name, click **Greet**. `Esc` quits.

## Running the tests

The suite mocks the LÖVE API and runs headless — no window required:

```
luajit tests/run.lua
```

Exit code is non-zero if any check fails, so it drops straight into CI. The
suite is split into one file per widget/topic under `tests/cases/`, sharing
`tests/harness.lua`; `tests/run.lua` lists and runs them.

## Future ideas

The core widget set (Tier 1 controls + Tier 2 overlays/containers) is complete.
Possible future additions: text area (multi-line input), context menu, color
picker, tree view, notification/toast. Each would follow the same lifecycle and,
where it floats, ride the `fox.Root` overlay layer.

## Git rules for contributors and AI agents

See `AGENTS.md`. In short: AI agents must never author commits under an AI name
and must never push upstream — the human owns commits and pushes.
