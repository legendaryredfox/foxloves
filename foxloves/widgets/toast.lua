-- ToastHost widget: transient, stacked notification messages.
--
-- ToastHost.new{
--   corner   = "br",   -- tl | tr | bl | br  (which corner toasts stack in)
--   gap      = 8,      -- pixels between stacked toasts
--   margin   = 12,     -- pixels from the screen edges
--   width    = 260,    -- toast box width
--   duration = 3,      -- default seconds a toast stays before fading out
--   max      = 4,      -- most toasts kept at once (oldest dropped past this)
--   theme    = <theme table>,
-- }
--
-- Add it to a fox.Root (root:add). Push messages with:
--   host:show("Saved.", { kind = "success", duration = 2 })
-- kind is info | success | warning | error and colors the left stripe; it reads
-- theme.color[kind] and falls back to accent. show() returns a handle you can
-- pass to host:dismiss(handle) to fade a toast out early. The host never
-- captures input, so add it after the widgets it floats over.

local defaultTheme = require("foxloves.theme")

local FADE_SPEED = 8  -- alpha units per second toward the target
local STRIPE = 4      -- width of the left accent stripe

local ToastHost = {}
ToastHost.__index = ToastHost

function ToastHost.new(opts)
  opts = opts or {}
  local self = setmetatable({}, ToastHost)
  self.corner = opts.corner or "br"
  self.gap = opts.gap or 8
  self.margin = opts.margin or 12
  self.width = opts.width or 260
  self.duration = opts.duration or 3
  self.max = opts.max or 4
  self.theme = opts.theme or defaultTheme
  self.toasts = {}  -- newest last
  return self
end

-- Queue a toast. Returns a handle usable with :dismiss.
function ToastHost:show(text, opts)
  opts = opts or {}
  local toast = {
    text = text or "",
    kind = opts.kind or "info",
    duration = opts.duration or self.duration,
    age = 0,
    alpha = 0,
    dismissing = false,
  }
  self.toasts[#self.toasts + 1] = toast
  -- Drop the oldest once we exceed max so the stack stays bounded.
  while #self.toasts > self.max do table.remove(self.toasts, 1) end
  return toast
end

-- Start fading a toast out now (no-op if it already went away).
function ToastHost:dismiss(handle)
  if handle then handle.dismissing = true end
end

function ToastHost:clear()
  self.toasts = {}
end

function ToastHost:update(dt)
  for i = #self.toasts, 1, -1 do
    local toast = self.toasts[i]
    toast.age = toast.age + dt
    local leaving = toast.dismissing or toast.age >= toast.duration
    local target = leaving and 0 or 1
    if toast.alpha < target then
      toast.alpha = math.min(target, toast.alpha + FADE_SPEED * dt)
    elseif toast.alpha > target then
      toast.alpha = math.max(target, toast.alpha - FADE_SPEED * dt)
    end
    if leaving and toast.alpha <= 0 then table.remove(self.toasts, i) end
  end
end

-- Wrapped text width available inside a toast box.
function ToastHost:_textWidth(font)
  return self.width - STRIPE - self.theme.padding * 3
end

function ToastHost:_boxHeight(toast, font)
  local pad = self.theme.padding
  local _, lines = font:getWrap(toast.text, self:_textWidth(font))
  return #lines * font:getHeight() + pad * 2
end

function ToastHost:draw()
  if #self.toasts == 0 then return end
  local t = self.theme
  local r, g, b, a = love.graphics.getColor()
  local font = defaultTheme.getFont(t)
  love.graphics.setFont(font)

  local screenW, screenH = love.graphics.getDimensions()
  local top = self.corner == "tl" or self.corner == "tr"
  local left = self.corner == "tl" or self.corner == "bl"
  -- Newest toast sits nearest the corner; walk from the last one outward.
  local edge = top and self.margin or (screenH - self.margin)
  local pad = t.padding

  for i = #self.toasts, 1, -1 do
    local toast = self.toasts[i]
    local boxH = self:_boxHeight(toast, font)
    local by = top and edge or (edge - boxH)
    local bx = left and self.margin or (screenW - self.margin - self.width)
    local al = toast.alpha
    local function setColor(c)
      love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * al)
    end

    setColor(t.color.fg)
    love.graphics.rectangle("fill", bx, by, self.width, boxH, t.radius, t.radius)
    setColor(t.color[toast.kind] or t.color.accent)
    love.graphics.rectangle("fill", bx, by, STRIPE, boxH)
    setColor(t.color.border)
    love.graphics.rectangle("line", bx, by, self.width, boxH, t.radius, t.radius)
    setColor(t.color.text)
    love.graphics.printf(toast.text, bx + STRIPE + pad, by + pad,
                         self:_textWidth(font), "left")

    -- Advance the stacking edge past this toast (plus the gap).
    if top then edge = edge + boxH + self.gap
    else edge = edge - boxH - self.gap end
  end

  love.graphics.setColor(r, g, b, a)
end

-- Non-blocking: never consumes input.
function ToastHost:mousepressed(px, py, btn) return false end
function ToastHost:mousereleased(px, py, btn) return false end
function ToastHost:keypressed(key) return false end
function ToastHost:textinput(text) return false end

return ToastHost
