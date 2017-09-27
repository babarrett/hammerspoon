local spacefn = {}
--  Two main functions, melded together:
-- 1. SpaceFn mappings
--  Keyboard mapping from Space+Key to action. For my current keuboards
--    this includes: Navigation, Cut, Copy, Paste, Undo, Backspace, Del,
--    PgUp, PgDn, Home, End, Load find selection, Find, Find next.
--
--  2. "Sticky Keys" for modifiers (⌘⌥⌃⇧)
--    Use reportLayerModifierChange.lua to display mod changes in HUD
--    TODO: Add support, after SpaceFn is complete
--
--  ⌘⌥⌃⇧     -- Visual representation
--  Left hand Cut, Paste ans Find functions:
--	SpaceFn+Z		Undo
--	SpaceFn+X		Cut to Clipboard
--	SpaceFn+C		Copy to Clipboard
--	SpaceFn+V		Paste Clipboard
--	SpaceFn+D		Load Find selection
--	SpaceFn+F   Find
--	SpaceFn+G   Find next
--  SpaceFn+E   Esc (used to exit out of mistakenly started SpaceFn)
--  SpaceFn+B   Space (repeats)
--
--  Right hand Navigation Cluster:
--   ⌫   ⬆️    Del                U, I, O
--⬅⇧  ⬅️  ⬇️    ➡️  ⇧➡️              H, J, K, L, ;  (Outer arrows for select)
--    ↖️    ↙️  (nop)   ⇞   ⇟            N, M, ,, .
--
--  Behaviors and operations:
--    Unused keys: if you hold the space bar and press a key that has no
--    function in the SpaceFn layout, you get exactly the same result as
--    if you were not holding space.
      --    There is an Esc key in the SpaceFn "layer" (E key), because you may want to 
      --    have direct access to the backquote in the basic layout. Also, it may be 
      --    convenient to be able to press Esc without releasing the space bar.
--    SpaceFn+B allows for repeating spaces (because holding Space won't repeat any more)
--    TODO: Support SpaceFn+Mod+(Shift+Arrow) for select word and line.
--    Approx. 300ms timeout on Space bar, so:
--      Space, < 300ms, release = " "
--      Space, > 300ms, key, release = SpaceFn+key
--      Space, > 300ms, no other keys pressed, do nothing
--
--Legend:
--  Spc - space bar
--  k   - normal, visible, non-modifier key (a-z,0-9, punctuation, tab, etc.)
--  mod - modifier key (Shift, Control, Alt/Option, Win/Command)
--  --> - arrow key
--  Esc - Escape
--
--
--  ----------------------------------------------------------------------
--  --------------------- Alternate thoughts, Bruce ----------------------
--  ----------------------------------------------------------------------
---- #1: Independent space
--  Spc   -----\____/-----------------------                spcDnStart
--                  Sp
--        Spc Dn, (no k) Spc Up = Emit Spc on Spc Up
--
---- #2: Independent k
--  k     --------------\______/------------                !spcDnStart
--                       k
--
---- #3: Esc within Spc to cancel
--  Spc   -----\______________________/-----                spcDnStart
--  k     --------------\______/------------
--                      Esc
--        Spc Dn, Esc Dn/Up, Spc Up = Swallow Sp and Esc
--
---- #4: Space down, k down, Spc up, k up after Spc
----        "Rollover" case, fast typest
--  Spc   -----\__________/-----------------                spcDnStart
--  k     --------------\______/------------
--                             Spc, k
--
---- #5: k wholly  within Spc
--  Spc   -----\______________________/-----                spcDnStart
--  k     --------------\______/------------
--        Spc Dn, k Dn, k Up, Spc Up = Swallow Sp, Emit Spc+k
--
---- #6: k down, Spc down, k up, Spc up after k
--  Spc   -------\__________/---------------                !spcDnStart
--  k     ----\______/----------------------
--            k             Sp
--        k Dn, Emit, Spc Dn, (don't emit), k Up, Emit k Up
--        Spc Up = Emit Spc Dn/Up (no Spc+k's emited to the Spc Dn/Up emits a Spc)
--
---- #7: k1 down, Spc down, k1 up, k2 Dn, k2 Up, Spc up
--  Spc   -------\____________________/-----                !spcDnStart
--  k     ----\______/----\______/----------
--            k1           k2
--        k1 Dn, Emit, Spc Dn, (don't emit), k1 Up, Emit k1 Up,
--        k2 Dn (emit Spc+k2 Dn), k2 Up (emit Spc+k2 Up)
--        Spc Up = Emit Spc Dn/Up (no Spc+k's emited to the Spc Dn/Up emits a Spc)
--
----  #8: LATER
--  Spc   ------------\____/----------------                !spcDnStart
--  k     ------\______________/------------
--        This could be: k Down, Space Down, Space Up, k Up = k, Spc
--        Uncommon enough to be undefined?
--
--  So, what's the algorithm for this?
--
--  Start:     
--
--  k Dn:      
--
--  k Up:      
--
--  Spc Dn:    
--
--  Spc Up:    
--
--  CleanEnd:
--
--
--  spcDnStart  kTypedinSpc keysToRelease keysDownInSpc EMIT
--  false       false       {}          {}            ""    --start

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
