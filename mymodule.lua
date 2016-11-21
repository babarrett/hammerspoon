-- mymodule.lua
local M = {} -- public interface

-- private
local x = 1
local function baz() 
  print 'test' 
end

-- external interface
function M.foo()
  print("foo", x) 
end

function M.bar()
  M.foo()		-- calling external functions
  baz()			-- calling private functions
  print "bar"
end

return M

-- -- Example usage:
-- local MM = require 'mymodule'
-- MM.foo()
-- MM.bar()
