# Tier 2 — Overlay + Container Subsystem — Design

Date: 2026-07-10
Project: foxloves (LÖVE UI design system)
Depends on: Tier 1 widgets (2026-07-10-tier1-widgets-design.md)

## Goal

Add the coordination layer that Tier 2 widgets need — z-order, input capture,
container coordinate spaces, focus — then build the widgets on top:
Panel, Modal, Dropdown, Tooltip, Tabs, ListBox.

The existing per-widget contract is unchanged. No new lifecycle methods are
added (decision (a)). Root and containers do all the new coordination.

## 1. fox.Root — the manager

The host stops looping a flat list and forwards raw LÖVE events to one Root.

```lua
function love.load()
  ui = fox.Root.new()
  ui:add(fox.Button.new{ ... })      -- base layer, ordered
end
function love.update(dt)             ui:update(dt) end
function love.draw()                 ui:draw() end
function love.mousepressed(x,y,b)    ui:mousepressed(x,y,b) end
function love.mousereleased(x,y,b)   ui:mousereleased(x,y,b) end
function love.keypressed(key)        ui:keypressed(key) end
function love.textinput(t)           ui:textinput(t) end
```

State:
- `base` — ordered array of top-level widgets (`root:add(w)`, `root:remove(w)`).
- `overlays` — LIFO stack of active overlay descriptors `{ widget, modal }`.
- `focused` — widget that receives keyboard, or nil.

### Input routing
- `mousepressed`: try overlays top-down. If an overlay consumes, done. If the
  top overlay is `modal`, it captures — base is never tried even on a miss
  (a click on the scrim is swallowed). Non-modal overlay + press outside its
  widget bounds => Root closes that overlay (dropdown/tooltip dismissal), and
  the press then continues to the layer below. Otherwise route to base list,
  first-consume-wins (Tier 1 semantics preserved).
- `mousereleased`: broadcast to the active layer (overlay subtree if modal,
  else base + overlays), matching Tier 1 (release is not consume-gated).
- Focus: after a consuming press, Root records the consumer as `focused`
  (a widget opts in by returning true from mousepressed). A press that hits
  nothing clears focus.
- `keypressed` / `textinput`: sent to `focused` first; if unconsumed and no
  modal is active, broadcast to the active layer. `Esc` with an open overlay is
  handled by Root (closes the top overlay) before broadcasting.

### Draw order
Base first (in add order), then overlays bottom-to-top. Correct z-order:
later/overlay content paints over earlier content.

### Overlay API
- `root:openOverlay(widget, { modal = bool })` — push.
- `root:closeOverlay(widget?)` — pop the given overlay or the top one.
- Widgets never touch the stack directly; they call callbacks the host wires,
  or receive a `root` reference on open (Modal/Dropdown get `self.root`).

## 2. Containers (Panel, Tabs) — relative child coords

Shared logic in `foxloves/container.lua` (a helper, not a widget):

- Holds `children`, a content origin `(ox, oy)` = container position + padding.
- `draw`: `love.graphics.translate(ox, oy)` (via push/pop), draw children in
  local space, then restore.
- Input: Root passes world coords; the container subtracts `(ox, oy)` and
  forwards local coords to children. Nesting composes (each level offsets).
- `container:add(child)` / `:remove(child)`.

### Panel
`Panel.new{ x, y, w, h, title = nil, theme }` — frame + optional title bar +
`panel:add(child)`. Children positioned relative to the content area (inside
padding, below the title bar when present).

## 3. Overlays

### Modal / Dialog
`Modal.new{ w, h, title, message?, buttons = {{label, onClick}}, theme }`
- Opened via `root:openOverlay(modal, { modal = true })`.
- Draws a full-screen scrim (dim), then a centered panel with title, message,
  and a row of Buttons.
- Traps all input. `Esc` and any button (after its onClick) call
  `root:closeOverlay(self)`.

### Dropdown / Select
`Dropdown.new{ x, y, w, options, selected?, onChange, theme }`
- Closed state draws like a button showing the current option + caret.
- Click opens a popup list as a non-modal overlay anchored below the trigger.
- Press outside the popup closes it (Root dismissal). Selecting a row fires
  `onChange(index)` and closes. `dropdown.selected` readable/writable.

### Tooltip
`Tooltip.new{ target = {x,y,w,h}, text, delay = 0.6, theme }`
- Polls the mouse in `update` (like Slider). When hovered over `target` for
  `delay` seconds, shows a floating box near the cursor; hides on leave.
- Non-blocking, never captures input, drawn above siblings via the overlay
  layer (auto-managed: Tooltip asks Root to draw it on top while visible).

## 4. Tabs, ListBox

### Tabs
`Tabs.new{ x, y, w, h, tabs = {{label, panel}}, selected = 1, onChange, theme }`
- Header row of clickable labels; body shows the selected tab's Panel
  (a Container). Switching updates `selected`, fires `onChange(index)`.

### ListBox
`ListBox.new{ x, y, w, h, items, selected?, onChange, theme }`
- Scrollable, selectable rows. Wheel / drag scroll; click selects a row.
- Clips rows to bounds (love.graphics.setScissor). Fires `onChange(index)`.

## 5. Contract

Unchanged. No new methods (decision (a)). Tooltip hover and dropdown
outside-close are handled by Root + update polling, not new callbacks.

## 6. Build order (stages)

1. `Root` — base layer, overlay stack, routing, focus. Foundation.
2. `container.lua` + `Panel`.
3. `Modal`, `Dropdown`, `Tooltip`.
4. `Tabs`, `ListBox`.

## 7. Testing

- Extend `tests/love_stub.lua` only as needed: `push`/`pop`/`translate`/
  `setScissor`/`getWidth`/`getHeight` no-ops; `love.graphics.getDimensions`
  for scrim sizing.
- Root: modal traps (base not reached), non-modal outside-press closes +
  falls through, focus set/clear, keypressed routed to focused, Esc closes top.
- Panel: click at world coords reaches the correct child in local coords;
  nested panel composes offsets.
- Modal/Dropdown/Tooltip/Tabs/ListBox: open/close, selection callbacks,
  scroll clamp (ListBox), tab switch.

## 8. Demo / docs

- `main.lua`: add a Panel grouping widgets, a Dropdown, a Modal trigger, a
  Tooltip, and a Tabs example, driven through `fox.Root`.
- `USAGE.md`: document Root + the six widgets; move them out of "Planned"
  (list becomes empty / "future ideas").
- `init.lua`: expose `fox.Root`, `fox.Panel`, `fox.Modal`, `fox.Dropdown`,
  `fox.Tooltip`, `fox.Tabs`, `fox.ListBox`.
