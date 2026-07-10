# AGENTS.md — foxloves

Instructions for AI agents working on **foxloves**, a design system (UI component library) for [LÖVE (love2d)](https://love2d.org/), written in Lua.

## Project goal

Build a reusable, themeable set of UI widgets for love2d games and tools. Widgets are self-contained, driven by a shared theme, and composable. Start small (textbox, button) and grow.

## Tech

- **Runtime:** LÖVE 11.x (LuaJIT / Lua 5.1 semantics).
- **Language:** Lua. No external dependencies unless approved.
- Run with: `love .` from the project root.

## Directory layout

```
foxloves/
├── AGENTS.md
├── main.lua              -- demo/playground entry point
├── conf.lua              -- LÖVE config (love.conf)
├── foxloves/
│   ├── init.lua          -- module entry: require("foxloves")
│   ├── theme.lua         -- default theme (colors, spacing, fonts)
│   └── widgets/
│       ├── button.lua
│       └── textbox.lua
└── examples/
    └── basic.lua         -- shows each widget
```

`require("foxloves")` returns a table exposing every widget plus the active theme.

## Widget contract

Every widget is a module returning a factory. All widgets follow the same lifecycle so the host game can drive them uniformly.

```lua
local widget = Button.new({
  x = 10, y = 10, w = 120, h = 32,
  -- widget-specific options...
})

widget:update(dt)                 -- per-frame logic
widget:draw()                     -- render with love.graphics
widget:mousepressed(x, y, btn)    -- input hooks (return true if consumed)
widget:mousereleased(x, y, btn)
widget:keypressed(key)
widget:textinput(text)
widget:wheelmoved(dx, dy)         -- optional; scrollable widgets only
```

Optional additive hooks: `widget.focusable = true` (opt into Tab focus, draw a
ring via `fox.util.focusRing` when `fox.util.isFocused(self)`), and
`widget:setFocused(bool)` (Root syncs a widget's own focus flag). Keyboard
activation (Space/Enter, arrows) is gated on focus. See CONTRIBUTING.md.

Rules:

1. A widget **never** calls `love.graphics.setColor` without restoring prior state, and reads all colors/metrics from the theme, not hardcoded literals.
2. Widgets hold their own state; no globals.
3. Input handlers return `true` when they consume the event so the caller can stop propagation.
4. Callbacks (e.g. `onClick`, `onChange`) are passed in via the options table and are optional.
5. Public API is documented with a short comment block above `new`.

## Theme

`theme.lua` centralizes look-and-feel. Widgets accept an optional `theme` in their options and fall back to the default. Minimum theme keys:

```lua
{
  color = { bg, fg, accent, border, hover, focus, disabled, text, textMuted },
  radius = 4,
  padding = 8,
  font = <love Font>,
}
```

`hover` fills hovered controls/rows; `focus` is the keyboard focus ring (falls
back to `accent`).

## First components

### Button

- States: normal, hovered, pressed, disabled.
- Options: `label`, `onClick`, `disabled`.
- Fires `onClick` on mouserelease inside bounds when it was pressed inside bounds.

### Textbox

- Single-line text input with a blinking caret.
- Options: `value`, `placeholder`, `onChange`, `maxLength`.
- Supports: text entry, backspace, caret via left/right, focus/blur on click.
- Fires `onChange(newValue)` when text changes.

## Coding conventions

- Local module pattern: `local M = {}` ... `return M`.
- 2-space indent, no tabs.
- Descriptive names; no single-letter locals except loop indices and coordinates (`x`, `y`).
- Keep each widget file under ~200 lines; extract shared helpers to `foxloves/util.lua` if repeated.
- No print debugging left in committed code.

## Testing / verification

- Update `main.lua` (or `examples/basic.lua`) to render any new widget so it can be exercised by hand with `love .`.
- Manually verify each interactive state before claiming done.

## Git rules (STRICT)

These are hard constraints for AI agents:

1. **AI must never author commits under an AI name.** Commit as the human author only. Do not set `--author` to Claude/AI/bot, do not add AI `Co-Authored-By` trailers, do not sign commits as the assistant. Use the repository's configured user identity.
2. **AI must never push upstream.** No `git push`, no `git push --force`, no publishing to any remote. The human handles all pushes.
3. Only commit when the human explicitly asks. Never commit unprompted.
4. Never rewrite published history or run destructive git operations without explicit approval.
