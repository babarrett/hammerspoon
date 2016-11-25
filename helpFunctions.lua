local helpFunctions = {}
-- help.lua
--	Hyper+H			hammerspoonHelp		Help, for Hammerspoon functions, or dismiss if already up

-- private fields
--	"helpString" - brief descriptions of mapped f()s. 
local helpAlertUUID = nil
local helpString = ""		-- start empty, we'll add to it as we go along.

-- Add help text to the end of what we have so far.
-- TODO: Add 1st parameter for modifiers or ""?
function helpFunctions.add(newString)
	 helpString = helpString .. newString
end

-- TODO: delete this
function hammerspoonHelp()
	if helpAlertUUID ~= nil then
		hs.alert.closeSpecific(helpAlertUUID)
		helpAlertUUID = nil
	else
		helpAlertUUID = hs.alert.show( 
			helpString
		, 
		{textSize=14, textColor={white = 1.0, alpha = 1.00 }, 
		textFont = "Andale Mono",	-- works for me. If missing reverts back to system default
		fillColor={white = 0.0, alpha = 1.00}, 
		strokeColor={red = 1, green=0, blue=0}, strokeWidth=4 }
		, 20	-- display 20 seconds, or until Hyper-Escape
		)
	end
end

local funNameToFunction = {
	hammerspoonHelp = hammerspoonHelp
}


local funNameToHelpText = {
	hammerspoonHelp = 	'Help, for Hammerspoon functions, and again to dismiss.',
}

function helpFunctions.bind(modifiers, char, functName)
	hs.hotkey.bind(modifiers, char, funNameToFunction[functName] )	-- bind the key
	-- Add to the help string
	HF.add("Hyper+" .. char .. "     - " .. funNameToHelpText[functName] .. "\n")
end

return helpFunctions
