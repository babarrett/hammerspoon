-- Edit Selection functions:
-- Operations that are performed on the current selection. 
-- OS X oriented.
--	* Surround selection with <x_pasteboard> and <y_pasteboard>
--	* Load <x_pasteboard> with selection
--	* Load <y_pasteboard> with selection
--	* Find next (Cmd+G)
--
-- 	* Select All
--	* Convert selection to UPPER case
--	* Convert selection to Title case
--	* Convert selection to lower case
--	* Open up camel case selection (ThisIsATest --> this is a test)
--	* Swap characters Ctrl+F12 (F9, 10, 11 are caught by OS X and cannot be used)
--
--	Delete Word functions:
--	* Delete left 1 word. (Ctrl+Backspace) 
--		Works by copying from insertion point to start of line, and replacing that with all but the last word selected.
--
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
--	Imperfect, perhaps. May not work well on large selections.
--	Taken from: https://github.com/Hammerspoon/hammerspoon/issues/634
function getTextSelection()	-- returns text or nil while leaving pasteboard undisturbed.
	local oldText = hs.pasteboard.getContents()
	hs.eventtap.keyStroke({"cmd"}, "c")
	hs.timer.usleep(100000)
	local text = hs.pasteboard.getContents()	-- if nothing is selected this is unchanged
	hs.pasteboard.setContents(oldText)
	if text ~= oldText then 
	  return text
	else
	  return ""
	end
end

-------------------------------------------
--	Functions to bind to:
-- Pre was already loaded before this call
-- Post was already loaded before this call
-- Selection is current selection.
-- Copy Selection, then type Pre+Selection+Post
function typePreSelectionPost() 
	debuglog("typePreSelectionPost")
	sel = getTextSelection()
	if sel == nil then return end
	
	if pre then hs.eventtap.keyStrokes(pre) end
	if sel then hs.eventtap.keyStrokes(sel) end
	if post then hs.eventtap.keyStrokes(post) end
	
end

-- Used in conjunction with typePreSelectionPost() to repeat the current find and prepare for the next replace.
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

-- Do not capitalize:
--	The first and last word, or these...
	noCapTitleWords = 
	{ "A", "An", "And", "As", "At", "But", "Buy", "By", "Down", "Even", "For",
	"From", "If", "In", "Into", "Like", "Long", "Near", "Nor", "Now", "Of", "Off",
	"On", "Once", "Only", "Onto", "Or", "Out", "Over", "Past", "So", "Than", "That",
	"The", "Till", "To", "Top", "Up", "Upon", "When", "With", "Yet" }

function toTitleCase()
	-- Scan for white space, quote, or other non-alphanumerics that could precede a word, 
	-- replace next character w/ Caps
	sel = getTextSelection()
	if sel == nil then return end
	newSel = ""
	capitalizeNext = true
	for i=1, string.len(sel), 1 do
		thisChar = string.sub(sel, i, i)
		if string.find(thisChar, "[ \t'\"“‘(]") then
			capitalizeNext = true
		elseif capitalizeNext then
			thisChar = string.upper(thisChar)
			capitalizeNext = false
		end
		newSel = newSel..thisChar
	end
	-- Now, uncapitalize any words to avoid (includes skipping 1st and last word.)
	for _, word in pairs(noCapTitleWords) do
		-- If any of the uppercased (by mistake) words of intrest are found, make them lowercase.
		newSel, _ = string.gsub( newSel, "[ \t'\"“‘(]"..word.."[ ,:'’”]", string.lower )
	end
	hs.eventtap.keyStrokes(newSel)
end

-- Turn CamelCaseTextRuns into: Camel case text runs
function toUncamelCase()
	-- Scan for uppercase char, replace with a space and the lowercase of it
	sel = getTextSelection()
	if sel == nil then return end
	newSel = ""
	lastWasWhiteSpace = true
	for i=1, string.len(sel), 1 do
		thisChar = string.sub(sel, i, i)
		if (string.find(thisChar, "[A-Z]") ) and  (not lastWasWhiteSpace) then
			newSel = newSel.." "..string.lower(thisChar)
		else 
			newSel = newSel..thisChar
		end
		lastWasWhiteSpace = string.find(thisChar, "[ \t]") and true or false
	end
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

-- swapChars - exchange adjacent characters.
-- If:  | is insertion point, ^^ is start of file, ^ is start of line, 
--		$ is end of line, $$ is end of file, word_center_word2 has center selected then:
--		This:		becomes this:
--		ht|e		the|
--		wr|od		word|
--		wodr|$		word|$
--		wodr|$$		word|$$
--		_drow_		word|
--		_drow$^_	no change, contains \n

function swapChars()
	
	textSel = getTextSelection()
	if string.len(textSel) > 0 then
	  if string.find(textSel, "\n") == nil then
	    -- if current selection is not empty, and does not contain newline then swap all characters
	    hs.eventtap.keyStrokes(string.reverse(textSel))
	    return
	  else
	    -- contains selection and \n, ignore
	    return
	  end
	else
	  -- no selection
	  hs.eventtap.keyStroke("", "right")
	  hs.eventtap.keyStroke("Shift", "left")
	  hs.eventtap.keyStroke("Shift", "left")
	  textSel = getTextSelection()
	  if string.find(textSel, "\n") == nil then
	    hs.eventtap.keyStrokes(string.reverse(textSel))
	  else
	    hs.eventtap.keyStroke("", "left")
	    hs.eventtap.keyStroke("", "right")
	  end
	end
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
hs.hotkey.bind("ctrl",  "f8", nil, function()  toUncamelCase()	end )
--	f9, f10, f11 are intercepted by macOS. Can't be used. :-(
hs.hotkey.bind("ctrl",  "f12", nil, function()  swapChars()	end )


return editSelection


