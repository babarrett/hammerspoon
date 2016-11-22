local helpFunctions = {}
-- help.lua
--	Hyper+H			hammerspoonHelp		Help, for Hammerspoon functions
--	Hyper+Esc		stopHelp			Stop displaying Help

-- private fields
--	"Help" - brief descriptions of mapped f()s. 
--	HyperFn+H to show
--	HyperFn+Esc to stop showing before it times out
local helpAlertUUID = nil
local helpString = ""		-- start empty, we'll add to it as we go along.

-- Add help text to the end of what we have so far.
-- TODO: Add 1st parameter for modifiers or ""?
function helpFunctions.add(newString)
	 helpString = helpString .. newString
end
function helpFunctions.displayHelp()
	helpAlertUUID = hs.alert.show( "Help for Bruce's Hammerspoon functions:\n" 
	.. helpString 
	, 
	{textSize=14, textColor={white = 1.0, alpha = 1.00 }, 
	textFont = "Andale Mono",	-- works for me. If missing reverts back to system default
	fillColor={white = 0.0, alpha = 1.00}, 
	strokeColor={red = 1, green=0, blue=0}, strokeWidth=4 }
	, 6	-- display 6 seconds
	)
	
end



-- TODO: delete this
function hammerspoonHelp()
	if helpAlertUUID ~= nil then
		hs.alert.closeSpecific(helpAlertUUID)
	end
	helpAlertUUID = hs.alert.show( 
		helpString
	, 
	{textSize=14, textColor={white = 1.0, alpha = 1.00 }, 
	textFont = "Andale Mono",	-- works for me. If missing reverts back to system default
	fillColor={white = 0.0, alpha = 1.00}, 
	strokeColor={red = 1, green=0, blue=0}, strokeWidth=4 }
	, 6	-- display 6 seconds
	)
end
function stopHelp()
	--Stop displaying Help if you've read it all
	if helpAlertUUID ~= nil then
		hs.alert.closeSpecific(helpAlertUUID)
		helpAlertUUID = nil
	end
end

--[[ Binding happens at load (requires) time.
hs.hotkey.bind(HyperFn, "H", helpFunctions.displayHelp)
hs.hotkey.bind(HyperFn, "escape", helpFunctions.stopHelp)
]]--
local funNameToFunction = {
	hammerspoonHelp = hammerspoonHelp,
	stopHelp = stopHelp,
}


local funNameToHelpText = {
	hammerspoonHelp = 	'Help, for Hammerspoon functions',
	stopHelp = 			'Stop displaying Help',
}

function helpFunctions.bind(modifiers, char, functName)
	hs.hotkey.bind(modifiers, char, funNameToFunction[functName] )	-- bind the key
	-- Add to the help string
	HF.add("Hyper+" .. char .. "     - " .. funNameToHelpText[functName] .. "\n")
end

return helpFunctions
