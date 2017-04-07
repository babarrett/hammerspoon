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
--	TODO: (somehow) support entries that don't have single character hotkeys. Can only reach w/Arrows. Put at start of table?
--	TODO: <Tab> to move to part of table that doesn't have single-character hotkey launch.
--	TODO: Support NW, NE, SW, SE "arrow keys" for navigating App/Webpage grids. Makes for fewer keystrokes required.
--	TODO: Go totally wild and support a 3rd dimension. Could access 3x3x3=27 entries w/ 2 arrow keys, or 5x5x5=125 entries with 4 arrow keys
--	TODO: "Merge" hot key behavior
--			1. still have 2 tables, appShortCuts and webShortCuts
--			2. reduce modalAppKey & modalWebKey bindings to 1 table. When both tables use the same keys stroke (or always?)
--				callout to Handle(key) which will pick the right behavior based upon the global, including "do nothing"
--				if the current "mode" does not have that key defined.
--			3. Need to handle "Space" and "Return" in a similar way.
--	TODO: Support change case of selection

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
	S = {"Secure DMG","/Users/bbarrett/Secure.dmg",nil},
--  S = {'Safari', 'Safari', nil},
    
    T = {'Tunnelblick', 'Tunnelblick', nil},
    X = {'Firefox', 'Firefox', nil},
    Z = {'Numbers', 'Numbers', nil},
    
}

local webShortCuts = {

    A = {"Aspera Support", nil, "https://aspera.zendesk.com/agent/dashboard"},
    B = {"Bluepages", nil, "Bluepages"},
    C = {"Confluence Connect", nil, "https://confluence.aspera.us/display/CON/Connect+Browser+Plug-in+Home"},

    D = {"Google Docs", nil, "https://docs.google.com/document/u/0/?tgif=c"},
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

-- TODO: support case changes too, someday
local changeCaseShortCuts = {
	L = {"To lowercase", nil, nil},
	T = {"To Title Case", nil, nil},
	U = {"To UPPERCASE", nil, nil}

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
		debuglog("Escape")
		modalKey:exit() end)
	modalKey:bind('', 'space',  
		function() 
		debuglog("Space")
		launchAppOrWebBySelection()
		modalKey:exit() end)
	modalKey:bind('', 'return',  
		function() 
		debuglog("Return")
		launchAppOrWebBySelection()
		modalKey:exit() end)


-- arrow keys, app & web
	-- insert jikl or wasd as arrow keys here too, if you wish.
	-- better yet, just map them as you usually would and they'll
	-- pass through here anyway.
	modalKey:bind('', 'left', nil, 
		function() 
		debuglog("Left")
		xsel = math.max(xmin, xsel-1)
		reloadPicker()
		end)
	modalKey:bind('', 'right', nil, 
		function() 
		debuglog("Right")
		xsel = math.min(xmax, xsel+1)
		reloadPicker()
		end)
	modalKey:bind('', 'up', nil, 
		function() 
		debuglog("Up")
		ysel = math.max(ymin, ysel-1)
		reloadPicker()
		end)
	modalKey:bind('', 'down', nil, 
		function() 
		debuglog("Down, a")
		ysel = math.min(ymax, ysel+1)
		reloadPicker()
		end)

end



-- App launch keys (defined in appShortCuts)
-- Pick up Applications to offer, sorted by activation key
for key, appInfo in hs.fnutils.sortByKeys(appShortCuts) do
    modalAppKey:bind('', key, 'Launching '..appInfo[1], 
      function() 
        output, status = hs.execute("open " .. appInfo[2])
        if (status) then	-- if failed, try again
			if (not hs.application.launchOrFocus(appInfo[2])) then
			  hs.application.launchOrFocusByBundleID(appInfo[2])	-- use BundleID ("com.aspera.connect") if App name fails
			end
        end
      end,	-- Key down, launch
      function() modalAppKey:exit() end)							-- Key up, leave mode
end

-- Web launch keys (defined in webShortCuts)
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
  inMode = "App"
  xmin =0
  xmax =2
  ymin =0
  ymax =4

  -- Move cursor to "center" and load "web page picker:
  centerAndShowPicker()
end

function modalWebKey:entered()
  -- Start with proper grid size
  -- Build a 3x4 grid of web names
  -- TODO: Re-do these with '1'-based indexing.
  inMode = "Web"
  xmin =0
  xmax =2
  ymin =0
  ymax =5

  -- Select, approximately, the center cell of the Web array
  xsel = math.floor((xmax-xmin)/2)
  ysel = math.floor((ymax-ymin)/2)
  reloadPicker()
end

function centerAndShowPicker()
  -- Select, approximately, the center cell of the App array
  xsel = math.floor((xmax-xmin)/2)
  ysel = math.floor((ymax-ymin)/2)
  reloadPicker()
end

function modalAppKey:exited() 
  -- Take down App selector
  debuglog("LaunchApp exited")
  takeDownPicker()
end


function modalWebKey:exited() 
  -- Take down App selector
  debuglog("LaunchWebpage exited")
  takeDownPicker()
end

function takeDownPicker()
  if pickerView ~= nil then
    debuglog("pickerView defined")
    pickerView:delete()
    pickerView=nil
  end
  inMode = nil
end

function launchAppOrWebBySelection()
  app = nil
  -- which index, based  on (x, y) cell was selected
  index = ysel * (xmax+1) + xsel
  debuglog("LaunchType: "..   inMode .."; (x, y) -- index= (" .. xsel .. ", " .. ysel .. ") -- " .. index)
  if (inMode == "App") then
  	dataTable = appShortCuts
  else
    dataTable = webShortCuts
--  dataTable =  (inMode == "App") ? appShortCuts : webShortCuts;
  end
  for key, appInfo in hs.fnutils.sortByKeys(dataTable) do
    if index == 0 then
	  if (inMode == "App") then
		app = appInfo[2]
		debuglog("Assigning app: "..app)
	  else
		app = appInfo[3]
		debuglog("Assigning webpage: "..app)
	  end
	end
    index = index -1
  end
  if inMode == "App" then		-- app ~= nil then
    hs.alert.show('Launching app... '..app)
--    hs.application.launchOrFocus(app)
      output, status = hs.execute("open " .. app)
	  if (status) then	-- if failed, try again
		if (not hs.application.launchOrFocus(app)) then
		  hs.application.launchOrFocusByBundleID(app)	-- use BundleID ("com.aspera.connect") if App name fails
		end
	  end
  else
    hs.alert.show('Launching webpage... '..app)
    hs.execute("open " .. app)
    -- hs.application.launchOrFocus(app)
  end
end


function reloadPicker()
  if pickerView then
  -- if it exists, refresh it
	debuglog("Refresh web page")
    pickerView:html(launchApplications.generateHtml())
  else
  -- if it doesn't exist, make it
	debuglog("Create new web page")
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
