local helpFunctions = {}
-- helpFunctions.lua
-- Hyper+H		Help, for Hammerspoon functions, or dismiss if already up
-- TODO: Keep Help up until HyperFn key is released?

-- Private fields
-- helpString - brief descriptions of mapped f()s. 
local helpAlertUUID = nil
local helpString = ""		-- start empty, we'll add to it as we go along.

-- Append help text to existing
function helpFunctions.add(newString)
	 helpString = helpString .. newString
end

-- TODO: Convert from alert to HTML for better controls, window placement,
--		manual time-out to force exit.
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
		, 90	-- display 90 seconds, or usr hits Hyper-H again
		)
	end
end

local funNameToFunction = {
	hammerspoonHelp = hammerspoonHelp
}


local funNameToHelpText = {
	hammerspoonHelp = 	'Help, for Hammerspoon functions, and again to dismiss.',
}

-- TODO: Make this a mode: modalKey = hs.hotkey.modal.new(HyperFn, 'H')
--		so we can ignore all but HyperFn+H
function helpFunctions.bind(modifiers, char, functName)
	hs.hotkey.bind(modifiers, char, funNameToFunction[functName] )	-- bind the key
	-- Add to the help string
	-- TODO: Change to accept modifiers (table) and convert to visual (⌘⌥⌃⇧)
	-- TODO: Change to adjust column widths so  they line up: 
	--		Col 1: "Hyper+Right" = 11 char
	--		Col 2: " - " + text
	HF.add("Hyper+" .. char .. "     - " .. funNameToHelpText[functName] .. "\n")
end

return helpFunctions
