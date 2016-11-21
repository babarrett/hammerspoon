local miscFunctions = {}
-- Things I care about and need
-- Modified to fit my preferred method of adding functions
--	Hyper+V					Type clipboard as text (avoid web site CMD-V blockers)
--	Hyper+H					Help, for Hammerspoon functions
--	Hyper+Esc				Stop displaying Help
--	HyperFn+Q				Quit App
--	HyperFn+W				Close window (or tab)
--	HyperFn+D				Dictate on/off
--	HyperFn+/				Cmd-Shift (for move to done in Mail)

-- private functions to be referenced & executed later.
function typeClipboardAsText()
	hs.eventtap.keyStrokes(hs.pasteboard.getContents()) 
end

-- private
local helpString = ""
local funNameToFunction = {
	pasteSafariUrl = typeCurrentSafariURL
}

function pasteCurrentSafariUrl.bind(modifiers, char, functName)
	-- Bind it to HyperFn+U
	helpString = "Hyper+" .. char .. "     - Fetch the current URL from Safari and type it.\n"
	hs.hotkey.bind(modifiers, char, funNameToFunction[functName] )
end

function pasteCurrentSafariUrl.getHelpString()
	return helpString
end

return pasteCurrentSafariUrl
