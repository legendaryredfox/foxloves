-- Shared helpers for foxloves widgets. Kept tiny and dependency-free.

local M = {}

-- Point-in-rectangle test.
function M.contains(px, py, x, y, w, h)
  return px >= x and px <= x + w
     and py >= y and py <= y + h
end

-- Clamp v into [lo, hi].
function M.clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

-- Draw a keyboard focus ring just outside a widget's bounds. Callers restore
-- their own color afterwards (same contract rule as everywhere else).
function M.focusRing(theme, x, y, w, h)
  love.graphics.setColor(theme.color.focus or theme.color.accent)
  love.graphics.rectangle("line", x - 2, y - 2, w + 4, h + 4, theme.radius, theme.radius)
end

-- True when this widget currently holds keyboard focus in its Root. Widgets get
-- their .root set by Root:add / Root:openOverlay; standalone widgets return false.
function M.isFocused(widget)
  return widget.root ~= nil and widget.root.focused == widget
end

return M
