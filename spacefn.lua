local spacefn = {}
-- SpaceFn mappings
-- Keyboard mapping from Space+X to action. (Often CMD+key)
-- Modified to fit my preferred method of adding functions

--  Start Simple
--	SpaceFn+Z		Undo
--	SpaceFn+X		Cut to Clipboard
--	SpaceFn+C		Copy to Clipboard
--	SpaceFn+V		Paste Clipboard

--  How to do this...
--  hs.eventtap and hs.eventtap.event
--  hs.eventtap.new(types, fn) -> eventtap
--      types = {"keyDown", "keyUp"}
--      fn = mycallbackfunction when event occures
--

-- private functions to be referenced & executed later.

function dumpTable(myTable)
  local count = 0
  for k,v in pairs(myTable) do
    debuglog("dumpTable: "..k..", "..v)
  end
end

function spacefn.undo()
	hs.eventtap.keyStroke({"cmd"}, "Z")
end
function spacefn.cut()
	hs.eventtap.keyStroke({"cmd"}, "X")
end
function spacefn.copy()
	hs.eventtap.keyStroke({"cmd"}, "C")
end
function spacefn.paste()
	hs.eventtap.keyStroke({"cmd"}, "V")
end

function todo()
	 hs.eventtap.keyStrokes('TODO: ')
end

-- private
local funNameToFunction = {
	typeClipboard = typeClipboardAsText,
	hammerspoonHelp = hammerspoonHelp,
	stopHelp = stopHelp,
	quitApp = quitApp,
	closeWindow = spacefn.closeWindow,
	dictate = dictate,
	moveToDone = moveToDone,
	moveToStatus = moveToStatus,
	lockMyScreen = lockMyScreen,
	mouseHighlight = mouseHighlight,
	manydashes = manyDashes,
	mdphotoplaceholder = mdphotoplaceholder,
--	fiveShifts = fiveShifts,
	todo = todo,
	mouseToEdge = mouseToEdge
}

local funNameToHelpText = {
	typeClipboard =		'Type clipboard as text (avoid web site ⌘-V blockers)',
	hammerspoonHelp = 	'Help, for Hammerspoon functions',
	stopHelp = 			'Stop displaying Help',
	quitApp =			'Quit current App',
	closeWindow =		'Close window (or tab)',
	dictate =			'Dictate on/off',
	moveToDone =		'Mail: Move current item to "Done"',
	moveToStatus =		'Mail: Move current item to "Status"',
	lockMyScreen = 		'Lock screen so you can walk away',
	mouseHighlight = 	'Surround mouse cursor with red circle for 3 seconds',
	manydashes = 		'Type 42 hyphens',
	mdphotoplaceholder=	'Type markdown place holder for photo',
--	fiveShifts = 		'Sticky keys',
	todo = 				'Type "TODO: " for codding',
  mouseToEdge = 'Move mouse to closest edge or corner of the front-most window.'

}
function spacefn.bind(modifiers, char, functName)
	-- debuglog("spacefn binding: "..char.." to "..functName)
	hs.hotkey.bind(modifiers, char, nil, funNameToFunction[functName] )	-- bind the key
	-- Add to the help string
	HF.add("Hyper+" .. char .. "     - " .. funNameToHelpText[functName] .. "\n")
end


return spacefn
