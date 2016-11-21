-- simpleTest.lua
local SimTst = {}

-- private functions to be referenced & executed later.
fun1 = function() 
	hs.console.printStyledtext("fun1() called from bound f()")
	return "fun1"
end
fun2 = function() 
	local y = 1
	return "fun2"
end


-- private
local helpString = "SimpleTest Help\n"
local funNameToFunction = {
	myName1 = fun1,
	myName2 = fun2
}

-- external interface
function SimTst.getHelpString()
--	helpString = helpString .. "Hyper+A: Apple\n"
--	helpString = helpString .. "Hyper+B: Banana\n"
--	helpString = helpString .. "Hyper+C: Carbon\n"
	hs.console.printStyledtext(fun1())
	hs.console.printStyledtext(fun2())
	return helpString
end

function SimTst.bind(modifiers, char, functName)
	hs.console.printStyledtext(# modifiers)
	hs.console.printStyledtext(char)
	hs.console.printStyledtext(functName)
	hs.hotkey.bind(modifiers, char, funNameToFunction[functName])
	return "123"
end

return SimTst


-- --------------------------------------------
-- -- Example usage:
-- local ST = require 'simpleTest'
-- ST.bind({}, "U", some_funct_name)
-- helpString = helpString .. ST.getHelpString()	-- accumulate help strings
