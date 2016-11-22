local miscFunctions = {}
-- Things I care about and need
-- Modified to fit my preferred method of adding functions
--	Hyper+V			typeClipboard		Type clipboard as text (avoid web site CMD-V blockers)
--	HyperFn+Q		quitApp				Quit App
--	HyperFn+W		closeWindow			Close window (or tab)
--	HyperFn+D		dictate				Dictate on/off
--	HyperFn+.		moveToDone			Move current mail item to "Done"
--	HyperFn+,		moveToStatus		Move current mail item to "Status"

-- private functions to be referenced & executed later.
function typeClipboardAsText()
	hs.eventtap.keyStrokes(hs.pasteboard.getContents()) 
end

function quitApp()
	hs.eventtap.keyStroke({"cmd"}, "Q")
end		
function closeWindow()
	hs.eventtap.keyStroke({"cmd"}, "W")
end	
function dictate()
	hs.eventtap.keyStroke({"cmd", "opt"}, "comma")
end		
function moveToDone()
	hs.eventtap.keyStroke({"cmd", "shift"}, "period")
end	
function moveToStatus()
	hs.eventtap.keyStroke({"cmd", "shift"}, "comma")
end	

-- private
local funNameToFunction = {
	typeClipboard = typeClipboardAsText,
	hammerspoonHelp = hammerspoonHelp,
	stopHelp = stopHelp,
	quitApp = quitApp,
	closeWindow = closeWindow,
	dictate = dictate,
	moveToDone = moveToDone,
	moveToStatus = moveToStatus
}

local funNameToHelpText = {
	typeClipboard =		'Type clipboard as text (avoid web site CMD-V blockers)',
	hammerspoonHelp = 	'Help, for Hammerspoon functions',
	stopHelp = 			'Stop displaying Help',
	quitApp =			'Quit current App',
	closeWindow =		'Close window (or tab)',
	dictate =			'Dictate on/off',
	moveToDone =		'Move current mail item to "Done"',
	moveToStatus =		'Move current mail item to "Status"'
}
function miscFunctions.bind(modifiers, char, functName)
	hs.hotkey.bind(modifiers, char, funNameToFunction[functName] )	-- bind the key
	-- Add to the help string
	HF.add("Hyper+" .. char .. "     - " .. funNameToHelpText[functName] .. "\n")
end

return miscFunctions
