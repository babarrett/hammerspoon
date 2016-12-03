-- Launch Applications
-- (TODO: Can also be used for websites)
-- TODO: Send up, down, left, right changes to web page as
--	Javascript to increase speed over page load. Maybe something
--	like: changeSelectionFromTo(fromCell, toCell)
-- Displays a NxM grid of App names and short-cut letters
-- User can use arrow keys to select an app to switch to, 
-- Enter or Space to switch. Or may use short-cut letters
-- to switch. Or Escape to cancel.
-- by: Bruce Barrett

launchApplications2 = {}
-- Operation:
--	HyperFn+A to enter "Application mode"
--	arrow keys to select an app to switch to.
--	Enter or Space to switch.
--	<single key> to launch an application
--	To leave "Application mode" without launching an application press Escape.

local DEFAULTBROWSER = 'Safari'
local webPageView = nil

-- Format is:
--   Key_to_press. A single key
--   Object with up to 3 items:
--     DisplayText
--     App to launch, or nil
--     Web site to open, or nil TODDO: Actually support the web-site option
local appShortCuts = {
    B = {'BBEdit', 'BBEdit', nil},
    C = {'Chrome', 'Google Chrome', nil},
    F = {'Finder', 'Finder', nil},
    
    I = {'iTerm', 'iTerm', nil},
    M = {'Mail', 'Mail', nil},
    N = {'Notetaker', 'Notetaker', nil},
    
    O = {'Oxygen', 'Oxygen XML Author', nil},
    R = {'Remote Desktop', 'Microsoftt Remote Desktop', nil}, 
    P = {'System Preferences', 'System Preferences', nil},
    
    S = {'Safari', 'Safari', nil},
    T = {'Tunnelblick', 'Tunnelblick', nil},
    X = {'Firefox', 'Firefox', nil},
}

-- Build a 3x4 grid of app names
local xmin =0
local xmax =2
local ymin =0
local ymax =3

local xsel
local ysel

local launchAppActive = nil		-- Inactive

local modalKey = hs.hotkey.modal.new(HyperFn, 'A')
--	Bind keys of interest
--	hs.hotkey.modal:bind(mods, key, message, pressedfn, releasedfn, repeatfn) -> hs.hotkey.modal object

-- Completion keys
	modalKey:bind('', 'escape', 
		function() 
		launchAppActive = nil
		debuglog("Escape")
		modalKey:exit() end)
	modalKey:bind('', 'space',  
		function() 
		launchAppActive = nil
		debuglog("Space")
		launchAppBySelection()
		modalKey:exit() end)
	modalKey:bind('', 'return',  
		function() 
		launchAppActive = nil
		debuglog("Return")
		launchAppBySelection()
		modalKey:exit() end)

-- arrow keys
	-- insert jikl or wasd as arrow keys here too, if you wish.
	-- better yet, just map them as you usually would and they'll
	-- pass through here anyway.
	modalKey:bind('', 'left', nil, 
		function() 
		debuglog("Left")
		xsel = math.max(xmin, xsel-1)
		reloadWebPage()
		end)
	modalKey:bind('', 'right', nil, 
		function() 
		debuglog("Right")
		xsel = math.min(xmax, xsel+1)
		reloadWebPage()
		end)
	modalKey:bind('', 'up', nil, 
		function() 
		debuglog("Up")
		ysel = math.max(ymin, ysel-1)
		reloadWebPage()
		end)
	modalKey:bind('', 'down', nil, 
		function() 
		debuglog("Down")
		ysel = math.min(ymax, ysel+1)
		reloadWebPage()
		end)


-- App launch keys (defined in appShortCuts)
-- Pick up Applications to offer, sorted by activation key
for key, appInfo in hs.fnutils.sortByKeys(appShortCuts) do
    -- TODO: Test App for nil and Web site for != nil, open website instead
    modalKey:bind('', key, 'Launching '..appInfo[2], 
      function() hs.application.launchOrFocus(appInfo[2]) end,	-- Key down, launch
      function() modalKey:exit() end)							-- Key up, leave mode
end

function modalKey:entered() 
  xsel = math.floor((xmax-xmin)/2)
  ysel = math.floor((ymax-ymin)/2)
  reloadWebPage()
end

function modalKey:exited() 
  -- Take down App selector
  if webPageView ~= nil then
    webPageView:delete()
    webPageView=nil
  end
  debuglog("LaunchApp2 exited")
end

function launchAppBySelection()
  -- which index, based  on (x, y) cell selected
  index = ysel * (xmax+1) + xsel
  debuglog("(x, y) -- index= (" .. xsel .. ", " .. ysel .. ") -- " .. index)
  for key, appInfo in hs.fnutils.sortByKeys(appShortCuts) do
    if index == 0 then
      app = appInfo[2]
    end
    index = index -1
  end
  if app ~= nil then
    hs.alert.show('Launching... '..app)
    hs.application.launchOrFocus(app)
  end
end

function reloadWebPage()
  if webPageView then
  -- if it exists, refresh it
	debuglog("Refresh web page")
    webPageView:html(generateHtml())
  else
  -- if it doesn't exist, make it
	debuglog("Create new web page")
	webPageView = hs.webview.new({x = 200, y = 200, w = 650, h = 350}, { developerExtrasEnabled = false, suppressesIncrementalRendering = false })
	:windowStyle("utility")
	:closeOnEscape(true)
	:html(generateHtml())
	:allowGestures(false)
	:windowTitle("Launch Applicatiion Mode")
	:show()
	-- These 2 lines were commented out. Don"t seem to help
	-- webPageView:asHSWindow():focus()
	-- webPageView:asHSDrawing():setAlpha(.98):bringToFront()
	webPageView:bringToFront()
  
  end
  
end

function generateHtml()
    --local focusedApp= hs.window.frontmostWindow():application()
    local focusedApp = hs.application.frontmostApplication()
    local appTitle = focusedApp:title()
    local allMenuItems = focusedApp:getMenuItems();
    local myMenuItems = getAllMenuItems(allMenuItems)

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
              position: fixed;
              top: 0;
              left: 0;
              right: 0;
              height:30px;
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
              <div class="title"><strong>Launch Application Mode</strong></div>
            </header>

          </body>
        </html><br>
		Use arrow keys to select App to launch.<br>
		Space or return to launch.<br>
		Esc to Cancel.
		<div id="container">
		<table id="selTable" width="90%"  border="3">
		]]..generateTable()..[[
		</table>
	</div>
	<div>
		Selected cell = <span id="selCell">selected cell goes here</span>.
	</div>

        ]]
    -- Adding this will dump the HTML to the console where it can be copied, if desired.
    -- hs.console.printStyledtext( html )
    return html
end

function generateTable()
	jumpChars = {"M", "S", "C", "X", "I", "F", "P", "B", "N"}
	appNmaes  = {"Mail", "Safari", "Chrome", "Firefox", "iTerm", "Finder", "System Prefs", "BBedit", "Notetaker" }
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

return launchApplications2
