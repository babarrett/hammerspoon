-- Edit Selection functions:
--	* Surround selection with <x_pasteboard> and <y_pasteboard>
--	* Load <x_pasteboard> with selection
--	* Load <y_pasteboard> with selection
--	* Find next (Cmd+G)

-- 	* Select All
--	* Convert to UPPER case
--	* Convert to Title case
--	* Convert to lower case
--	* Open up camel case (ThisIsATest --> This Is A Test, or this is a test)

-- by: Bruce Barrett

editSelection = {}

local	pre = nil
local	post = nil
local	sel = nil

-------------------------------------------
--	Utility Function

-- getTextSelection
-- 	Gets currently selected text using Cmd+C
--	Saves and restores the current pasteboard
--	Imperfect, perhaps.
--	Taken from: https://github.com/Hammerspoon/hammerspoon/issues/634
function getTextSelection()	-- returns text or nil
	local oldText = hs.pasteboard.getContents()
	hs.eventtap.keyStroke({"cmd"}, "c")
	hs.timer.usleep(100000)
	local text = hs.pasteboard.getContents()
	hs.pasteboard.setContents(oldText)
	return text
end

-------------------------------------------
--	Functions to bind to:

function typePreSelectionPost() 
	debuglog("typePreSelectionPost")
	sel = getTextSelection()
	if sel == nil then return end
	
	if pre then hs.eventtap.keyStrokes(pre) end
	if sel then hs.eventtap.keyStrokes(sel) end
	if post then hs.eventtap.keyStrokes(post) end
	
end

function findNext()
	hs.eventtap.keyStroke("Cmd", "G")
end

function loadSelectionIntoPre()
	debuglog("Pre")
	pre = getTextSelection()
	hs.alert("Pre = "..pre)
end

function loadSelectionIntoPost()
	debuglog("Post")
	post = getTextSelection()
	hs.alert("Post = "..post)
end





hs.hotkey.bind("ctrl", "f1", nil, function()  typePreSelectionPost()  end )
hs.hotkey.bind("ctrl", "f2", nil, function()  findNext()  end )
-- alt == option
hs.hotkey.bind("alt",  "f1", nil, function()  loadSelectionIntoPre()	end )
hs.hotkey.bind("alt",  "f2", nil, function()  loadSelectionIntoPost()	end )





return editSelection
