local miscFunctions = {}
-- Things I care about and need.
-- Primarily Keyboard mapping from HyperFn+X to Command sequence, but could be more complex.
-- Modified to fit my preferred method of adding functions

--	HyperFn+V		typeClipboard		Type clipboard as unformatted text (avoid web site CMD-V blockers)
--	HyperFn+Q		quitApp				Quit App
--	HyperFn+W		closeWindow			Close window (or tab)
--	HyperFn+D		dictate				Dictate on/off (Cmd+Opt+,)
--	TODO: Only respond if in "Mail" App
--	HyperFn+/		moveToDone			Move current mail item to "Done"
--	HyperFn+,		moveToStatus		Move current mail item to "Status"

-- private functions to be referenced & executed later.
function typeClipboardAsText()
	hs.eventtap.keyStrokes(hs.pasteboard.getContents()) 
end

function quitApp()
	hs.eventtap.keyStroke({"cmd"}, "Q")
end		
function miscFunctions.closeWindow()
	hs.eventtap.keyStroke({"cmd"}, "W")
end	
function dictate()
	hs.alert.show("Dictate")
	hs.eventtap.keyStroke({"cmd", "opt"}, "comma")
end		
function moveToDone()
	hs.alert.show("moveTo Done", 4)
	-- BUG: We don't get this far.
	hs.eventtap.keyStroke({"cmd", "shift"}, "period")	-- ">"
end	
function moveToStatus()
	hs.alert.show("moveTo Status", 4)
	-- BUG: We don't get this far.
	hs.eventtap.keyStroke({"cmd", "shift"}, "comma")	-- "<"
end	

-- private
local funNameToFunction = {
	typeClipboard = typeClipboardAsText,
	hammerspoonHelp = hammerspoonHelp,
	stopHelp = stopHelp,
	quitApp = quitApp,
	closeWindow = miscFunctions.closeWindow,
	dictate = dictate,
	moveToDone = moveToDone,
	moveToStatus = moveToStatus
}

local funNameToHelpText = {
	typeClipboard =		'Type clipboard as text (avoid web site ⌘-V blockers)',
	hammerspoonHelp = 	'Help, for Hammerspoon functions',
	stopHelp = 			'Stop displaying Help',
	quitApp =			'Quit current App',
	closeWindow =		'Close window (or tab)',
	dictate =			'Dictate on/off',
	moveToDone =		'Mail: Move current item to "Done"',
	moveToStatus =		'Mail: Move current item to "Status"'
}
function miscFunctions.bind(modifiers, char, functName)
	hs.hotkey.bind(modifiers, char, nil, funNameToFunction[functName] )	-- bind the key
	-- Add to the help string
	HF.add("Hyper+" .. char .. "     - " .. funNameToHelpText[functName] .. "\n")
end

return miscFunctions
