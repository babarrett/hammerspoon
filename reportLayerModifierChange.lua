-- Report Layer Modifier Change
-- Bruce's Ergodox keyboard will generate an HID sequence starting with "mod: "
-- and ending with <return> when a layer or modifier change is noted.
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

shellTask = nil
neverStarted = true


function shellTaskStreaming(mtaskid, mstdout, mstderr)
--	debuglog("\n    shellTaskStreaming -------------------------------------------")
	--debuglog(mtaskid)
	debuglog("STDOUT: "..mstdout)
--	debuglog("STDERR: \n"..mstderr)
--	debuglog("END shellTaskStreaming -------------------------------------------\n")
	return true		-- KEEP STREAMING
end

-- Stop the current HUD daa collection and display.
-- Exit with true if we stopped it.
function stopHUD()
	weStoppedIt = false
	if shellTask then 
		-- terminate it
		shellTask:terminate()
		shellTask = nil
		weStoppedIt = true
	else
	-- TODO: scan and kill processes
		-- weStoppedIt = true
	end
	
	if weStoppedIt then
		hs.alert.show("Modifier display: Off")
	end
	return weStoppedIt
end

--	The callback functions MUST be defined first or nils get passed.
function startHUD()
	-- start it up.
	-- TODO: kill any existing hid_listner.mac processes
	debuglog("Starting Modifier display")
	-- TODO: Collect (display) all active processes, watch stream for hid_listen.mac, kill any PIDs found
	-- Start listener, point the stream to the receiving function.
	shellTask = hs.task.new("/Applications/hid_listen/binaries/hid_listen.mac", nil, shellTaskStreaming)
	shellTask:start()
	-- debuglog("shellTask: "..tostring(shellTask))
	hs.alert.show("Modifier display: On")
end

-- Cmd+Shift+F12 to start/stop manually.
-- If it's running, stop it.
-- If not running, start it.
function startStopHUD()
	stopped = stopHUD()
	if not stopped then
		startHUD()
	end
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
	-- len("mod: ------<cr>") == 12
	if len(newStatus ~= 12) then
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
