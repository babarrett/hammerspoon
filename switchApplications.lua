switchApplications = {}

--Application switcher, like Cmd+Tab but better. Instead:
--  * √ A GUI, in a matrix of some sort
--  * √ App icons fill the matrix
--  * √ Don't list current App, Esc will return to it
--  * √ Use Hyper+Tab to activate
--  * √ Allow up, down, left, right to select;
--  * √ Indicate the selection with rectangle around App icon
--  * √ Bring up on active window. Centered
--  * √ Only currently running apps
--  * √ Return to select app we navigated to
--  * √ Use Space123456789 key to present list of open windows in chooser for app we switched to
--  * √ Window chooser is also available w/o switching apps. HyperFn+` (back-tick)
--  * √ Large keyboards: Allow N, S, E, W, NW, NE, SW, SE from NumPad #1-#9;
--  * (Later) "Badge" each app with number of open windows
--  * TODO: The matrix may be sparse. Maybe more like a cross than a complete grid, see in-line comments
--  * TODO: Improve navigation:
--  *    Use {some_modifier_or_combo, maybe Hyper+NumPad-5 Arrow to activate this mode.
--        This way you middle finger is already centered and selecting center, left or right
--        Apps requires no finger movement.
--  *   Allow click to switch;
--  *   Bring the matrix up "under" the current mouse location to make click easier. (or center mouse on grid)
--  *   Add a "black list" of apps that do not show up in doc, if you never want to switch to. (SpamSieve)
--  *   App name (truncated if needed) below the icon
--  *   Track the time spent *active* in each running app, and/or the number of times switched into.
--		    Use that to prioritize the running programs to reduce the number of navigation key movements
--		    to get to the "most used" apps
--
--Keyboard keys:
--  * Arrows, navigate around the grid
--  * Space, switch immediately to selected app
--  * Return, if selected app has > 1 window open switch to the window chooser (list), else open immediately
--  * Escape, cancel the app switch

-- Possible matrix: (# represent # of Key strokes not counting Hyper+Lead to start and <space> to select)
--  9 apps in 0 or 1 key strokes;
-- 14 apps in 2 key strokes;
-- 25 apps in <= 2 keystrokes
--			Allow	
--			Diagonal (NE, SW, etc.)
--            22222
--            21112
--            21012
--            21112
--            22222
--
-- Or, with only horizontal and vertical movements:
--        5 apps in 1 keystroke;
--        9 apps with double-tap keystrokes; (I think I usually have < 9 apps running at a time.)
--       13 apps in 2 keystrokes or less. Right, then Up for example.
--			Allow
--			Horiz+Vert
--              2
--             212
--            21012
--             212
--              2
--
--	Map of the order to add application icons to the grid.
--	Optimized for: fewest keystrokes, and minimizing number of rows.
--	I often run with 5 or 6 app running. This plan lets me have 17
--	apps running and still only have 3 rows active. 23 as represented.
--	We could fill out the entire grid and add 12 more apps for 35 total.
--	
--	            XX
-- row 01 02 03 04 05 06 07
-- --- -- -- -- -- -- -- --
--	01       23 21 22
--	02    15 11 07 10 14
--	03 17 05 04 .. 02 03 16 (center)
--	04    13 09 06 08 12
--	05       20 18 19
--
-- Kindred soles:
--		https://tomdebruijn.com/posts/super-fast-application-switching/
--		http://applehelpwriter.com/
--		https://botbot.me/freenode/hammerspoon/2017-05-01/?tz=America/Los_Angeles
--			Notice that `hs.image.imageFromAppBundle('lol') returns a generic icon
--		https://github.com/knu/hs-knu -- includes app watcher, USK kbd differentiator.
--		http://bezhermoso.github.io/2016/01/20/making-perfect-ramen-lua-os-x-automation-with-hammerspoon/
--			Switch *screen* focus. Also move mouse o screen:
--			local pt = geometry.rectMidPoint(screen:fullFrame())
--			mouse.setAbsolutePosition(pt)
--		fn key in macOS 10.12: https://github.com/Hammerspoon/hammerspoon/issues/922
--		hs.application.runningApplications() -> list of hs.application objects
--		hs.application.frontmostApplication() -> hs.application object
--		hs.application:bundleID() -> string
--  	hs.drawing.image(sizeRect, imageData) -> drawingObject or nil

--	Utility functions----------------------------------------------------------------

-- Test for "should this app be shown in the picker."
-- Return true for include the app
-- We'll include all except:
--		a) The current app
--		b) Apps that are not visible (don't show in dock)
--		c) TODO: Apps on the blacklist. (Spam sieve, Free Ruler,...)
-- showingTest(k, v)
-- k:	key, not used
-- v:	value, an application object
function showingTest(k, v)
	-- Only those in dock (i.e. visible), and not current (active) app, and TODO: not "blacklisted" apps
	if frontAppBundleID == tostring(v:bundleID()) then return false end
	return (v:kind() == 1)
end

-- myTable:		the table we want to know how many elements it contains
-- test: 		is an optional callback. Called with k, v (Key value).
--				test returns true for "count this one."
--				If test is nill don't bother with the test, count all elements.
function countTableElements(myTable, test)
  if myTable == nil then return 0 end
  local count = 0
  for k,v in pairs(myTable) do
    if test == nil or test(k, v) then
      count = count + 1
    end
  end
  return count
end

--	Globals---------------------------------------------------------------------------
currentSelDrawing = nil
currentSel = nil
appCount = 0
frontAppBundleID = nil

-- CONSTANTS
-- Icon sizes are nominally 75x75, but easy to vary
-- BG rect is +10 on all 4 sides
CELLWIDTH = 75;
CELLHEIGHT = 75;
bgBoarder = 10;

--------------------------------------------------------------------------------------

--	HyperFn+Tab starts "Switch Application mode."
--	It terminates with switching to an app (space or return), or quitting (Esc)
local switchApp = hs.hotkey.modal.new(HyperFn, 'Tab')

--	Bind keys of interest for switching apps
--	switchApp:bind(mods, key, message, pressedfn, releasedfn, repeatfn) -> hs.hotkey.modal object
switchApp:bind('', 'escape',
	function()
	switchApp:exit() end)
switchApp:bind('', 'return',
	function()
	switchToCurrentApp()
	switchApp:exit()
	end)
switchApp:bind('', 'space',
	function()
		-- If > 1 window allow user to choose which window from list
		-- Bring up app's windows as a hs.chooser list. Up/Down will then be used to select.
		--		Return to choose and open.
		-- 		Esc will just ignore window, but we've already done the App selection.
		listOfApps = hs.application.applicationsForBundleID( appList[currentSel] )
		appWindowList = listOfApps[1]:allWindows()

		if countTableElements(appWindowList) <= 1 then
		  -- nothing more to do... zero, or only 1 window anyway.
		  switchToCurrentApp()
		  switchApp:exit()
		  return
		end
		switchToCurrentApp()
		switchApp:exit()		-- Take down the app switcher, stops intercepting arrow keys so hs.chooser gets them.
		hs.timer.doAfter(0.5, showAppWindows)
--		hs.timer.usleep(100000)
--		showAppWindows()
	end)

-- arrow keys, for switching to a running app
switchApp:bind('', 'left', nil,
	function()
    if currentSel % cellsX ~= 1 then
	    currentSel = math.max(currentSel-1, 1)
	    displaySelRect(currentSel)
	  end
	end)
switchApp:bind('', 'pad4', nil,
	function()
    if currentSel % cellsX ~= 1 then
	    currentSel = math.max(currentSel-1, 1)
	    displaySelRect(currentSel)
	  end
	end)

switchApp:bind('', 'right', nil,
	function()
    if currentSel % cellsX ~= 0 then
  	  currentSel = math.min(currentSel+1, appCount)
  	  displaySelRect(currentSel)
  	end
	end)
switchApp:bind('', 'pad6', nil,
	function()
    if currentSel % cellsX ~= 0 then
  	  currentSel = math.min(currentSel+1, appCount)
  	  displaySelRect(currentSel)
  	end
	end)

-- arrow keys, for switching to a running app, or for choosing a window
switchApp:bind('', 'up', nil,
	function()
    if currentSel > cellsX then
      currentSel = math.max(currentSel-cellsX, 1)
      displaySelRect(currentSel)
    end
	end)
switchApp:bind('', 'pad8', nil,
	function()
    if currentSel > cellsX then
      currentSel = math.max(currentSel-cellsX, 1)
      displaySelRect(currentSel)
    end
	end)

switchApp:bind('', 'down', nil,
	function()
    if currentSel <= cellsX * (cellsY-1) then
      currentSel = math.min(currentSel+cellsX, appCount)
      displaySelRect(currentSel)
    end
	end)
switchApp:bind('', 'pad2', nil,
	function()
    if currentSel <= cellsX * (cellsY-1) then
      currentSel = math.min(currentSel+cellsX, appCount)
      displaySelRect(currentSel)
    end
	end)

-- NW, NE, SW, SE -------------------------------------------
switchApp:bind('', 'pad7', nil,
	function()
	  -- Up, then left
    if currentSel > cellsX then
      currentSel = math.max(currentSel-cellsX, 1)
    end
    if currentSel % cellsX ~= 1 then
	    currentSel = math.max(currentSel-1, 1)
	  end
	  displaySelRect(currentSel)
	end)
switchApp:bind('', 'pad9', nil,
	function()
	  -- Up, then right
    if currentSel > cellsX then
      currentSel = math.max(currentSel-cellsX, 1)
    end
    if currentSel % cellsX ~= 0 then
  	  currentSel = math.min(currentSel+1, appCount)
  	end
	  displaySelRect(currentSel)
	end)
switchApp:bind('', 'pad1', nil,
	function()
	  -- Left, then down
    if currentSel % cellsX ~= 1 then
	    currentSel = math.max(currentSel-1, 1)
	  end
    if currentSel <= cellsX * (cellsY-1) then
      currentSel = math.min(currentSel+cellsX, appCount)
    end
	  displaySelRect(currentSel)
	end)
switchApp:bind('', 'pad3', nil,
	function()
	  -- Right, then down
    if currentSel <= cellsX * (cellsY-1) then
      currentSel = math.min(currentSel+cellsX, appCount)
    end
    if currentSel % cellsX ~= 0 then
  	  currentSel = math.min(currentSel+1, appCount)
  	end
	  displaySelRect(currentSel)
	end)

function switchApp:entered()
  -- Build a grid of app names
  bringUpSwitcher()
end

function switchApp:exited()
  debuglog("***>> exited <<***")
  takeDownSwitcher()
end

function switchToCurrentApp()
	-- Use selected app (indexed by cell number) to switch to, by bundleID
	debuglog("Switching to: "..tostring( appList[currentSel] ))
	hs.application.launchOrFocusByBundleID(appList[currentSel])
end

-- Given a cell number (1 is top-left corner) return a rectangle
-- to encompass the app icon, with a margin. Used to display the selection rectangle outline
function cellNumbToRect(cellNum)
	x = bgX+bgBoarder + ( (cellNum-1) % cellsX) * CELLWIDTH;
	y = bgY+bgBoarder + math.floor((cellNum-1) / cellsX) * CELLHEIGHT;
	return hs.geometry.rect(x, y, CELLWIDTH, CELLHEIGHT);
end

function displaySelRect(cellNum)
	if currentSelDrawing then currentSelDrawing:delete() end	-- remove any existing
	currentSel = cellNum
	selRect = hs.drawing.rectangle(cellNumbToRect(cellNum));
	selRect:setFillColor({["red"]=1.0,["blue"]=1.0,["green"]=1.0,["alpha"]=0.0}):setFill(true)
	selRect:setRoundedRectRadii(5, 5);
	selRect:setStroke(true);
	selRect:setStrokeWidth(6);
    selRect:setStrokeColor({["red"]=0.75,["blue"]=0,["green"]=0,["alpha"]=1})
	selRect:setLevel(hs.drawing.windowLevels["floating"])
	currentSelDrawing = selRect:show()
end

function bringUpSwitcher()
	frontDrawingList = {}	-- track all visual images we add to the screen, for later removal
	appList = {}
	-- TODO: (Maybe) change this to pick the screen with the mouse on it.
	frame = hs.screen.mainScreen():frame()	-- the one containing the currently focused window

	-- Keep track of which app is current
	-- Don't display the current app at all. If user made a mistake and decided not to change
	-- apps <Esc> will cancel.
	frontApp = hs.application.frontmostApplication()
	frontAppBundleID = frontApp:bundleID()
	
	-- Lay them out on the screen as grid
	allApps = hs.application.runningApplications()
	appCount = countTableElements(allApps, showingTest)
	
	-- Compute the matrix squares, say 3 x 3, as needed. Depends on # of apps found
	cellsX = math.ceil(math.sqrt(appCount));
	cellsY = math.ceil(appCount/cellsX);
	cellsHeight = cellsY * CELLHEIGHT;
	cellsWidth  = cellsX * CELLWIDTH;
	-- Once we know the appCount we can create the BG (screened back gray, rectangle)
	-- and later populate it with icons.
	--
	-- Screen coordinates: fame.x and .y may not be at 0,0. Depends on active screen.
	-- Compute the matrix area, say 3 x 3, as needed. Depends on # of apps found
	bgX = frame.x + frame.w/2 - (cellsX*CELLWIDTH/2) - bgBoarder;
	bgY = frame.y + frame.h/2 - CELLHEIGHT/2 - bgBoarder;
	
	-- Create on-screen BG rectangle
	bgRect = hs.drawing.rectangle(hs.geometry.rect(bgX, bgY, cellsWidth+2*bgBoarder, cellsHeight+2*bgBoarder))
	bgRect:setFillColor({["red"]=0.5,["blue"]=0.5,["green"]=0.5,["alpha"]=0.5}):setFill(true)
	bgRect:setRoundedRectRadii(10, 10)
	bgRect:setLevel(hs.drawing.windowLevels["floating"])
	table.insert(frontDrawingList, bgRect:show() )
	
	cnt = 1;
	for index, app in pairs(allApps) do
		-- Only those in dock, except current
		if (app:kind() == 1) and ( frontAppBundleID ~= app:bundleID() )then
			table.insert(appList, app:bundleID() )
			appName = hs.application.nameForBundleID(app:bundleID())
			i = (index)   and index   or "nil";
			a = (appName) and appName or "(none)";
			frontIcon = hs.image.imageFromAppBundle(app:bundleID());
			boxrect   = cellNumbToRect(cnt);
			frontDrawing = hs.drawing.image(boxrect, frontIcon);
			frontDrawing:setLevel(hs.drawing.windowLevels["floating"])	-- above the rest
			table.insert(frontDrawingList, frontDrawing:show() )
			-- TODO: Add text below each app in list. Track it so we can delete when it's time to
			-- tear down the image.
 			-- table.insert(frontDrawingList, some_text_structure )
			cnt = cnt + 1;
		end
	end
	-- Create selection indicator, centered if possible
	column = math.ceil(cellsX/2);
	row    = math.ceil(cellsY/2);
	sumpart = column + (row-1)*cellsX;
--	debuglog("column/row/'sum': "..column.."  "..row.."  "..sumpart)
	displaySelRect(sumpart)
end

function takeDownSwitcher ()
	for _, drawing in pairs(frontDrawingList) do
		drawing:delete()
	end
	if currentSelDrawing then currentSelDrawing:delete() end
end


--------------------------------------------------------------------------------------
--	Chooser for selecting which window.
--------------------------------------------------------------------------------------
-- selectionTable: One object from the chooserChoices list.
-- 		Contains:
--			  ["text"] = displayTitle, shortened as needed
--			  ["winID"] = winID, the unique ID so we can actually manipulate the window.
  function chooserCompletion(selectionTable)
--    debuglog("chooserCompletion selectionTable: "..tostring(selectionTable))
--    debuglog("chooserCompletion title: ".. selectionTable["text"])

    -- Open the requested window, unless user canceled the chooser.
    debuglog("chooserCompletion")
    takeDownChooser()
    if selectionTable ~= nil then
--      debuglog("  text: ".. selectionTable["text"])
	  win = hs.window.get(selectionTable["winID"])
--	  debuglog("  win: ".. tostring(win))
	  win:becomeMain()
	  win:focus()
	end

  end
  function takeDownChooser()
    debuglog("takeDownChooser")
    myChooser:delete()
  end


  function bringUpChooser(chooserChoices)
    --
    debuglog("bringUpChooser")
    myChooser = hs.chooser.new(chooserCompletion)	
    myChooser:choices(chooserChoices)
	-- Get colors to match Application switcher better
	myChooser:bgDark(false)
    myChooser:fgColor({["red"]=0.3,["blue"]=0.3,["green"]=0.3,["alpha"]=1.0})
    
    myChooser:width(30)		-- 30% of screen width, centered.
    myChooser:rows(countTableElements(chooserChoices))
    myChooser:show()
  end


--------------------------------------------------------------------------------------
--	Show Current Windows HyperFn-`
--------------------------------------------------------------------------------------
  function showAppWindows()
	-- If > 0 window allow user to choose which window from list
	-- Bring up app's windows as a hs.chooser list. Up/Down will then be used to select.
	--		Return to choose and open.
	-- 		Esc will just ignore window.
	appWindowList = hs.application.frontmostApplication():allWindows()

	if countTableElements(appWindowList) <= 0 then
	    -- nothing more to do... no windows
	    hs.alert("No windows in active application")
	  return
	end
--	debuglog("# of windows: "..countTableElements(appWindowList))
	chooserChoices = {}
	local count = 0
	for k,v in pairs(appWindowList) do
	  realTitle = appWindowList[k]:title()
	  -- Skip empty titles
	  if realTitle ~= nil and realTitle ~= "" then
		  winID = appWindowList[k]:id()
		  displayTitle = (realTitle == "") and "(no title)" or appWindowList[k]:title()
		  displayTitle = string.gsub(displayTitle, "/.*/", "")		-- strip off path, if present (NoteTaker App)
--		  debuglog(tostring(k).." -- ".. realTitle .." -- ".. displayTitle)

		  table.insert(chooserChoices,
			{
			  ["text"] = displayTitle,
			  ["winID"] = winID
			}
		  )
		  count = count + 1
	  end
	end
	if count <= 0 then
	    -- nothing more to do... no named windows
	    hs.alert("No windows in active application.")
	  return
	end
	if count <= 1 then
	    -- nothing to choose... select the only non-empty window.
	    hs.alert("Selecting the only available window")
	    win = hs.window.get(chooserChoices[1]["winID"])
--	    debuglog("  win: ".. tostring(win).."     "..chooserChoices[1]["text"])
	    win:becomeMain()
	    win:focus()
	  return
	end
	-- once it's built...
	bringUpChooser(chooserChoices)

  end
  hs.hotkey.bind(HyperFn,'`',nil, showAppWindows)




if false then
function makeSwitcher()
  myUI = {
  ["textColor"] = {0,1,0},
  ["onlyActiveApplication"] = true,
  ["showThumbnails"] = false,
  ["showSelectedThumbnail"] = false,
  ["selectedThumbnailSize"] = 128,
  }
  wf = hs.window.filter.new("BBEdit")
  switcher = hs.window.switcher.new(wf, myUI) -- default windowfilter: only visible windows, all Spaces
  switcher:next()
--  switcher:previous()
--  switcher_space = hs.window.switcher.new(hs.window.filter.new():setCurrentSpace(true):setDefaultFilter{}) -- include minimized/hidden windows, current Space only
--  switcher_browsers = hs.window.switcher.new{'Safari','Google Chrome'} -- specialized switcher for your dozens of browser windows :)
end

  -- bind to hotkeys; WARNING: at least one modifier key is required!
  hs.hotkey.bind('alt','tab','Show Window Switcher',function() makeSwitcher() end)


end
-- SH-268 design.
-- SH-579 / 580
-- credentials:
--		u/p: alice@wonderland.com / aspera
--		bo3b@example.com / 456 rty (Bo3b jones)
--		email: bruceb@earthreflections.com		pw: 456 rty		(Name: Org_Admin OS_Org)
--		email: bbarrett@asperasoft.com			pw: 456 rty		(Name: Project_Admin Touch_Project)
--		host: https://shares2-ci.aspera.us
--		https://shares2.aspera.us/

return switchApplications
