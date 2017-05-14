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
-- TODO: add CONSTANTS for shell commands such as /bin/ps, /bin/kill, /Applications/hid_listen/binaries/hid_listen.mac
-- TODO: add CONSTANTS for command options like -A
local HIDLEADIN = "KL: "	-- TODO: must change to "mod: " once keyboard is updated
debuglog(HIDLEADIN)

shellTask = nil
neverStarted = true
local	weStoppedIt = false


-- This function collects the modifier events as they come in from the keyboard
-- Updates if found.
-- This function remains active until the next Cmd+Shift+F12 is received.
function shellTaskStreaming(mtaskid, mstdout, mstderr)
	-- debuglog(mtaskid)
	-- Look at each line, one at a time. \n to separate
	for line in string.gmatch(mstdout, "[^\n]+") do
		-- Look for "mod: " event
		if string.sub(line, 1, string.len(HIDLEADIN)) == HIDLEADIN then
			debuglog("Modifier found: " .. line)
			-- TODO: if, update HUD bases upon "line"
			-- modStatusReceived(string.sub(string.len(HIDLEADIN)+1))
		end
	end
	return true		-- KEEP STREAMING
end

local hid_listenKilled = false


-- Function to process the results of the 'ps -A' command
-- Search for '/Applications/hid_listen/binaries/hid_listen.mac' and kill it's pid
-- stdOut: results of command (list of processes)
-- If stdout contains ...hid_listen_mac then 
--		set the global 
--		kill the process
--		
function psResults(exitCode, stdOut, stdErr)
	if not stdOut then return end
	-- debuglog("psResults: "..stdOut)
	-- TODO: scan and kill processes
	for line in string.gmatch(stdOut, "[^\n]+") do
		-- Look for "hid_listen.mac" process
		if string.find(line, '/Applications/hid_listen/binaries/hid_listen.mac') then
		  debuglog("ps found: " .. line) 
		  -- TODO: Kill pid @ start of line
		  pid, _ = string.gsub(line, ' .*', '')
		  killTask = hs.task.new("/bin/kill", nil, {pid} )
		  killTask:start()
		end
		-- TODO: if, update HUD
	end
end

-- Stop the current HUD data collection and display.
-- Set weStoppedIt to true if we stopped it.
-- Note: Also spawns "ps" command looking for an already running listener that we don't know about.
function stopHUD()
	if shellTask then 
		-- terminate it if it's a task we know about and started
		shellTask:terminate()
		shellTask = nil
		weStoppedIt = true
	else
		-- TODO: scan and kill processes
		local hid_listenKilled = false
		psScanTask = hs.task.new("/bin/ps", psResults, {"-A"} )
		psScanTask:start()
		-- weStoppedIt = true
	end
	
	if weStoppedIt then
		hs.alert.show("Modifier display: Off")
	end
	return weStoppedIt
end

--	The callback functions MUST be defined first or nils get passed.
--	weStoppedIt: Global. If true then we DO NOT start up the HUD
function startHUD()
	if not weStoppedIt then
		-- There was no process to stop... Start it up.
		debuglog("Starting Modifier display")
		-- Start listener, point the stream to the receiving function.
		shellTask = hs.task.new("/Applications/hid_listen/binaries/hid_listen.mac", nil, shellTaskStreaming)
		shellTask:start()
		hs.alert.show("Modifier display: On")
	end
	weStoppedIt = 'Running'		-- BUG: Probably not needed.
end

-- Cmd+Shift+F12 to start/stop manually.
-- If it's running, stop it.
-- If not running, start it.
function startStopHUD()
	weStoppedIt = false
	stopHUD()
	-- Give it all 2 seconds to work, then see if we need to start up the HUD
	hs.timer.doAfter(2, startHUD)
end

hs.hotkey.bind("Cmd Shift", "f12", nil, function() startStopHUD() end )


--	This function not used.
function shellTaskDone(exitcode, stdout, stderr)
	debuglog("Called shellTaskDone")
	debuglog(exitcode)
	debuglog("STDOUT: \n"..stdout)
	debuglog("STDERR: \n"..stderr)
end


-- See: http://www.hammerspoon.org/docs/hs.task.html#setStreamCallback
function modStatusReceived(newStatus)
	-- string.len("mod: ------<cr>") == 12
	if string.len(newStatus ~= 12) then
		return
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

	tearDown()
	updateHUD()
	debuglog("Layer: ".. layerName.. "  Add/Delete: ".. addDelete..  "   Shift: ".. tostring(modShift))
end

function tearDown()
  -- todo: replace w/ graphics, if needed
  if HUDView then
    debuglog("Tear down HUD view.")
    HUDView:delete()
    HUDView=nil
  end
end

function updateHUD()
  -- todo: replace w/ graphics
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



return reportLayerModifierChange
