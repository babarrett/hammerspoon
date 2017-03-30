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
--	TODO: (somehow) support entries that don't have single character hotkeys. Can only reach w/Arrows
--	TODO: <Tab> to move to part of table that doesn't have single-character hotkey launch.
--	TODO: Support NW, NE, SW, SE "arrow keys" for navigating App/Webpage grids
--	TODO: Set launch type (App, Web) in a global on entered() and simplify the rest of the code (remove much of the duplicate code)
--	TODO: Go totally wild and support a 3rd dimension. Could access 3x3x3=27 entries w/ 2 arrow keys, or 5x5x5=125 entries with 4 arrow keys

local DEFAULTBROWSER = 'Safari'
local webPageView = nil

-- Format is:
--   Key_to_press. A single key
--   Object with up to 3 items:
--     DisplayText
--     App to launch, or bundleID, or nil
--     Web site to open, or nil TODDO: Actually support the web-site option
local appShortCuts = {
	-- "/Users/bbarrett/" works, but "~/" does not. :-(
	-- hs.application.launchOrFocusByBundleID("com.aspera.connect") works.
	-- TODO: Would be nice to be able to add slots in the table that didn't require 1-character (hot key) shortcuts.
    A = {'Connect', 'com.aspera.connect', nil}, -- > hs.application.bundleID(hs.application.applicationForPID(58463)) --> com.aspera.connect
    B = {'BBEdit', 'BBEdit', nil},
    C = {'Chrome', 'Google Chrome', nil},

    F = {'Finder', 'Finder', nil},
    I = {'iTerm', 'iTerm', nil},
    J = {'Notes', 'Notes', nil},

    M = {'Mail', 'Mail', nil},
    N = {'Notetaker', 'Notetaker', nil},
    O = {'Oxygen', 'Oxygen XML Author', nil},

--	P = {'Pages', 'Pages', nil},
	
    P = {'System Preferences', 'System Preferences', nil},
    R = {'Remote Desktop', '/Applications/Microsoft Remote Desktop.app/', nil}, -- > hs.application.nameForBundleID("com.microsoft.rdc.mac") --> "Microsoft Remote Desktop"
    S = {'Safari', 'Safari', nil},
    
    T = {'Tunnelblick', 'Tunnelblick', nil},
    X = {'Firefox', 'Firefox', nil},
    Z = {'Numbers', 'Numbers', nil},
    
}

local webShortCuts = {

    A = {"Aspera Support", nil, "Support.asperasoft.com"},
    B = {"Bluepages", nil, "Bluepages"},
    D = {"Google Docs", nil, "docs.google.com"},

    G = {"Google Drive", nil, "drive.google.com"},
    H = {"Home", nil, "http://brucebarrett.com/browserhome/brucehome.html"},
    J = {"Jira ASCN", nil, "jira.aspera.us"},

    K = {"KLE", nil, "http://www.keyboard-layout-editor.com"},
    L = {"Aspera Downlads", nil, "downlads.asperasoft.com"},
    M = {"IBM Mail", nil, "IBM Mail"},

    N = {"ADN", nil, "developer.asperasoft.com"},
    S = {"Google Sheets", nil, "sheets.google.com"},
    T = {"Confluence TP", nil, "confluence.aspera.us"}

}


--	HyperFn+A starts "Launch Application mode.
--	It terminates with selection an app, or <Esc>
local modalAppKey = hs.hotkey.modal.new(HyperFn, 'A')

--	HyperFn+W starts "Launch Webpage mode.
--	It terminates with selection a web page, or <Esc>
local modalWebKey = hs.hotkey.modal.new(HyperFn, 'W')

--	Bind keys of interest
--	hs.hotkey.modal:bind(mods, key, message, pressedfn, releasedfn, repeatfn) -> hs.hotkey.modal object

-- Completion keys App
	modalAppKey:bind('', 'escape', 
		function() 
		debuglog("Escape")
		modalAppKey:exit() end)
	modalAppKey:bind('', 'space',  
		function() 
		debuglog("Space")
		launchAppOrWebBySelection("App")
		modalAppKey:exit() end)
	modalAppKey:bind('', 'return',  
		function() 
		debuglog("Return")
		launchAppOrWebBySelection("App")
		modalAppKey:exit() end)

-- Completion keys Web
	modalWebKey:bind('', 'escape', 
		function() 
		debuglog("Escape")
		modalWebKey:exit() end)
	modalWebKey:bind('', 'space',  
		function() 
		debuglog("Space")
		launchAppOrWebBySelection("Web")
		modalWebKey:exit() end)
	modalWebKey:bind('', 'return',  
		function() 
		debuglog("Return")
		launchAppOrWebBySelection("Web")
		modalWebKey:exit() end)

-- arrow keys, app
	-- insert jikl or wasd as arrow keys here too, if you wish.
	-- better yet, just map them as you usually would and they'll
	-- pass through here anyway.
	modalAppKey:bind('', 'left', nil, 
		function() 
		debuglog("Left")
		xsel = math.max(xmin, xsel-1)
		reloadWebPage(generateAppTable, "App")
		end)
	modalAppKey:bind('', 'right', nil, 
		function() 
		debuglog("Right")
		xsel = math.min(xmax, xsel+1)
		reloadWebPage(generateAppTable, "App")
		end)
	modalAppKey:bind('', 'up', nil, 
		function() 
		debuglog("Up")
		ysel = math.max(ymin, ysel-1)
		reloadWebPage(generateAppTable, "App")
		end)
	modalAppKey:bind('', 'down', nil, 
		function() 
		debuglog("Down, a")
		ysel = math.min(ymax, ysel+1)
		reloadWebPage(generateAppTable, "App")
		end)

-- arrow keys, Web
	modalWebKey:bind('', 'left', nil, 
		function() 
		debuglog("Left")
		xsel = math.max(xmin, xsel-1)
		reloadWebPage(generateWebTable, "Webpage")
		end)
	modalWebKey:bind('', 'right', nil, 
		function() 
		debuglog("Right")
		xsel = math.min(xmax, xsel+1)
		reloadWebPage(generateWebTable, "Webpage")
		end)
	modalWebKey:bind('', 'up', nil, 
		function() 
		debuglog("Up")
		ysel = math.max(ymin, ysel-1)
		reloadWebPage(generateWebTable, "Webpage")
		end)
	modalWebKey:bind('', 'down', nil, 
		function() 
		debuglog("Down, w")
		ysel = math.min(ymax, ysel+1)
		reloadWebPage(generateWebTable, "Webpage")
		end)


-- App launch keys (defined in appShortCuts)
-- Pick up Applications to offer, sorted by activation key
for key, appInfo in hs.fnutils.sortByKeys(appShortCuts) do
    modalAppKey:bind('', key, 'Launching '..appInfo[1], 
      function() 
        if (not hs.application.launchOrFocus(appInfo[2])) then
          hs.application.launchOrFocusByBundleID(appInfo[2])	-- use BundleID ("com.aspera.connect") if App name fails
        end
      end,	-- Key down, launch
      function() modalAppKey:exit() end)							-- Key up, leave mode
end

-- App launch keys (defined in appShortCuts)
-- Pick up Applications to offer, sorted by activation key
for key, webInfo in hs.fnutils.sortByKeys(webShortCuts) do
    modalWebKey:bind('', key, 'Launching '..webInfo[1], 
      function()
      	hs.execute("open " .. webInfo[3])
      end,	-- Key down, launch
      function() modalWebKey:exit() end)							-- Key up, leave mode
end

function modalAppKey:entered()
  -- Start with proper grid size
  -- Build a 3x5 grid of app names
  -- TODO: Re-do these with '1'-based indexing.
  xmin =0
  xmax =2
  ymin =0
  ymax =4

  -- Select, approximately, the center cell of the App array
  xsel = math.floor((xmax-xmin)/2)
  ysel = math.floor((ymax-ymin)/2)
  reloadWebPage(generateAppTable, "App")
end

function modalWebKey:entered()
  -- Start with proper grid size
  -- Build a 3x4 grid of web names
  -- TODO: Re-do these with '1'-based indexing.
  xmin =0
  xmax =2
  ymin =0
  ymax =3

  -- Select, approximately, the center cell of the App array
  xsel = math.floor((xmax-xmin)/2)
  ysel = math.floor((ymax-ymin)/2)
  reloadWebPage(generateWebTable, "Webpage")
end

function modalAppKey:exited() 
  -- Take down App selector
  if webPageView ~= nil then
    debuglog("webPageView defined")
    webPageView:delete()
    webPageView=nil
  end
  debuglog("LaunchApp exited")
end

function modalWebKey:exited() 
  -- Take down App selector
  if webPageView ~= nil then
    debuglog("webPageView defined")
    webPageView:delete()
    webPageView=nil
  end
  debuglog("LaunchWebpage exited")
end

function launchAppOrWebBySelection(launchType)
  app = nil
  -- which index, based  on (x, y) cell was selected
  index = ysel * (xmax+1) + xsel
  debuglog("LaunchType: ".. launchType .."; (x, y) -- index= (" .. xsel .. ", " .. ysel .. ") -- " .. index)
  if (launchType == "App") then
  	dataTable = appShortCuts
  else
    dataTable = webShortCuts
--  dataTable =  (launchType == "App") ? appShortCuts : webShortCuts;
  end
  for key, appInfo in hs.fnutils.sortByKeys(dataTable) do
    if index == 0 then
				  if (launchType == "App") then
					app = appInfo[2]
					debuglog("Assigning app: "..app)
				  else
					app = appInfo[3]
					debuglog("Assigning webpage: "..app)
				  end
	end
    index = index -1
  end
  if launchType == "App" then		-- app ~= nil then
    hs.alert.show('Launching app... '..app)
    hs.application.launchOrFocus(app)
  else
    hs.alert.show('Launching webpage... '..app)
    hs.execute("open " .. app)
    -- hs.application.launchOrFocus(app)
  end
end

function reloadWebPage(generateTable, appwebtype)
  if webPageView then
  -- if it exists, refresh it
	debuglog("Refresh web page")
    webPageView:html(launchApplications.generateHtml(generateTable, appwebtype))
  else
  -- if it doesn't exist, make it
	debuglog("Create new web page")
	webPageView = hs.webview.new({x = 200, y = 200, w = 650, h = 350}, { developerExtrasEnabled = false, suppressesIncrementalRendering = false })
	:windowStyle("utility")
	:closeOnEscape(true)
	:html(launchApplications.generateHtml(generateTable, appwebtype))
	:allowGestures(false)
	:windowTitle("Launch Applicatiion Mode")
	:show()
	-- These 2 lines were commented out. Don't seem to help
	-- webPageView:asHSWindow():focus()
	-- webPageView:asHSDrawing():setAlpha(.98):bringToFront()
	webPageView:bringToFront()
  
  end
  
end

function launchApplications.generateHtml(whichTable, appwebtype)
	local instructions
	if (appwebtype == "App") then
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
		]]..whichTable()..[[
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

function generateAppTable()
    local tableText =  "<tr>"

	local x = 0;
	local y = 0;
	local i = 0;
	
	for key, appInfo in hs.fnutils.sortByKeys(appShortCuts) do
		tableText = tableText .. "<td class = 'jumpchar' width='5%' align='right'>" .. key ..":";
		tableText = tableText .. "<td class="
		
		if (x==xsel and y==ysel) then 
			tableText = tableText .. "'sel'"
		else
			tableText = tableText ..  "'unsel'"
		end
		tableText = tableText .. " width='22%'>" .. appInfo[1] .. "</td>";
		
		x = x + 1
		if x > xmax then
			-- end tr
			tableText = tableText .. "</tr>\n<tr>"
			x = xmin
			y = y + 1
		end

	end

    return tableText
end

function generateWebTable()
	debuglog("generateWebTable")
    local tableText =  "<tr>"

	local x = 0;
	local y = 0;
	local i = 0;
	
	for key, appInfo in hs.fnutils.sortByKeys(webShortCuts) do
		tableText = tableText .. "<td class = 'jumpchar' width='5%' align='right'>" .. key ..":";
		tableText = tableText .. "<td class="
		
		if (x==xsel and y==ysel) then 
			tableText = tableText .. "'sel'"
		else
			tableText = tableText ..  "'unsel'"
		end
		tableText = tableText .. " width='22%'>" .. appInfo[1] .. "</td>";
		
		x = x + 1
		if x > xmax then
			-- end tr
			tableText = tableText .. "</tr>\n<tr>"
			x = xmin
			y = y + 1
		end

	end

    return tableText
end



return launchApplications
