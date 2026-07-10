-- foxloves: a small UI design system for LÖVE (love2d).
-- Usage: local fox = require("foxloves")
--        local btn = fox.Button.new{ ... }

local M = {
  theme       = require("foxloves.theme"),
  util        = require("foxloves.util"),
  Root        = require("foxloves.root"),
  Button      = require("foxloves.widgets.button"),
  Textbox     = require("foxloves.widgets.textbox"),
  Label       = require("foxloves.widgets.label"),
  Divider     = require("foxloves.widgets.divider"),
  ProgressBar = require("foxloves.widgets.progressbar"),
  Checkbox    = require("foxloves.widgets.checkbox"),
  Toggle      = require("foxloves.widgets.toggle"),
  RadioGroup  = require("foxloves.widgets.radiogroup"),
  Slider      = require("foxloves.widgets.slider"),
  Stepper     = require("foxloves.widgets.stepper"),
  IconButton  = require("foxloves.widgets.iconbutton"),
  Panel       = require("foxloves.widgets.panel"),
  Modal       = require("foxloves.widgets.modal"),
  Dropdown    = require("foxloves.widgets.dropdown"),
  Tooltip     = require("foxloves.widgets.tooltip"),
  Tabs        = require("foxloves.widgets.tabs"),
  ListBox     = require("foxloves.widgets.listbox"),
}

return M
