# Contributing to foxloves

Thanks for working on foxloves. This guide covers the widget contract, coding
conventions, testing, and the git workflow for this repository.

## Widget contract

Every widget is a module returning a factory `Widget.new(opts)`. All widgets
follow the same lifecycle so the host (or `fox.Root`) can drive them uniformly:

```lua
widget:update(dt)                 -- per-frame logic
widget:draw()                     -- render with love.graphics
widget:mousepressed(x, y, btn)    -- return true if consumed
widget:mousereleased(x, y, btn)
widget:keypressed(key)
widget:textinput(text)
```

Rules:

1. A widget never calls `love.graphics.setColor` without restoring prior state,
   and reads all colors/metrics from the theme, not hardcoded literals.
2. Widgets hold their own state; no globals.
3. Input handlers return `true` when they consume the event.
4. Callbacks (`onClick`, `onChange`, …) come from the options table and are
   optional.
5. Document the public API with a short comment block above `new`.

Overlays and containers are coordinated by `fox.Root`; see [USAGE.md](USAGE.md).
The per-widget contract above is stable — new widgets must fit it rather than
add new lifecycle methods.

## Coding conventions

- Local module pattern: `local M = {}` … `return M`.
- 2-space indent, no tabs.
- Descriptive names; no single-letter locals except loop indices and
  coordinates (`x`, `y`).
- Keep each widget file under ~200 lines; extract shared helpers to
  `foxloves/util.lua` (or `container.lua`) when logic repeats.
- No print debugging left in committed code.

## Testing

The suite mocks the LÖVE API and runs headless:

```
luajit tests/run.lua
```

- Add a test block per new widget in `tests/run.lua`: construct, mutate state,
  assert callbacks fire, assert input handlers consume/ignore correctly, and a
  draw smoke test (no error).
- If a widget uses a LÖVE call not yet stubbed, add a no-op to
  `tests/love_stub.lua`.
- Update `main.lua` to show any new widget so it can be exercised with `love .`.

## Git workflow

### Multiple GitHub accounts on one machine

This repo is developed under a dedicated account. SSH host aliases keep it
separate from any other account on the machine (`~/.ssh/config`):

```
Host github-redfox
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_legendaryredfox
  IdentitiesOnly yes
```

Use the alias in the remote URL so the correct key is used:

```
git remote add origin git@github-redfox:legendaryredfox/foxloves.git
```

Pin the author identity locally (so it overrides any global identity):

```
git config user.name  "Legendary Redfox"
git config user.email "legendaryredfox.dev@gmail.com"
```

Verify before pushing:

```
git log -1 --format='%an <%ae>'      # -> Legendary Redfox <...>
ssh -T git@github-redfox             # -> Hi legendaryredfox! ...
```

### Commit style

- Conventional prefixes: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`.
- Subject in the imperative, ≤ 50 characters; add a body when the "why" is not
  obvious from the diff.

### Rules for AI agents

See [AGENTS.md](AGENTS.md). In short: AI agents must never author commits under
an AI name and must never push upstream — a human owns commits and pushes.
