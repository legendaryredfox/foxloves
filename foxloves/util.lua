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

return M
