-- Report Layer Modifier Change
-- Bruce's Ergodox keyboard will generate a sequence starting with F14 
-- and ending with <return> when a layer or modifier change is noted.
-- This Hammmerspoon code will detect and interpret those "keys" and
-- display the current state in a "heads up display"
-- by: Bruce Barrett

reportLayerModifierChange = {}
-- Operation:
--	Notice the F14 key and enter the tracking mode
--	set addDelete global to "add"
--	Loop, listening for characters until <return> is received.
--		when "+" is received set addDelete global to "add"
--		when "-" is received set addDelete global to "delete"
--		Handle Mod changes
--		when "A" is received set modShift to "true" (or "false" if addDelete == "delete")
--		when "B" is received set modControl
--		when "C" is received set modOption
--		when "D" is received set modCommand
--		when "X" is received close down window
--		Handle Layer changes
--		when "0" to "9" is received set layer to:
--		0 = Base
--		1 = Numeric
--		2 = Nav/Pnct
--		3 = SpaceFn
--		4 = Layer 4, etc.

local HUD = nil
local HUDView
local addDelete = "add"					-- I'm not crazy about globals, but this simplifies the code
local modShift		= false
local modControl	= false
local modOption		= false
local modCommand	= false

local keyList = { 
		en = "return", mi = "-", -- and later, "+"
		A = "A", B = "B", C = "C", D = "D", X = "X",
		f = "0", g = "1", h = "2", i = "3", j = "4", 
		k = "5", l = "6", m = "7", n = "8", o = "9"
		}
layerNames = {
	"Numeric",
	"Nav/Pnct",
	"SpaceFn",
	"Layer 4",
	"Layer 5",
	"Layer 6",
	"Layer 7",
	"Layer 8",
	"Layer 9",
}
layerNames[0] = "Base"
layerName = layerNames[0]	-- default start

--	HyperFn+F14 starts "Report Layer Modifier Change mode."
--	It terminates with <return>
local LayerModifierKey = hs.hotkey.modal.new(HyperFn, 'F12')

-- Map all keys of interest to processing routine
-- Pick up Applications to offer, sorted by activation key
for key, val in hs.fnutils.sortByKeys(keyList) do
	-- debuglog( "Key="..key.."  val="..tostring(val).."  table val=".. tostring(keyList[key]))
	LayerModifierKey:bind('', val, nil, 
	  function()
		processChar(val)
	  end)							-- Key up, leave mode
end

-- plus as shift+'=' for is a plus (+).
LayerModifierKey:bind('{shift}', "=", nil, 
  function()
		processChar("+")
  end)							-- Key up, leave mode

-- OK, this is the real work
--		when "+" is received set addDelete global to "add"
--		when "-" is received set addDelete global to "delete"
--		Handle Mod changes
--		when "A" is received set modShift to "true" (or "false" if addDelete == "delete")
--		when "B" is received set modControl
--		when "C" is received set modOption
--		when "D" is received set modCommand
--		Handle Layer changes
--		when "0" to "9" is received set layer to:
--		0 = Base
--		1 = Numeric
--		2 = Nav/Pnct
--		3 = SpaceFn
--		4 = Layer 4, etc.
function processChar(val)
  debuglog("caught a: "..val)
  if       val == "A" then modShift = (addDelete == "add")
    elseif val == "B" then modControl = (addDelete == "add")
    elseif val == "C" then modOption = (addDelete == "add")
    elseif val == "D" then modCommand = (addDelete == "add")
    elseif val == "E" then modCommand = (addDelete == "add")
    elseif (val >= "0") and (val <= "9") then layerName = layerNames[tonumber(val)]
    elseif val == "+" then addDelete = "add"
    elseif val == "-" then addDelete = "delete"
    elseif val == "X" then tearDown()
    elseif val == "return" then updateHUD()
  end
  debuglog("Layer: ".. layerName.. "  Add/Delete: ".. addDelete..  "   Shift: ".. tostring(modShift))
end

function tearDown()
  if HUDView then
    debuglog("Tear down HUD view.")
    HUDView:delete()
    HUDView=nil
  end
  LayerModifierKey:exit()
end

function updateHUD()
  if HUDView then
  -- if it exists, refresh it
	debuglog("Refresh HUD display")
    HUDView:html(reportLayerModifierChange.generateHtml())
  else
  -- if it doesn't exist, make it
	debuglog("Create new HUD display")
	local screen = hs.screen.primaryScreen()
	local sf = screen:frame()
	
	xLoc = sf.w - 300
	yLoc = sf.h - 100
	wide = 200
	high = 90

	HUDView = hs.webview.new({x = xLoc, y = yLoc, w = wide, h = high}, 
		{ developerExtrasEnabled = false, suppressesIncrementalRendering = false })
	:windowStyle("utility")
	:closeOnEscape(false)
	:html(reportLayerModifierChange.generateHtml())
	:allowGestures(false)
	:windowTitle("Launch Applicatiion Mode")
	:show()
	:alpha(.50)
	--	:transparent(true) 
	-- These 2 lines were commented out. Don't seem to help
	-- pickerView:asHSWindow():focus()
	-- pickerView:asHSDrawing():setAlpha(.98):bringToFront()
	HUDView:bringToFront()
  
  end
  LayerModifierKey:exit()
  
end

function reportLayerModifierChange.generateHtml()
    local html = [[
        <!DOCTYPE html>
        <html>
        <head>
        <style type="text/css">
            html, body{ 
              background-color:#404040;
              font-family: arial;
              font-size: 13px;
            }

			body {
			   margin: 5px;
			   background-color: #404040;
			   color: #c0c0c0;
			   width: 250px;
			   font-family: "HelveticaNeue-Light", "Helvetica Neue Light",
				  "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
			   font-weight: bold;
			   font-size: 200%;
			   
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
        </head>
          <body>
            <header>
              <div>]]..layerName..[[<br>]]..
				((modShift  ) and "⇧" or "&nbsp;&nbsp;") ..
				((modControl) and "⋏" or  "&nbsp;") ..
				((modOption ) and "⌥" or "&nbsp;&nbsp;&nbsp;") ..
				((modCommand) and "⌘" or "&nbsp;&nbsp;&nbsp;&nbsp;") ..
				[[<br>
              </div>
            </header>

          </body>
        </html><br>

     ]]
     return html
end


return reportLayerModifierChange
