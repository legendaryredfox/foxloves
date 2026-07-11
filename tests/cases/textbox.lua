local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Textbox")
  local last
  local t = fox.Textbox.new{ x = 0, y = 0, w = 200, h = 30,
    onChange = function(v) last = v end }

  check("starts empty", t.value == "")
  check("starts unfocused", t.focused == false)

  -- typing requires focus
  t:textinput("x")
  check("no input while unfocused", t.value == "")

  -- focus by clicking inside
  check("click focuses", t:mousepressed(5, 5, 1) == true)
  check("focused after click", t.focused == true)

  t:textinput("H"); t:textinput("i")
  check("typed text", t.value == "Hi")
  check("onChange fired", last == "Hi")
  check("caret at end", t.caret == 2)

  -- backspace
  t:keypressed("backspace")
  check("backspace removes char", t.value == "H")
  check("caret follows", t.caret == 1)

  -- caret movement + mid-string insert
  t:textinput("ello")            -- "Hello"
  t:keypressed("left"); t:keypressed("left")
  check("caret moved left", t.caret == 3)
  t:textinput("X")               -- "HelXlo"
  check("mid insert", t.value == "HelXlo")

  -- maxLength cap
  local cap = fox.Textbox.new{ maxLength = 3 }
  cap:mousepressed(0, 0, 1)      -- focus (default bounds contain 0,0)
  cap:textinput("a"); cap:textinput("b"); cap:textinput("c"); cap:textinput("d")
  check("maxLength enforced", cap.value == "abc")

  -- blur by clicking outside
  t:mousepressed(999, 999, 1)
  check("click outside blurs", t.focused == false)
  t:textinput("z")
  check("no input after blur", t.value == "HelXlo")

  -- draw smoke test
  local okDraw = pcall(function() t.focused = true; t:draw() end)
  check("draw does not error", okDraw)
end

do
  h.section("Textbox caret/scroll")
  -- Font stub: 7px per char, padding 8. Box x = 0.
  local tb = fox.Textbox.new{ x = 0, y = 0, w = 200, h = 30 }
  tb:mousepressed(5, 5, 1)      -- focus (empty)
  tb:textinput("Hello")         -- caret at 5
  check("caret at end after typing", tb.caret == 5)
  -- Click near character 2: rel = px - pad; caret 2 center = (7 + 14)/2 = 10.5,
  -- caret 3 boundary at (14+21)/2 = 17.5, so px = pad + 14 = 22 lands on caret 2.
  tb:mousepressed(22, 5, 1)
  check("click places caret mid-string", tb.caret == 2)
  -- Click far left snaps caret to 0.
  tb:mousepressed(2, 5, 1)
  check("click far left caret 0", tb.caret == 0)

  -- Horizontal scroll: narrow box, text longer than the view, caret at end.
  local nb = fox.Textbox.new{ x = 0, y = 0, w = 50, h = 30 }
  nb:mousepressed(5, 5, 1)
  nb:textinput("AAAAAAAAAA")     -- 10 chars * 7 = 70px; view = 50 - 16 = 34
  check("scrollX tracks caret past view", nb.scrollX == 70 - 34)
  -- Home resets caret and scroll back to the left.
  nb:keypressed("home")
  check("home scrolls back to start", nb.scrollX == 0)

  local ok = pcall(function() nb.focused = true; nb:draw() end)
  check("draw with scroll no error", ok)
end

do
  h.section("Textbox submit and delete")
  local root = fox.Root.new()
  local submitted
  local tb = root:add(fox.Textbox.new{ x = 0, y = 0, w = 200, h = 30,
    value = "hello", onSubmit = function(v) submitted = v end })
  root:setFocus(tb)
  check("focused via Root", tb.focused == true)

  -- Enter fires onSubmit with the value and blurs (Root focus clears).
  tb:keypressed("return")
  check("onSubmit got value", submitted == "hello")
  check("blurred after Enter", tb.focused == false)
  check("Root focus cleared", root.focused == nil)

  -- forward Delete removes the char at the caret, leaving caret put.
  root:setFocus(tb)
  tb.caret = 0
  tb:keypressed("delete")
  check("delete removed head char", tb.value == "ello")
  check("caret unchanged by delete", tb.caret == 0)

  -- Delete at end of text is a no-op.
  tb.caret = #tb.value
  tb:keypressed("delete")
  check("delete at end no-op", tb.value == "ello")
end
