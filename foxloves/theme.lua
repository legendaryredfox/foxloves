-- Default theme for foxloves widgets.
-- Widgets read all colors/metrics from a theme table; override by passing
-- `theme` in a widget's options.

local M = {
  color = {
    bg       = {0.16, 0.17, 0.20, 1.0},
    fg       = {0.22, 0.24, 0.28, 1.0},
    accent   = {0.90, 0.55, 0.25, 1.0}, -- fox orange
    border   = {0.35, 0.37, 0.42, 1.0},
    hover    = {0.28, 0.30, 0.35, 1.0}, -- distinct from fg; used for hover fills
    focus    = {0.98, 0.72, 0.40, 1.0}, -- keyboard focus ring (lighter accent)
    disabled = {0.30, 0.31, 0.34, 1.0},
    text     = {0.94, 0.95, 0.97, 1.0},
    textMuted= {0.55, 0.57, 0.62, 1.0},
    success  = {0.35, 0.72, 0.42, 1.0}, -- toast/status accent
    warning  = {0.92, 0.72, 0.25, 1.0},
    error    = {0.86, 0.32, 0.30, 1.0},
  },
  radius  = 4,
  padding = 8,
  font    = nil, -- filled with love.graphics.getFont() on first use
}

-- Returns the theme's font, defaulting to LÖVE's current font.
function M.getFont(theme)
  return (theme and theme.font) or M.font or love.graphics.getFont()
end

return M
