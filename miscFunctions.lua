local miscFunctions = {}
-- Things I care about and need.
-- Primarily Keyboard mapping from HyperFn+X to Command sequence, but could be more complex.
-- Modified to fit my preferred method of adding functions

--	HyperFn+V		typeClipboard		Type clipboard as unformatted text (avoid web site CMD-V blockers)
--	HyperFn+Q		quitApp				Quit App
--	HyperFn+W		closeWindow			Close window (or tab)
--	HyperFn+D		dictate				Dictate on/off (Cmd+Opt+,)
--	HyperFn+L		Lock screens		Instantly lock screen so I can walk away
--	TODO: Only respond if in "Mail" App; Add BBEdit-only functions
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
	-- BUG: We don't get this far.
	debuglog("moveTo Done")
	hs.alert.show("moveTo Done", 4)
--	hs.eventtap.keyStroke({"cmd", "shift"}, "period")	-- ">"
end	
function moveToStatus()
	-- BUG: We don't get this far if we try to use HyperFn+, or . (or /)?
	debuglog("moveTo Status")
	hs.alert.show("moveTo Status", 4)
--	hs.eventtap.keyStroke({"cmd", "shift"}, "comma")	-- "<"
end	

function lockMyScreen()
	hs.caffeinate.lockScreen()
end

-- Cursor locator
-- Adapted (slightly) from: https://gist.github.com/ttscoff/cce98a711b5476166792d5e6f1ac5907

local mouseCircle = nil
local mouseCircleTimer = nil

function mouseHighlight()
  size = 70
    -- Delete an existing highlight if it exists
    if mouseCircle then
        mouseCircle:delete()
--        mouseCircle2:delete()
        if mouseCircleTimer then
            mouseCircleTimer:stop()
        end
    end
    -- Get the current co-ordinates of the mouse pointer
    mousepoint = hs.mouse.getAbsolutePosition()
    -- Prepare a big red circle around the mouse pointer
    mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x-(size/2), mousepoint.y-(size/2), size, size))
--    mouseCircle2 = hs.drawing.circle(hs.geometry.rect(mousepoint.x-(size/4), mousepoint.y-(size/4), size/2, size/2))
    mouseCircle:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1})
--    mouseCircle2:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1})
    mouseCircle:setFill(false)
--    mouseCircle2:setFill(false)
    mouseCircle:setStrokeWidth(5)
--    mouseCircle2:setStrokeWidth(5)
    mouseCircle:show()
--" "     mouseCircle2:show()

    -- Set a timer to delete the circle after 3 seconds
    mouseCircleTimer = hs.timer.doAfter(1, function() mouseCircle:delete() 
    	--mouseCircle2:delete() 
    end)
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
	moveToStatus = moveToStatus,
	lockMyScreen = lockMyScreen,
	mouseHighlight = mouseHighlight
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
	mouseHighlight = 	'Surround mouse cursor with red circle for 3 seconds'
}
function miscFunctions.bind(modifiers, char, functName)
	debuglog("miscFunctions binding: "..char.." to "..functName)
	hs.hotkey.bind(modifiers, char, nil, funNameToFunction[functName] )	-- bind the key
	-- Add to the help string
	HF.add("Hyper+" .. char .. "     - " .. funNameToHelpText[functName] .. "\n")
end


return miscFunctions
