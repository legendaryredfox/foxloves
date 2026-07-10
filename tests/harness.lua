-- Shared test harness for foxloves. Installs the headless LÖVE stub, loads the
-- library, and exposes a check() plus running pass/fail totals. Case files under
-- tests/cases/ require this module and run their assertions at require time; the
-- module is cached, so every case shares one set of counters and one `fox`.

package.path = "./?.lua;./?/init.lua;" .. package.path

local love_stub = require("tests.love_stub")
love_stub.install()

local H = {
  fox = require("foxloves"),
  love_stub = love_stub,
  pass = 0,
  fail = 0,
}

function H.section(name)
  print(name)
end

function H.check(name, cond)
  if cond then
    H.pass = H.pass + 1
    print("  ok   " .. name)
  else
    H.fail = H.fail + 1
    print("  FAIL " .. name)
  end
end

return H
