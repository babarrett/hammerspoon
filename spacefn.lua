local spacefn = {}
-- SpaceFn mappings
-- Keyboard mapping from Space+X to action. (Often CMD+key)
-- Modified to fit my preferred method of adding functions

--  ⌘⌥⌃⇧     -- Visual representation
--  Start Simple
--	SpaceFn+Z		Undo
--	SpaceFn+X		Cut to Clipboard
--	SpaceFn+C		Copy to Clipboard
--	SpaceFn+V		Paste Clipboard
--  Navigation Cluster:
--                      ⌫ word   Delete
--    ↖️  ⬆️    ⇞                     U, I, O
--⬅⇧  ⬅️  ⬇️    ➡️  ⇧➡️              H, J, K, L, ;  (Outer arrows for select)
--        ↙️  ⬇️    ⇟                   M, ,, .
--
--  Behaviors and operations:
--    Unused keys: if you hold the space bar and press a key that has no
--    function in the SpaceFn layout, you get exactly the same result as
--    if you were not holding space.
      --    There is an Esc key in the Fn layer (E key), because you may want to have direct
      --    access to the backquote in the basic layout. Also, it may be convenient to be
      --    able to press Esc without releasing the space bar.
--    SpaceFN+B for repeating spaces (because holding Space won't repeat any more)
--    NO: double tap the space bar (2 taps in X milliseconds) to trigger repeating
--    TODO: Support SpaceFn+Mod+(Shift+Arrow) for select word and line.
--    Approx. 300ms timeout on Space bar, so:
--      Space, < 300ms, release = " "
--      Space, > 300ms, key, release = SpaceFn+key
--      Space, > 300ms, no other keys pressed, do nothing
--
--Legend:
--  Spc - space bar
--  k   - normal key (a-z,0-9, punctuation,etc.)
--  mod - modifier key (Shift, Control, Alt/Option, Win/Command)
--  --> - arrow key
--
--Normal operations:
--  Generate a space character (tap for space)
--  Spc   -----\_____/-----
--
--  Generate a SpaceFn character (unambigious case)
--  Spc   -----\____________/-----
--  k     --------\_____/-----
--
--  Cancel a mistakenly started SpaceFn function.
--  At least Esc will cancel. TBD: Will any non-SpaceFn key cancel? or be treated
--  as the un-SpaceFn character?
--  Spc   -----\____________/-----
--  Esc   --------\_____/---------
--
--
--
--Less common cases to be handled:
--  Space + Option + RightArrow + RightArrow + RightArrow moves right three words (OS X)
--  Spc   -----\_____________________________________________/-----
--  mod   --------\_______________________________________/-----
--  k     -----------\______/------\______/------\______/-----
--
--  Using Space+##s to cause repeat of the next character if it is: Any arrow, delete/backspace, del
--  Space + 1 + 1 + RightArrow moves right 11 characters.
--  Spc   -----\_____________________________________________/-----
--  1     -----------\______/------\______/------------------------
--  -->   --------------------------------------\______/-----------
--
--
--
--Ambigious, or edge-case conditions:
--  k starts during Spc down, but ends after Spc up.
--  ("Rollover issue" caused by starting k before fully releasing Spc. Fast typist.)
--  Interpret this as: Space, k
--  Spc   -----\__________/-----
--  k     --------------\______/-----
--
--    wilderjds: What I ended up doing, and it works quite well even in actual real world typing,
--    at least for me, is the following:
--      #1. If spacebar is pressed, then k is released, treat the spacebar press as a space press.
--      #2. If spacebar is pressed, then k is pressed and spacebar is released, treat the
--        spacebar events as space events
--    #3. Otherwise treat the spacebar press (and the following release) as a SpaceFn.
--    I guess the key thing is the first of the checks. It makes all the difference in
--    the world for me.
--
--    There are four possible relationships between Space and k:
--    * Space and k don't overlap. Unambiguous.
--    * k overlaps the start of Space. Treat as k, Space
--    * k overlaps the end of Space. Treat as Space, k
--    * k is wholly within Space. Treat as SpaceFn+k
--    * Space is wholly within k. Treat as SpaceFn+k
--  Spc   -----\____/----------------
--  k     --------------\______/-----
--
--  Spc   -------\__________/--------
--  k     ----\______/---------------
--        Rule #1 says this is: k, Space
--
--  Spc   -----\__________/-----
--  k     --------------\______/-----
--        Rule #2 says this is: Space, k
--
--  Spc   -----\___________________/-----
--  k     --------------\______/-----
--        Rule #3 says this is: SpaceFn+k
--
--  Spc   ------------\____/---------
--  k     ------\______________/-----
--        Rule #3 says this is: SpaceFn+k


--  Hasu says: (DR = Duel Role)
--    Rules determining whether DRmod should perform as key or modifier are very simple:
--    1. Judging term (200ms in my case) elapsed(timeout) => modifier
--    3. DRmod is released within 200ms(tapping)  => key
--    Need to buffer keys while Space is down.
--
--    Placing modifiers on home row is nice idea. I've used ';' as modifier happily
--    for a few years but never tried other home keys. If you use alpha keys as
--    modifier it'll be important to choke off false detection as possible with
--    tweaking code or parameters. It is really challenging idea.
--  Lydell
--    One thing that really made a big difference in my script, is the ability to
--    have key-level settings (which I added in version 0.3.0). I use 70ms delay by
--    default, and 200ms for the alt and Windows dual-role keys.

--    Why is it necessary to have a delay?
--    Think of a dual-role key is comprised of Space and Shift.
--    When you type, for example, "a man" fast you will/may press 'm' before
--    releasing space key. Without the delay you will get "aMan" in this case.

--    More research (paper): http://edgarmatias.com/papers/hci96
--    BTW, while one-handed typing is very cool, I found that replacing Caps Lock with
--    an Fn key (and a well designed Fn layer) is a lot more useful in day-to-day use...
--    http://matias.ca/optimizer
--    http://matias.ca/optimizer/viewer/?p=5
--    The Backspace, Enter, Copy/Paste shortcuts on the left hand are expecially handy.

--    My use of dual role keys: ***
--    1. space as shift: we usually don't press space and shift at the same time, this
--    setting helps to keep my hands on the home row.
--    2. "f" used to activate navigation layer: I have a layer in which the right hand
--    home row keys are assigned to navigation keys, since we seldom use characters
--    and navigation keys (arrow keys) in combination, this setting allows me to keep
--    my hands on the home row all the time.

--    Checking release order can prevent most errors as well. The potential
--    downside is that you may have to retrain yourself to always release modifier
--    keys last (though this isn't a huge deal). A combination of this and a delay may
--    be very reliable.

--  Possible interactions



--  How to do this...
--  hs.eventtap and hs.eventtap.event
--  hs.eventtap.new(types, fn) -> eventtap
--      types = {"keyDown", "keyUp"}
--      fn = mycallbackfunction when event occures
--
--  SpaceFnDown = false
--  Tap Events, set callback for {"keyDown", "keyUp"}
--
--  callback(event)
--    if key == "space" and type == "keyDown"
--      SpaceFnDown = true
--    if key == "space" and type == "keyUp"
--      SpaceFnDown = false
--      .
--
--
--
--
--
--
--
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
