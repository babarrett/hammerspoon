-- Edit Selection functions:
--	* Surround selection with <x_pasteboard> and <y_pasteboard>
--	* Load <x_pasteboard> with selection
--	* Load <y_pasteboard> with selection
--	* Find next (Cmd+G)
--
--	Delete Word functions:
--	* Delete left 1 word. (Shift+Backspace)
--
--	TODO: 
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

-- getTextSelection()
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

function selectAll()
	hs.eventtap.keyStroke("Cmd", "A")
end

function toUppercase()
	sel = getTextSelection()
	if sel then hs.eventtap.keyStrokes(string.upper(sel)) end
end

function toLowercase()
	sel = getTextSelection()
	if sel then hs.eventtap.keyStrokes(string.lower(sel)) end
end

function toTitleCase()
	-- TODO: scan for non-alphas, replace next w/ Caps
	sel = getTextSelection()
	if sel == nil then return end
	newSel = ""
	debuglog("Pre: "..sel)
	lastWasWhiteSpace = true
	for i=1, string.len(sel), 1 do
		thisChar = string.sub(sel, i, i)
		if string.find(thisChar, "[ \t]") then
			lastWasWhiteSpace = true
		elseif lastWasWhiteSpace then
			thisChar = string.upper(thisChar)
			lastWasWhiteSpace = false
		end
		newSel = newSel..thisChar
		debuglog(tostring(lastWasWhiteSpace))
	end
	debuglog("Post: "..newSel)
	hs.eventtap.keyStrokes(newSel)
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


function deletePreviousWord()
	-- Get current selection, exit if not empty
	currSel = getTextSelection()
	if string.len(currSel) < 1 then return end
	
	-- Select to start of line, copy. Exit if empty
	hs.eventtap.keyStroke("Cmd Shift", "Left")
	currSel = getTextSelection()
	if string.len(currSel) < 1 then return end
--	debuglog("currSel: "..currSel.."<<<")

	-- Replace with all but prior word by searching back from end looking for word break
	-- iTerm defines these as part of a word: /-+\~_.
	-- BBEdit Uses: defiles word characters as a-z, A-Z, 0-9, _, and some 8-bit characters
	-- New string = oldstring w/o the last word. Lua uses %w for alpha-numeric characrers. %W for non-
	
	-- Drop any trailing non-words
	newS = string.match(currSel, "(.*%w)(%W*)$")
--	debuglog("newS___: "..newS.."<<<")
	-- Drop last trailing word
	newS = string.match(newS, "(.*%W)(%w+)$")
	--debuglog("newS__.: "..newS.."<<<")

--	debuglog("lastWord: "..newS.."<<<")
--	debuglog("lastSpace: "..newS.."<<<")
	-- If the insertion point is past the end of the word to the left, for example at the end of
	-- "last word  " instead of at the end of "last word" then we would have copied the next character too.
	-- Check for, and drop any non-word characters at the end of the selection.
	trim = string.gsub(newS, ".*(%w*$)", "")
	--debuglog("trim___: "..trim.."<<<")
	hs.eventtap.keyStrokes(newS)
	-- Drop selection
--	hs.eventtap.keyStroke({""}, "right")
end





hs.hotkey.bind("ctrl", "f1", nil, function()  typePreSelectionPost()  end )
hs.hotkey.bind("ctrl", "f2", nil, function()  findNext()  end )
-- alt == option
hs.hotkey.bind("alt",  "f1", nil, function()  loadSelectionIntoPre()	end )
hs.hotkey.bind("alt",  "f2", nil, function()  loadSelectionIntoPost()	end )


hs.hotkey.bind("ctrl",  "delete", nil, function()  deletePreviousWord()	end )
hs.hotkey.bind("ctrl",  "f4", nil, function()  selectAll()		end )
hs.hotkey.bind("ctrl",  "f5", nil, function()  toUppercase()	end )
hs.hotkey.bind("ctrl",  "f6", nil, function()  toLowercase()	end )
hs.hotkey.bind("ctrl",  "f7", nil, function()  toTitleCase()	end )
--hs.hotkey.bind("ctrl",  "f8", nil, function()  toUncamelCase()	end )


return editSelection
