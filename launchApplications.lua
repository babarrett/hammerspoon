-- Launch Applications (or web pages)
-- Displays a NxM grid of App names and short-cut letters
-- User can use arrow keys to select an app to switch to, 
-- Enter or Space to switch. Or may use short-cut letters
-- to switch. Or Escape to cancel.
-- by: Bruce Barrett

launchApplications = {}
-- Operation:
--	HyperFn+A to enter "Application mode"
--	arrow keys to select an app to switch to.
--	Enter or Space to switch.
--	<single key> to launch an application
--	To leave "Application mode" without launching an application press Escape.

--	TODO: Send up, down, left, right changes to Hammerspoon web page as
--		Javascript to increase speed over page load. Maybe something
--		like: changeSelectionFromTo(fromCell, toCell) to move a covering rectangle
--	TODO: <Tab> to move to part of table that doesn't have single-character hotkey launch.
--	TODO: Support NW, NE, SW, SE "arrow keys" for navigating App/Webpage grids. Makes for fewer keystrokes required.
--	TODO: Go totally wild and support a 3rd dimension. Could access 3x3x3=27 entries w/ 2 arrow key presses, or 5x5x5=125 entries with 4 arrow keys
--	TODO: "Merge" hot key behavior
--			1. (done) still have 2 tables, appShortCuts and webShortCuts
--			2. reduce modalAppKey & modalWebKey bindings to 1 table. When both tables use the same keys stroke (or always?)
--				callout to Handle(key) which will pick the right behavior based upon the global, including "do nothing"
--				if the current "mode" does not have that key defined.
--			3. Need to handle "Space" and "Return" in a similar way.

local DEFAULTBROWSER = 'Safari'
local pickerView = nil
inMode = nil					-- I'm not crazy about globals, but this really simplified the code

-- Format is:
--   Key_to_press. A single key
--   Object with up to 3 items:
--     DisplayText
--     App to launch, or bundleID, or nil
--     Web site to open, or nil TODDO: Actually support the web-site option
local appShortCuts = {
	-- "/Users/bbarrett/" works, but "~/" does not. :-(
	-- hs.application.launchOrFocusByBundleID("com.aspera.connect") works.
	-- Use Z# to support entries without the 1 character (hot key) shortcuts
	--	Multi char strings?
    A = {'Connect', 'com.aspera.connect', nil}, -- > hs.application.bundleID(hs.application.applicationForPID(58463)) --> com.aspera.connect
    B = {'BBEdit', 'BBEdit', nil},
    C = {'Chrome', 'Google Chrome', nil},

    F = {'Finder', 'Finder', nil},
    G = {'OmniGraffle', 'OmniGraffle', nil},
    I = {'iTerm', 'iTerm', nil},

    J = {'Notes', 'Notes', nil},
    M = {'Mail', 'Mail', nil},
    N = {'Notetaker', 'Notetaker', nil},

    P = {'System Preferences', 'System Preferences', nil},
    R = {'Remote Desktop', '/Applications/Microsoft Remote Desktop.app/', nil}, -- > hs.application.nameForBundleID("com.microsoft.rdc.mac") --> "Microsoft Remote Desktop"
	S = {"Secure DMG","/Users/bbarrett/Secure.dmg & open /Users/bruce/Secure.dmg",nil},	-- open Secure.dmg either at work or at home.

    T = {'Tunnelblick', 'Tunnelblick', nil},
    V = {'IBM VPN', 'Cisco AnyConnect Secure Mobility Client', nil},
    X = {'Firefox', 'Firefox', nil},

	-- Using Zaa so it sorts after the 1-character shortcuts. 
	-- Nothing "sacred" about # of characters in name
	-- Zaa sorts before Zbb so we can keep these in order as we like
    Zad = {'Adobe Reader', 'Adobe Reader', nil},
    Zca = {'Calendar', 'Calendar', nil},
    Zit = {'iTunes', 'iTunes', nil},
    Znu = {'Numbers', 'Numbers', nil},
    Zpa = {'Pages', 'Pages', nil},
    Zpr = {'Preview', 'Preview', nil},
}

local webShortCuts = {

    A = {"Aspera Support", nil, "https://aspera.zendesk.com/agent/dashboard"},
    B = {"Bluepages", nil, "Bluepages"},
    C = {"Confluence Connect", nil, "https://confluence.aspera.us/display/CON/Connect+Browser+Plug-in+Home"},

    D = {"Google Docs", nil, "https://docs.google.com/document/u/0/?tgif=c"},
    F = {"Google Hangouts", nil, "https://hangouts.google.com/"},
    G = {"Google Drive", nil, "https://drive.google.com/drive/my-drive"},

    H = {"Home", nil, "http://brucebarrett.com/browserhome/brucehome.html"},
    J = {"Jira ASCN", nil, "https://jira.aspera.us/projects/ASCN?selectedItem=com.atlassian.jira.jira-projects-plugin%3Arelease-page&status=no-filter"},
    K = {"KLE", nil, "http://www.keyboard-layout-editor.com"},

    L = {"Aspera Downlads", nil, "http://downloads.asperasoft.com"},
    M = {"IBM Mail", nil, "IBM Mail"},
    N = {"ADN", nil, "https://developer.asperasoft.com"},

    O = {"Trac, Old bugs", nil, "https://trac.aspera.us"},
    S = {"Google Sheets", nil, "https://sheets.google.com"},
    T = {"Confluence TP", nil, "https://confluence.aspera.us/display/TP/Technical+Publications"},

	W = {"Geekhack", nil, "https://geekhack.org/index.php?action=watched"},		-- Geekhack, Watched
}

function countTableElements(myTable)
  local count = 0
  for k,v in pairs(myTable) do
    count = count + 1
  end
  return count
end

-- TODO: support special terminal commands for development (git, pushd, cd,...), someday
local developmentShortCuts = {
	A = {"cd algernon-master", nil, nil},
	B = {"cd bruce-ergodox", nil, nil},
	C = {"cd ~/dev/git/qmk_firmware & make keyboard=ergodox keymap=bbarrett", nil, nil}

}


--	HyperFn+A starts "Launch Application mode."
--	It terminates with selection an app, or <Esc>
local modalAppKey = hs.hotkey.modal.new(HyperFn, 'A')

--	HyperFn+W starts "Launch Webpage mode."
--	It terminates with selection a web page, or <Esc>
local modalWebKey = hs.hotkey.modal.new(HyperFn, 'W')

--	Bind keys of interest, both Apps and Web Pages
--	hs.hotkey.modal:bind(mods, key, message, pressedfn, releasedfn, repeatfn) -> hs.hotkey.modal object
for index, modalKey in pairs({modalAppKey, modalWebKey}) do
	modalKey:bind('', 'escape', 
		function() 
		modalKey:exit() end)
	modalKey:bind('', 'space',  
		function() 
		launchAppOrWebBySelection()
		modalKey:exit() end)
	modalKey:bind('', 'return',  
		function() 
		launchAppOrWebBySelection()
		modalKey:exit() end)


-- arrow keys, app & web
	-- insert jikl or wasd as arrow keys here too, if you wish.
	-- better yet, just map them as you usually would and they'll
	-- pass through here anyway.
	modalKey:bind('', 'left', nil, 
		function() 
		xsel = math.max(xmin, xsel-1)
		reloadPicker()
		end)
	modalKey:bind('', 'right', nil, 
		function() 
		xsel = math.min(xmax, xsel+1)
		reloadPicker()
		end)
	modalKey:bind('', 'up', nil, 
		function() 
		ysel = math.max(ymin, ysel-1)
		reloadPicker()
		end)
	modalKey:bind('', 'down', nil, 
		function() 
		ysel = math.min(ymax, ysel+1)
		reloadPicker()
		end)

end



-- App launch keys (defined in appShortCuts)
-- Pick up Applications to offer, sorted by activation key
for key, appInfo in hs.fnutils.sortByKeys(appShortCuts) do
	if string.len(key) == 1 then
		modalAppKey:bind('', key, 'Launching '..appInfo[1], 
		  function()
			launchAppOrWeb(appInfo[2])
		  end,
		  function() modalAppKey:exit() end)							-- Key up, leave mode
	  end
end

-- Web launch keys (defined in webShortCuts)
-- Pick up Web pages to offer, sorted by activation key
for key, webInfo in hs.fnutils.sortByKeys(webShortCuts) do
    modalWebKey:bind('', key, 'Opening page: '..webInfo[1], 
      function()
      	launchAppOrWeb(webInfo[3])
      	-- hs.execute("open " .. webInfo[3])
      end,	-- Key down, launch
      function() modalWebKey:exit() end)							-- Key up, leave mode
end

function modalAppKey:entered()
  -- Build a grid of app names
  inMode = "App"
  centerAndShowPicker(appShortCuts)
end

function modalWebKey:entered()
  -- Build a grid of web names
  inMode = "Web"
  centerAndShowPicker(webShortCuts)
end

-- Move cursor to "center" and load "web page picker:
function centerAndShowPicker(pickerTable)
  -- TODO: Re-do these with '1'-based indexing.
  -- Select, approximately, the center cell of the App array
  xmin =0
  xmax =2
  ymin =0
  
  -- Dynamically size # of rows (Y) based upon # of entries in table. Using a fixed 3 columns
  tc = countTableElements(pickerTable)
  ymax =math.ceil(tc / 3) -1
  
  xsel = math.floor((xmax-xmin)/2)
  ysel = math.floor((ymax-ymin)/2)
  reloadPicker()
end

function modalAppKey:exited() 
  -- Take down App selector
  takeDownPicker()
end


function modalWebKey:exited() 
  -- Take down App selector
  takeDownPicker()
end

function takeDownPicker()
  if pickerView ~= nil then
    pickerView:delete()
    pickerView=nil
  end
  inMode = nil
end

function launchAppOrWebBySelection()
  app = nil
  -- which index, based  on (x, y) cell was selected
  index = ysel * (xmax+1) + xsel
--  debuglog("LaunchType: "..   inMode .."; (x, y) -- index= (" .. xsel .. ", " .. ysel .. ") -- " .. index)
  dataTable =  (inMode == "App") and appShortCuts or webShortCuts;
  for key, appInfo in hs.fnutils.sortByKeys(dataTable) do
    if index == 0 then
	  if (inMode == "App") then
		app = appInfo[2]
	  else
		app = appInfo[3]
	  end
	end
    index = index -1
  end
  
  launchAppOrWeb(app)
end

-- TODO: Merge/replace with f() of the same name in file: bindFunctionKeys.lua
function launchAppOrWeb(app)
  if inMode == "App" then
    -- hs.alert.show('Launching app... '..app)
	  status = hs.application.launchOrFocus(app)
	  if (not status) then
		  status = hs.application.launchOrFocusByBundleID(app)	-- use BundleID ("com.aspera.connect") if App name fails
		  if (not status) then
		    output, status = hs.execute("open " .. app)
		  end
		end
  else
    -- Opening webpage, instead of app
    hs.execute("open " .. app)
  end
end


function reloadPicker()
  if pickerView then
  -- if it exists, refresh it
    pickerView:html(launchApplications.generateHtml())
  else
  -- if it doesn't exist, make it
	pickerView = hs.webview.new({x = 200, y = 200, w = 650, h = 350}, { developerExtrasEnabled = false, suppressesIncrementalRendering = false })
	:windowStyle("utility")
	:closeOnEscape(true)
	:html(launchApplications.generateHtml())
	:allowGestures(false)
	:windowTitle("Launch Applicatiion Mode")
	:show()
	-- These 2 lines were commented out. Don't seem to help
	-- pickerView:asHSWindow():focus()
	-- pickerView:asHSDrawing():setAlpha(.98):bringToFront()
	pickerView:bringToFront()
  
  end
  
end

function launchApplications.generateHtml()
	local instructions
	if (  inMode == "App") then
		instructions = {"App", "Application"}
	else
		instructions = {"Webpage", "Webpage"}
	end
    local html = [[
        <!DOCTYPE html>
        <html>
        <head>
        <style type="text/css">
            *{margin:10; padding:10;}
            html, body{ 
              background-color:#404040;
              font-family: arial;
              font-size: 13px;
            }
            header{
              <!-- position: fixed; -->
              top: 0;
              left: 0;
              right: 0;
              height:90px;
              background-color:#aab;
              color:#000000;
              z-index:99;
            }
            .title{
                padding: 15px;
            }

			body {
			   margin: 10px; padding: 10px;
			   background-color: #404040;
			   color: #c0c0c0;
			   width: 600px;
			   margin: auto;
			   font-family: "HelveticaNeue-Light", "Helvetica Neue Light",
				  "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
			   font-weight: normal;
			}

			.jumpchar {
				color: #ffff00;
			}
			.unsel {
				color: #88ff80;
				font-weight: 900;
			}
			.sel {
				color: #ff0000;
				font-weight: 900;
				background-color: #ffffff;
			}
        </style>
        <title>Launch Application Mode</title>
        </head>
          <body>
            <header>
              <div class="title"><strong>Launch ]]..instructions[2]..[[ Mode</strong><br>
				Use arrow keys to select ]]..instructions[1]..[[ to launch.<br>
				Space or return to launch.<br>
				Esc to Cancel.
              </div>
            </header>

          </body>
        </html><br>
		<div id="container">
		<table id="selTable" width="90%"  border="1">
		]]..generateAppOrWebTable()..[[
		</table>
	</div>
	<div>
		<!-- Selected cell = <span id="selCell">selected cell goes here</span>. -->
	</div>

        ]]
    -- Adding this will dump the HTML to the console where it can be copied, if desired.
    -- hs.console.printStyledtext( html )
    return html
end

function generateAppOrWebTable()
    local tableText =  "<tr>"

	local x = 0;
	local y = 0;
	local i = 0;
	
	for key, appInfo in hs.fnutils.sortByKeys((inMode == "App") and appShortCuts or webShortCuts) do
		tableText = tableText .. "<td class = 'jumpchar' width='5%' align='right'>" .. 
			((string.len(key) == 1) and key..":" or "&nbsp;");	-- skip entries we don't want to use with 1 character (hot key) shortcuts
		tableText = tableText .. "<td class="
		
		tableText = tableText .. ((x==xsel and y==ysel) and "'sel'" or "'unsel'")

		tableText = tableText .. " width='22%'>" .. appInfo[1] .. "</td>";
		
		x = x + 1
		if x > xmax then
			-- end tr
			tableText = tableText .. "</tr>\n<tr>"
			x = xmin
			y = y + 1
		end

	end
	-- Fill the rest of the last row with &nbsp; in cells for cleaner display.
	if x > xmin then
	  for i=xmax, x, -1 do
		tableText = tableText .. "<td class = 'jumpchar' width='5%' align='right'>&nbsp;";
		tableText = tableText .. "<td class='unsel' width='22%'>&nbsp;</td>";
	  end
	end
    return tableText
end


--Another idea of interest...
--Application picker, like Cmd+Tab but instead:
--* A GUI, in a matrix of some sort
--* App images fill the matrix
--* The matrix may be sparse. Maybe more like a cross than a complete grid
--* Allow up, down, left, right to select;
--* Allow NW, NE, SW, SE too; 
--* Bring up on active window. Centered?
--* (Later) Allow click to launch; Bring the matrix up "under" the current mouse location.
--* Only currently running apps
--* (Later) Track the time spent *active* in each running app, and/or the number of times switched into.
--		Use that to prioritize the running programs to reduce the number of navigation events 
--		to get to the "most used" apps
--* Space to select app we navigated to
--* (Later) "Badge" each app with number of open windows
--* (Later) Use Return key to present open window selection for app we navigated to
--* Use {some_modifier_or_combo, maybe Hyper}+ Right Arrow to activate this mode.
--    This way you finger is already on the right arrow and selecting center or next 2 right
--    Apps requires no finger movement.
--
-- Possible matrix: (# represent # of Key strokes not counting Hyper+Lead to start and <space> to select)
--  9 apps in 0 or 1 key strokes;
-- 14 apps in 2 key strokes;
-- 25 apps in <= 2 keystrokes
--			 Allow	
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
--			  Allow
--			Horiz+Vert
--              2  
--             212 
--            21012
--             212 
--              2  
--
-- Kindred soles:
--		https://tomdebruijn.com/posts/super-fast-application-switching/
--		http://applehelpwriter.com/
--		https://botbot.me/freenode/hammerspoon/2017-05-01/?tz=America/Los_Angeles
--			i notice that `hs.image.imageFromAppBundle('lol') returns a generic icon
--	hs.application.frontmostApplication() -> hs.application object
--  hs.application:bundleID() -> string
--  hs.drawing.image(sizeRect, imageData) -> drawingObject or nil
--  
-- Test by showing current Apps icons:	Works!!

if true then
	-- TODO: Maybe, change this to pick the screen with the mouse on it.
	frame = hs.screen.mainScreen():frame()	-- the one containing the currently focused window

	-- TODO: keep track of which one is current
	-- TODO: Lay them out on the screen as grid
	-- TODO: Remove them after 5 sec.
	appList = hs.application.runningApplications()
	count = 0
	for index, app in pairs(appList) do
		-- Only those in dock
		if app:kind() == 1 then
			count = count + 1
		end
	end
	-- TODO: Once we know the count we can create the BG (screened back gray, right shape)
	-- TODO: and later populate it with icons.
	-- appList = hs.application.runningApplications()
	frontApp = hs.application.frontmostApplication()
	-- frame.x and .y may not be at 0,0
	-- Compute the matrix area, say 3 x 3, as needed.
	startX = frame.x + frame.w/2 - (count*100/2)
	startY = frame.y + frame.h/2 + -50
	frontDrawingList = {}
	debuglog("App List")
	for index, app in pairs(appList) do
		-- Only those in dock
		if app:kind() == 1 then
			appName = hs.application.nameForBundleID(app:bundleID())
			i = (index)   and index   or "nil";
			a = (appName) and appName or "(none)";
			debuglog(tostring(i) ..": ".. a)	-- tostring(app)
			frontIcon = hs.image.imageFromAppBundle(app:bundleID()); 
			boxrect   = hs.geometry.rect(startX, startY, 100, 100)
			frontDrawing = hs.drawing.image(boxrect, frontIcon);
			frontDrawing:setLevel(hs.drawing.windowLevels["floating"])	-- above the rest
			table.insert(frontDrawingList, frontDrawing:show() )
			-- TODO: Add text to the end of the list
			-- hs.drawing.text(textrect[whichText], styleTextext)show()
			-- table.insert(frontDrawingList, some_text_structure )
			startX = startX + 100	-- march across the screen
		end
	end

end

hs.timer.doAfter(5, function ()
		for _, drawing in pairs(frontDrawingList) do
			drawing:delete()
		end
	end
)

return launchApplications


-- SH-268 design.
-- sh-579 / 580
-- credentials:
--		u/p: alice@wonderland.com / aspera
--		bo3b@example.com / b3j (bo3b jones)
--		host: https://shares2-ci.aspera.us
