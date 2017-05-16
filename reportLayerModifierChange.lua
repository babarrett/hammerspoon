-- Report Layer Modifier Change
-- Bruce's Ergodox keyboard will generate an HID sequence starting with "mod: "
-- and ending with <return> when a layer or modifier change is noticed.
-- This Hammerspoon code will detect and interpret that sequence and
-- display the current state in a "heads up display"
-- Cmd+Shift+F12 to start/stop the monitoring and display.
-- by: Bruce Barrett

reportLayerModifierChange = {}

-- On (Report Layer Modifier Change) activate (Cmd+Shift+F12) run the shell command: 
--		if shellTask ~= nil then terminate() else 
--			if neverStarted then 
--				execute /bin/ps And search the results for hid_listen.mac.
--				kill any active IDs (the lines start with a process ID)
--			end
--		end
--
--		(re)Start the hid_listen.mac process, catching output stream
--		Set the lastSeenStatus to "mod: ------"
--		Create a new task that watches the stream with hs.task.new(launchPath, callbackFn[, streamCallbackFn, arguments]) -> hs.task object
--			shellTask = hs.task.new("/Applications/hid_listen/binaries/hid_listen.mac", nil, shellTaskStreaming)
-- 
-- On every modStatusReceived:
--		Validate that we received 12 bytes. "mod... <return>"
--		Process the status (validate format, ignore if no change, evaluate & display)
--		Set "last seen status" to current
--		wait for next stream event to occur
--
-- CONSTANTS for shell commands such as /bin/ps, /bin/kill, /Applications/hid_listen/binaries/hid_listen.mac
local HIDLISTENER = '/Applications/hid_listen/binaries/hid_listen.mac'
local PSCOMMAND   = '/bin/ps'
local KILLCOMMAND = '/bin/kill'
local PSOPTION    = '-A'

local HIDLEADIN = "KL: "	-- BUG: must change to "mod: " once keyboard is updated

shellTask = nil
neverStarted = true
local	weStoppedIt = false


-- This function collects the modifier events as they come in from the keyboard
-- Updates HUD, if found.
-- This function remains active until the next Cmd+Shift+F12 is received.
function shellTaskStreaming(mtaskid, mstdout, mstderr)
	-- Look at each line, one at a time. \n to separates the lines
	for line in string.gmatch(mstdout, "[^\n]+") do
		-- Look for "mod: " at start of line, ignore all others.
		if string.sub(line, 1, string.len(HIDLEADIN)) == HIDLEADIN then
			debuglog("Modifier found: " .. line)
			-- TODO: Update HUD based upon new status "line"
			-- modStatusReceived(string.sub(string.len(HIDLEADIN)+1))
		end
	end
	return true		-- keep streaming
end


-- Function to process the results of the 'ps -A' command.
-- Search for HID listener, and kill it's PID if present.
-- stdOut: results of command (list of processes)
-- If one or more lines in stdout contain ...hid_listen_mac then 
--		set the global (weStoppedIt = true)
--		kill the process
-- 
function psResults(exitCode, stdOut, stdErr)
	if not stdOut then return end
	-- Scan and kill listener processes
	for line in string.gmatch(stdOut, "[^\n]+") do
		-- Look for "hid_listen.mac" process
		if string.find(line, HIDLISTENER) then
		  debuglog("Stopping unknown listener task: ".. line)
		  -- Kill pid found @ start of line
		  pid, _ = string.gsub(line, ' .*', '')
		  -- We're just trusting that this works. (Testing so far indicates that it does.) Not checking the return results.
		  -- Really, what could we do anyway? Try to kill it again?
		  killTask = hs.task.new(KILLCOMMAND, nil, {pid} )
		  killTask:start()
		end
	end
end

--	The callback functions MUST be defined first or nils get passed.
--	weStoppedIt: Global. If true then we killed an HUD process, so we're done.
function startHUD()
	if weStoppedIt then
		hs.alert.show("Modifier display: Off")
		debuglog("Modifier display: Off")
		-- TODO: tear down any HUD graphics here.
		tearDownHUD()
	else
		-- There was no process to stop... Start it up.
		debuglog("Modifier display: On")
		-- Start listener, point the stream to the receiving function.
		shellTask = hs.task.new(HIDLISTENER, nil, shellTaskStreaming)
		shellTask:start()
		hs.alert.show("Modifier display: On")
		-- TODO: Start up an empty HUD here.
		createHUD()
	end
end

-- Cmd+Shift+F12 to start/stop manually.
-- If it's running, take down the current HUD and stop the data collection.
-- If not running, bring up the HUD and start data collection and update.
-- This way we both Stop and Start with Cmd+Shift+F12
--
-- Note: Also spawns "ps" command looking for (and killing) an already running listener that we don't know about.
-- We delay n seconds to let the spawned ps and kill do their jobs.
function stopOrStartHUD()
	weStoppedIt = false
	if shellTask then 
		-- terminate it if it's a task we know about and started
		debuglog("Stopping known listener task. "..tostring(shellTask))
		shellTask:terminate()
		shellTask = nil
		weStoppedIt = true
	end
	-- Scan and kill processes, no matter what
	psScanTask = hs.task.new(PSCOMMAND, psResults, {PSOPTION} )
	psScanTask:start()
	
	-- Give it all 1 seconds to work, then see if we need to start up the HUD
	hs.timer.doAfter(1, startHUD)
end


hs.hotkey.bind("Cmd Shift", "f12", nil, function() stopOrStartHUD() end )


-- See: http://www.hammerspoon.org/docs/hs.task.html#setStreamCallback
-- newStatus: Th latest status values to be updated with (less the identifying lead-in, "mod: ")
function modStatusReceived(newStatus)
	-- string.len("------") == 12
	if string.len(newStatus ~= 12) then
		return		-- error, give up
	end
	if newStatus == lastSeenStatus then
		return		-- shouldn't happen, but just in case
	end
	-- TODO: Replace this alert with displayStatus(newStatus)
	alert("New Status: "..newStatus)
end


local HUD = nil
local HUDView
local modShift		= false
local modControl	= false
local modOption		= false
local modCommand	= false

layerNames = {
	"Numeric",
	"Nav/Pnct",
	"SpaceFn",
	"Layer 4",
	"Layer 5",
	"Layer 6",
	"Layer 7",
	"Layer 8",
	"Layer 9, or above",
}
layerNames[0] = "Base"
layerName = layerNames[0]	-- default start


-- OK, this is the real work
--		The format of the input is:
--			mod: #abcde
--		Where:
--			"mod: " is a litteral for this record, that we care about here
--			"#" A layer number, 0.. 9. Any layer >9 is reported as 9
--			a A value for the Layer
--			b A value for the Shift modifier
--			c A value for the Control modifier
--			d A value for the Option modifier
--			e A value for the Command modifier
--		The values available for the layer and each modifier are: 0, 3, 6, 9 and represent the
--		"intensity" of the layer or modifier where:
--		0 - Not active
--		3 - Active, one-shot. Will deactivate on next key press
--		6 - Active, being held by the user. Will deactivate upon release
--		9 - Locked (like caps lock). Will remain active until the modifier is pressed and 
--			released again, or in the case of layer until another layer is selected.
--		We'll use these values to inform the "brightness" of the display of the modifier (symbol)
--		0 = off, 9 = brightest

--		Layer and layer intensity is always set. Layer intensity of 0 is meaningless (not allowed)
--		When layer "0" to "9" is received set layer text to layerNames[tonumber(layer)]:
--		0 = Base
--		1 = Numeric
--		2 = Nav/Pnct
--		3 = SpaceFn
--		4 = Layer 4, etc.
function displayStatus(newStat)

	debuglog("Display newStat: "..newStat)
	layerName = layerNames[tonumber(sub(newStat,6,1))]
	layerVal = 		tonumber(sub(newStat,7,1))

	--	modShift   "⇧"
	--	modControl "⋏" 
	--	modOption  "⌥"
	--	modCommand "⌘"
	modShiftVal = 	tonumber(sub(newStat,8,1))
	modControlVal = tonumber(sub(newStat,9,1))
	modOptionVal = 	tonumber(sub(newStat,10,1))
	modCommandVal = tonumber(sub(newStat,11,1))

	tearDownHUD()
	updateHUD()
	debuglog("Layer: ".. layerName.. "  Add/Delete: ".. addDelete..  "   Shift: ".. tostring(modShift))
end

--function tearDownHUD()
--  -- TODO: replace w/ graphics, if needed
--  if HUDView then
--    debuglog("Tear down HUD view.")
--    HUDView:delete()
--    HUDView=nil
--  end
--end

function updateHUD()
  -- TODO: replace w/ graphics
  if HUDView then
  -- if it exists, refresh it
	debuglog("Refresh HUD display")
  else
  -- if it doesn't exist, make it
	debuglog("Create new HUD display")
	local screen = hs.screen.primaryScreen()
	local sf = screen:frame()
	
	xLoc = sf.w - 300
	yLoc = sf.h - 100
	wide = 200
	high = 90

	-- TODO: Replace with screen graphics instead
	HUDView = hs.webview.new({x = xLoc, y = yLoc, w = wide, h = high}, 
		{ developerExtrasEnabled = false, suppressesIncrementalRendering = false })
	:windowStyle("utility")
	:closeOnEscape(false)
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
  -- LayerModifierKey:exit()
  
end

--------------------------------------------------------------------------------------
-- Testing graphics
--------------------------------------------------------------------------------------
--	Objects created once, then used as needed.
local frame = hs.screen.primaryScreen():frame()
local boxrect   = hs.geometry.rect(frame.x+frame.w-290, frame.y+frame.h-150, 275, 100)
local box = hs.drawing.rectangle(boxrect)

local textrect={}
textrect[1] = hs.geometry.rect(frame.x+frame.w-260, frame.y+frame.h-140, 235, 160)	-- modifiers
textrect[2] = hs.geometry.rect(frame.x+frame.w-200, frame.y+frame.h-140, 235, 160)
textrect[3] = hs.geometry.rect(frame.x+frame.w-140, frame.y+frame.h-140, 235, 160)
textrect[4] = hs.geometry.rect(frame.x+frame.w- 80, frame.y+frame.h-140,  90, 160)
textrect[5] = hs.geometry.rect(frame.x+frame.w-260, frame.y+frame.h-100, 300, 160)	-- Layer name text

local textColor={}
textColor[3]  = hs.drawing.color.asRGB({["red"] = 1.0,["green"] = 1.0, ["blue"] = 1.0,["alpha"]=0.75})
textColor[6]  = hs.drawing.color.asRGB({["red"] = 1.0,["green"] = 1.0, ["blue"] = 1.0,["alpha"]=0.75})
textColor[9]  = hs.drawing.color.asRGB({["red"] = 1.0,["green"] = 1.0, ["blue"] = 1.0,["alpha"]=0.75})

local shadow = {
	["offset"] = {["h"]=-2,["w"]=2}, 
	["color"]  = {["red"]=0.2,["blue"]=0.2,["green"]=0.2,["alpha"]=0.5}
	}

-- We'll use these when we see a modifier down, and delete them when the modifier is released.
-- We may need to change the "color" to textColor[3], [6], or [9] to reflect the mature of the modifier
-- stextLayer can always remain the same.
local stextCmd   = hs.styledtext.new("⌘", { ["color"] = textColor[9], ["ligature"] = 0, ["shadow"] = shadow } )
local stextOpt   = hs.styledtext.new("⌥", { ["color"] = textColor[9], ["ligature"] = 0, ["shadow"] = shadow } )
local stextCtrl  = hs.styledtext.new("⌃", { ["color"] = textColor[9], ["ligature"] = 0, ["shadow"] = shadow } )
local stextShift = hs.styledtext.new("⇧", { ["color"] = textColor[9], ["ligature"] = 0, ["shadow"] = shadow } )
local stextLayer = hs.styledtext.new("Qwerty",{ ["color"] = textColor[9], ["ligature"] = 0, ["shadow"] = shadow } )

local boxtext={}
boxtext[1] = hs.drawing.text(textrect[1], stextCmd)
boxtext[2] = hs.drawing.text(textrect[2], stextOpt)
boxtext[3] = hs.drawing.text(textrect[3], stextCtrl)
boxtext[4] = hs.drawing.text(textrect[4], stextShift)
boxtext[5] = hs.drawing.text(textrect[5], stextLayer)

-- Destroy HUD by deleting any graphics objects still on screen
function tearDownHUD()
    if boxtext[1] then boxtext[1]:delete() boxtext[1] = nil end
    if boxtext[2] then boxtext[2]:delete() boxtext[2] = nil end
    if boxtext[3] then boxtext[3]:delete() boxtext[3] = nil end
    if boxtext[4] then boxtext[4]:delete() boxtext[4] = nil end
    if boxtext[5] then boxtext[5]:delete() boxtext[5] = nil end
    box:delete()
end

function createHUD()
	debuglog("createHUD() being called.")
    --local activeWindow = hs.window.frontmostWindow()
    --local frame = activeWindow:screen():frame()
    -- Show text: ⌘⌥⌃⇧
    box = hs.drawing.rectangle(boxrect)
    box:setFillColor({["red"]=0.5,["blue"]=0.5,["green"]=0.5,["alpha"]=0.5}):setFill(true)
    box:setRoundedRectRadii(10, 10)
    box:setClickCallback(tearDownHUD)
    box:setLevel(hs.drawing.windowLevels["floating"])
    box:show()
    
	boxtext[1] = hs.drawing.text(textrect[1], stextCmd)
	boxtext[2] = hs.drawing.text(textrect[2], stextOpt)
	boxtext[3] = hs.drawing.text(textrect[3], stextCtrl)
	boxtext[4] = hs.drawing.text(textrect[4], stextShift)
	boxtext[5] = hs.drawing.text(textrect[5], stextLayer)

    boxtext[1]:show()
    boxtext[2]:show()
    boxtext[3]:show()
    boxtext[4]:show()
    boxtext[5]:show()
end


debuglog("Draw a box")
createHUD()
debuglog("Box done")

-- Maybe later:
--   	["tabStops"] = {
--   		{["location"] =  24, ["tabStopType"] = "left"},
--   		{["location"] =  48, ["tabStopType"] = "left"},
--   		{["location"] =  96, ["tabStopType"] = "left"},
--   		{["location"] = 120, ["tabStopType"] = "left"}
--   		},


return reportLayerModifierChange
