local h = require("tests.harness")
local fox, check = h.fox, h.check

do
  h.section("Tabs")
  -- Panels used as tab bodies; they record whether they were drawn/pressed.
  local function fakePanel()
    local p = { pressed = false }
    function p:update() end
    function p:draw() end
    function p:mousepressed() self.pressed = true; return true end
    function p:mousereleased() end
    function p:keypressed() return false end
    function p:textinput() return false end
    return p
  end
  local p1, p2 = fakePanel(), fakePanel()
  local switched
  local tabs = fox.Tabs.new{ x = 0, y = 0, w = 200, headerH = 30,
    tabs = { { label = "A", panel = p1 }, { label = "B", panel = p2 } },
    onChange = function(i) switched = i end }
  check("default selected 1", tabs.selected == 1)
  check("current is panel 1", tabs:current() == p1)

  -- click the second header segment (x 100..200, y 0..30)
  check("header click consumes", tabs:mousepressed(150, 15, 1) == true)
  check("switched to 2", tabs.selected == 2)
  check("onChange got 2", switched == 2)
  check("current is panel 2", tabs:current() == p2)

  -- click below the header routes to the active panel
  tabs:mousepressed(50, 100, 1)
  check("body press routed to active panel", p2.pressed == true)
  check("inactive panel untouched", p1.pressed == false)

  local ok = pcall(function() tabs:draw() end)
  check("draw no error", ok)
end

do
  h.section("Tabs keyboard")
  local function fakePanel(consumeKey)
    local p = { pressed = false }
    function p:update() end
    function p:draw() end
    function p:mousepressed() return false end
    function p:mousereleased() end
    function p:keypressed(k) return consumeKey ~= nil and k == consumeKey end
    function p:textinput() return false end
    return p
  end
  local switched
  local r = fox.Root.new()
  local tabs = r:add(fox.Tabs.new{ x = 0, y = 0, w = 300, headerH = 30,
    tabs = { { label = "A", panel = fakePanel() },
             { label = "B", panel = fakePanel() },
             { label = "C", panel = fakePanel() } },
    onChange = function(i) switched = i end })
  r:setFocus(tabs)
  tabs:keypressed("right")
  check("right switches to 2", tabs.selected == 2 and switched == 2)
  tabs:keypressed("left")
  check("left switches to 1", tabs.selected == 1)
  tabs:keypressed("end")
  check("end selects last", tabs.selected == 3)
  tabs:keypressed("home")
  check("home selects first", tabs.selected == 1)

  -- Active panel gets first refusal: a panel that consumes "right" blocks switch.
  local r2 = fox.Root.new()
  local blocker = r2:add(fox.Tabs.new{ x = 0, y = 0, w = 300, headerH = 30,
    tabs = { { label = "A", panel = fakePanel("right") },
             { label = "B", panel = fakePanel("right") } } })
  r2:setFocus(blocker)
  blocker:keypressed("right")
  check("panel consumes key, no tab switch", blocker.selected == 1)
end
