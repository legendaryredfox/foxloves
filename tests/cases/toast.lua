local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("ToastHost")
  local host = fox.ToastHost.new{ duration = 1, max = 3 }
  check("starts empty", #host.toasts == 0)

  local handle = host:show("Saved.", { kind = "success" })
  check("show queues a toast", #host.toasts == 1)
  check("toast keeps text", host.toasts[1].text == "Saved.")
  check("toast keeps kind", host.toasts[1].kind == "success")
  check("show returns handle", handle == host.toasts[1])

  -- fade-in raises alpha toward 1
  host:update(0.1)
  check("alpha rises on update", host.toasts[1].alpha > 0)

  -- never captures input
  check("mousepressed passthrough", host:mousepressed(0, 0, 1) == false)
  check("keypressed passthrough", host:keypressed("a") == false)
end

do
  h.section("ToastHost expiry and cap")
  local host = fox.ToastHost.new{ duration = 0.5, max = 2 }
  host:show("one")
  host:show("two")
  host:show("three")
  check("cap drops oldest", #host.toasts == 2)
  check("oldest kept is 'two'", host.toasts[1].text == "two")

  -- run past the duration plus the fade-out; toast should be removed
  for _ = 1, 200 do host:update(0.016) end
  check("expired toasts removed", #host.toasts == 0)
end

do
  h.section("ToastHost dismiss")
  local host = fox.ToastHost.new{ duration = 10 }
  local handle = host:show("bye")
  for _ = 1, 5 do host:update(0.016) end     -- let it fade in
  check("faded in", host.toasts[1].alpha > 0)
  host:dismiss(handle)
  for _ = 1, 200 do host:update(0.016) end    -- fade out well before duration
  check("dismiss removes early", #host.toasts == 0)
end

do
  h.section("ToastHost draw")
  for _, corner in ipairs({ "tl", "tr", "bl", "br" }) do
    local host = fox.ToastHost.new{ corner = corner }
    host:show("A short message")
    host:show("Another, somewhat longer message that will wrap across lines.",
              { kind = "error" })
    host:update(0.1)
    local ok = pcall(function() host:draw() end)
    check("draw no error (" .. corner .. ")", ok)
  end
end
