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

do
  h.section("Textbox selection & clipboard")
  local stub = require("tests.love_stub")
  local last
  local tb = fox.Textbox.new{ x = 0, y = 0, w = 400, h = 30,
    value = "hello world", onChange = function(v) last = v end }
  tb:mousepressed(2, 5, 1)          -- focus, caret near 0
  tb.caret, tb.anchor = 0, nil

  -- Shift+Right extends a selection; plain Right collapses to its far edge.
  stub.setKey("lshift", true)
  tb:keypressed("right"); tb:keypressed("right"); tb:keypressed("right")
  check("shift-right selects 3 chars", tb.anchor == 0 and tb.caret == 3)
  check("selected text is 'hel'", tb:_selectedText() == "hel")
  stub.setKey("lshift", false)
  tb:keypressed("right")
  check("plain right collapses to sel end", tb.caret == 3 and tb.anchor == nil)

  -- Ctrl+A selects everything; Ctrl+C copies it.
  stub.setKey("lctrl", true)
  tb:keypressed("a")
  check("ctrl-a selects all", tb.anchor == 0 and tb.caret == #tb.value)
  tb:keypressed("c")
  check("ctrl-c copies selection", love.system.getClipboardText() == "hello world")

  -- Typing over a selection replaces it.
  stub.setKey("lctrl", false)
  tb:textinput("X")
  check("typing replaces selection", tb.value == "X")
  check("onChange saw replacement", last == "X")
  check("caret after inserted char", tb.caret == 1 and tb.anchor == nil)

  -- Paste inserts clipboard text at the caret (over any selection).
  stub.setKey("lctrl", true)
  tb:keypressed("a")                -- select "X"
  tb:keypressed("v")                -- paste "hello world" over it
  check("ctrl-v pastes over selection", tb.value == "hello world")
  stub.setKey("lctrl", false)

  -- Backspace with a selection deletes the range, not one char.
  tb.anchor, tb.caret = 0, 5        -- select "hello"
  tb:keypressed("backspace")
  check("backspace deletes selection", tb.value == " world")
  check("caret at deletion start", tb.caret == 0)

  -- Cut copies then removes the selection.
  tb.anchor, tb.caret = 0, #tb.value
  stub.setKey("lctrl", true)
  tb:keypressed("x")
  check("ctrl-x cuts to clipboard", love.system.getClipboardText() == " world")
  check("ctrl-x empties value", tb.value == "")
  stub.setKey("lctrl", false)

  -- Shift-click extends a selection from the caret.
  local cb = fox.Textbox.new{ x = 0, y = 0, w = 400, h = 30, value = "abcdef" }
  cb:mousepressed(2, 5, 1)          -- caret 0
  stub.setKey("lshift", true)
  cb:mousepressed(2 + 8 + 7 * 3, 5, 1)  -- click near char 3 (pad 8, 7px/char)
  check("shift-click selects to click", cb.anchor == 0 and cb.caret == 3)
  stub.setKey("lshift", false)

  local ok = pcall(function() cb.focused = true; cb:draw() end)
  check("draw with selection no error", ok)
end

do
  h.section("Textbox word motion")
  local stub = require("tests.love_stub")

  -- Ctrl+Left/Right jump by whole words.
  local tb = fox.Textbox.new{ value = "hello world foo" }
  tb.focused = true
  tb.caret = #tb.value
  stub.setKey("lctrl", true)
  tb:keypressed("left")
  check("ctrl+left to start of last word", tb.caret == 12)
  tb:keypressed("left")
  check("ctrl+left to start of middle word", tb.caret == 6)
  tb:keypressed("right")
  check("ctrl+right to end of middle word", tb.caret == 11)

  -- Ctrl+Shift+Left extends a selection over the word.
  tb.caret = #tb.value; tb.anchor = nil
  stub.setKey("lshift", true)
  tb:keypressed("left")
  check("ctrl+shift+left selects word", tb:_hasSelection() and tb:_selectedText() == "foo")
  stub.setKey("lshift", false)

  -- Ctrl+Backspace deletes the word before the caret.
  local changed
  local tb2 = fox.Textbox.new{ value = "hello world", onChange = function(v) changed = v end }
  tb2.focused = true; tb2.caret = #tb2.value
  tb2:keypressed("backspace")
  check("ctrl+backspace deletes prev word", tb2.value == "hello " and tb2.caret == 6)
  check("ctrl+backspace fires onChange", changed == "hello ")

  -- Ctrl+Delete deletes the word after the caret.
  local tb3 = fox.Textbox.new{ value = "hello world" }
  tb3.focused = true; tb3.caret = 0
  tb3:keypressed("delete")
  check("ctrl+delete removes next word", tb3.value == " world" and tb3.caret == 0)

  stub.setKey("lctrl", false)
end
