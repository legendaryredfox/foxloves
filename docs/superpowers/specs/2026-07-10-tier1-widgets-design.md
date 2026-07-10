# Tier 1 Widgets — Design

Date: 2026-07-10
Project: foxloves (LÖVE UI design system)

## Goal

Add nine simple widgets that fit the existing widget contract with no
architecture change. Interactive overlays/containers (Dropdown, Modal, Tabs,
Panel, Tooltip, ListBox) are explicitly deferred to a later "Tier 2" spec that
first designs a shared overlay/z-order + container subsystem.

## Existing contract (unchanged)

Every widget module returns a factory `Widget.new(opts)` producing an object with:

```
:update(dt)
:draw()                      -- reads theme, restores prior color state
:mousepressed(x, y, btn)     -- returns true if consumed
:mousereleased(x, y, btn)
:keypressed(key)
:textinput(text)
```

Rules (from AGENTS.md): no globals; read colors/metrics from theme; input
handlers return `true` only when they consume; callbacks optional; file < ~200
lines; 2-space indent.

## Shared helper — `foxloves/util.lua`

Repeated logic extracted per AGENTS.md convention:

```lua
util.contains(px, py, x, y, w, h) -> bool     -- point-in-rect
util.clamp(v, lo, hi) -> number
```

## Widgets

### Label (approach A — no wrap flag)
`Label.new{ x, y, w=nil, text="", align="left", color=nil, muted=false, theme }`
- `w` set → `printf(text, x, y, w, align)`; absent → `print(text, x, y)`.
- Color precedence: `color` table > `muted` (textMuted) > text.
- `label.text` mutable; `:setText(s)` sugar. No input (handlers return false).

### Divider
`Divider.new{ x, y, length, vertical=false, thickness=1, theme }`
- One line in `theme.color.border`. No input.

### ProgressBar
`ProgressBar.new{ x, y, w, h, value=0, min=0, max=1, theme }`
- Read-only. bg track + accent fill = clamp((value-min)/(max-min), 0, 1).
- `bar.value` mutable. No input.

### Checkbox
`Checkbox.new{ x, y, size=20, label=nil, checked=false, onChange, disabled, theme }`
- Box + check glyph when checked + optional label to the right.
- Toggle on mouserelease inside (press-began-inside logic like Button).
- Hit area = box + label span. Fires `onChange(checked)`.

### Toggle / Switch
`Toggle.new{ x, y, w=44, h=24, on=false, onChange, disabled, theme }`
- Rounded track + sliding knob; accent track when on.
- Click toggles. `update(dt)` lerps knob position for animation.
- Fires `onChange(on)`.

### RadioGroup
`RadioGroup.new{ x, y, options={...}, selected=1, spacing=28, onChange, disabled, theme }`
- One widget owns N rows (circle + filled dot + label), vertical stack.
- Click selects one; others clear. Fires `onChange(index)`.
- `group.selected` readable/writable.

### Slider
`Slider.new{ x, y, w, h=20, value=0, min=0, max=1, step=nil, onChange, disabled, theme }`
- Track + draggable handle.
- **Decision:** dragging polls `love.mouse` in `update` (no `mousemoved` added
  to the contract). `mousepressed` on track/handle begins drag and jumps value
  to cursor; `update` follows cursor while `love.mouse.isDown(1)`;
  `mousereleased` ends drag.
- Value maps from cursor X across track, snapped to `step` if set, clamped.
- Fires `onChange(value)` when value changes.

### Stepper
`Stepper.new{ x, y, w, h=32, value=0, min=nil, max=nil, step=1, onChange, disabled, theme }`
- Composes two Buttons (− / +) flanking a printed numeric readout.
- **Decision:** readout is a printed number, not an editable Textbox (keyboard
  entry deferred).
- Clamp to min/max when set. Fires `onChange(value)`.

### IconButton
`IconButton.new{ x, y, w, h, image, onClick, disabled, theme }`
- Button behavior (normal/hover/press/disabled) drawing `image` centered
  instead of a label.
- **Decision:** copy Button internals rather than inherit — keeps files
  independent and under the size limit, per convention.

## Cross-cutting decisions

1. Slider drag polls `love.mouse` in `update` — no contract change.
2. `foxloves/util.lua` holds `contains` + `clamp`.
3. All widgets follow the full lifecycle; irrelevant input handlers return
   `false`; draw restores prior color.

## Testing

- Extend `tests/love_stub.lua` with `love.mouse.isDown` (+ helper to set button
  state) so Slider drag is exercisable headless.
- Add a test block per widget in `tests/run.lua`: construct, mutate state,
  assert callbacks fire, assert input handlers consume/ignore correctly, draw
  smoke test (no error).

## Demo / docs

- `main.lua`: add a live instance of each widget.
- `USAGE.md`: document the nine widgets; move them out of "Planned".
- `foxloves/init.lua`: expose each as `fox.<Widget>`.

## Out of scope (Tier 2)

Panel, Tooltip, Dropdown/Select, Modal/Dialog, Tabs, ListBox — require an
overlay/z-order + container subsystem, designed separately.
