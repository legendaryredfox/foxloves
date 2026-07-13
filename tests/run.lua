-- foxloves test runner. No external deps.
-- Run from project root: luajit tests/run.lua   (or: lua tests/run.lua)
--
-- The harness installs the headless LÖVE stub and loads the library; each case
-- file under tests/cases/ runs its assertions at require time and shares the
-- harness's pass/fail counters. To add a suite, drop a file in tests/cases/ and
-- list it below.

local h = require("tests.harness")

local cases = {
  "button",
  "textbox",
  "label",
  "divider",
  "progressbar",
  "checkbox",
  "toggle",
  "radiogroup",
  "slider",
  "stepper",
  "iconbutton",
  "root",
  "panel",
  "modal",
  "dropdown",
  "tooltip",
  "tabs",
  "listbox",
  "badge",
  "avatar",
  "contextmenu",
  "toast",
  "spinner",
  "numberfield",
  "segmentedcontrol",
  "interaction",
}

for _, name in ipairs(cases) do
  require("tests.cases." .. name)
end

print(string.format("\n%d passed, %d failed", h.pass, h.fail))
os.exit(h.fail == 0 and 0 or 1)
