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
--	HyperFn++		mouseHighlight		Show mouse location by putting a circle around it
--	HyperFn+-		manyDashes			Type 42 dashes
--	HyperFn+T		todo				Type "TODO: "
--	HyperFn+P		mdphotoplaceholder	Type something that looks like a photo in markdown.
--	HyperFn+Z		mouseToEdge			Move mouse cursor, which is somewhat close to the edge of the front-most
--                               window to sitting right on top the edge. (so mouse can grab it)

-- private functions to be referenced & executed later.

function sleep(s)
  local ntime = os.clock() + s
  repeat until os.clock() > ntime
end

function dumpTable(myTable)
  local count = 0
  for k,v in pairs(myTable) do
    debuglog("dumpTable: "..k..", "..v)
  end
end

function typeClipboardAsText()
-- Pause for 0.2 seconds every 20 characters to let app catch up.
-- Without this I was occasionally getting swapped characters: teh
--	rs = tostring(hs.pasteboard.readStyledText())
	tx = hs.pasteboard.readString(true)	-- table
--	debuglog(type(tx))
--	dumpTable(tx)
	for ky,vl in pairs(tx) do
--		debuglog("value of vl ("..ky..") is "..tostring(vl))
		for i = 1, string.len(tostring(vl)), 20 do
		  st = string.sub(vl, i, i+19)
		  hs.eventtap.keyStrokes(st)
		  sleep(.50)
		end
	end
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
    mouseCircle:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1})
    mouseCircle:setFill(false)
    mouseCircle:setStrokeWidth(5)
    mouseCircle:show()

    -- Set a timer to delete the circle after 3 seconds
    mouseCircleTimer = hs.timer.doAfter(1, function() mouseCircle:delete()
    end)
end


function manyDashes()
	 hs.eventtap.keyStrokes('-------------------------------------------')
end

function mdphotoplaceholder()
	 hs.eventtap.keyStrokes("```")
	 hs.eventtap.keyStroke({}, "Return")
	 hs.eventtap.keyStrokes("    +-----+")
	 hs.eventtap.keyStroke({}, "Return")
	 hs.eventtap.keyStrokes("    |photo|")
	 hs.eventtap.keyStroke({}, "Return")
	 hs.eventtap.keyStrokes("    +-----+")
	 hs.eventtap.keyStroke({}, "Return")
	 hs.eventtap.keyStrokes("```")
	 hs.eventtap.keyStroke({}, "Return")
end


-- function fiveShifts()
--	 hs.eventtap.keyStroke({"shift"}, "")
--end

function todo()
	 hs.eventtap.keyStrokes('TODO: ')
end

function mouseToEdge()
  -- TODO: BUG: Test more when window is touching edge of screen. May
  -- need to adjust like we did with "top"

	local win = hs.window.frontmostWindow()
	local fudge = 40
	if win ~= nil then	-- only if there's a window to move
		local wf = win:frame() -- in absolute coordinates

		debuglog("-------------------------------------------\nWindow Frame rect (x, y, w, h): "..wf.x..", "..wf.y..", "..wf.w..", "..wf.h)

    mouseAbs = hs.mouse.getAbsolutePosition()
		debuglog("---Abs (x,y)---: ("..mouseAbs.x..", "..mouseAbs.y..")")
		-- update here
		if (math.abs(mouseAbs.x - wf.x) < fudge) then
		  mouseAbs.x = wf.x  -- left edge
		end
		if (math.abs(mouseAbs.y - wf.y) < fudge) then
		  mouseAbs.y = math.floor(wf.y)+1  -- top edge
		end

		if (math.abs(mouseAbs.x - (wf.x+wf.w)) < fudge) then
		  mouseAbs.x = wf.x+wf.w  -- right edge
		end
		if (math.abs(mouseAbs.y - (wf.y+wf.h)) < fudge) then
		  mouseAbs.y = wf.y+wf.h  -- bottom edge
		end
		debuglog("---Abs (x,y)---: ("..mouseAbs.x..", "..mouseAbs.y..")")
		hs.mouse.setAbsolutePosition(mouseAbs)
	end

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
function miscFunctions.bind(modifiers, char, functName)
	debuglog("miscFunctions binding: "..char.." to "..functName)
	hs.hotkey.bind(modifiers, char, nil, funNameToFunction[functName] )	-- bind the key
	-- Add to the help string
	HF.add("Hyper+" .. char .. "     - " .. funNameToHelpText[functName] .. "\n")
end


return miscFunctions
