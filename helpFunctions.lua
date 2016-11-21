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
	-- #mark H=Help
	if helpAlertUUID ~= nil then
		hs.alert.closeSpecific(helpAlertUUID)
	end
	helpAlertUUID = hs.alert.show( "Help for Bruce's Hammerspoon functions:\n" 
	.. pasteCurrentSafariUrl.getHelpString()
	.. "Hyper-V     - Type clipboard as text (avoid web site CMD-V blockers).\n"
	.. windowManagement.getHelpString()
	.. "\n"
	-- BUG: This should loop through to accumulate active screens.
	.. "Active screens: " .. hs.screen.allScreens()[1]:name() .. ", " .. hs.screen.allScreens()[2]:name() 
	, 
	{textSize=14, textColor={white = 1.0, alpha = 1.00 }, 
	textFont = "Andale Mono",	-- works for me. If missing reverts back to system default
	fillColor={white = 0.0, alpha = 1.00}, 
	strokeColor={red = 1, green=0, blue=0}, strokeWidth=4 }
	, 6	-- display 6 seconds
	)
	-- DEBUG:  hs.console.printStyledtext(string.gsub(package.path, ";", "\n"))
end
function helpFunctions.stopHelp()
	--Stop displaying Help if you've read it all
	if helpAlertUUID ~= nil then
		hs.alert.closeSpecific(helpAlertUUID)
		helpAlertUUID = nil
	end
end

-- Binding happens at load (requires) time.
hs.hotkey.bind(HyperFn, "H", helpFunctions.displayHelp)
hs.hotkey.bind(HyperFn, "escape", helpFunctions.stopHelp)

return helpFunctions
