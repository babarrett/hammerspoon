-- Report Layer Modifier Change
-- Bruce's Ergodox keyboard will generate an HID sequence starting with "mod: "
-- and ending with <return> when a layer or modifier change is noted.
-- This Hammerspoon code will detect and interpret that sequence and
-- display the current state in a "heads up display"
-- by: Bruce Barrett

reportLayerModifierChange = {}

-- Because I don't know how to feed HID events into Hammerspoon directly I'll
-- do it through the file system, as follows:
-- On Hammerspoon start-up or "Reload config" run the shell command: ps | grep hid_listen | grep -v grep
--		if any non-empty lines are returned they start with a process ID. Kill those processes
--		(re)Start the hid_listen process, redirecting output, through grep, to /tmp/hid-for-hammerspoon
--			hid_listen | grep 'mod: ' > /tmp/hid-for-hammerspoon
--		Set "last seen file size" to zero
--		Set the lastSeenStatus to "mod: ------"
--	XX	Create a recurring timer probably: "streamTimer = hs.timer.new(interval, fn [, continueOnError]) -> timer" (this does not start the timer, yet)
--	XX		or less likely: "hs.timer.doEvery(interval, fn)" for every 1/4 second. [but can this do sub-second scans?]
--		Create a new task that watches the stream with hs.task.new(launchPath, callbackFn[, streamCallbackFn, arguments]) -> hs.task object
--			newModStatus = hs.task.new("/usr/bin/tail", nil, modStatusReceived, {"-1"})		-- return most recent status == last line in file
-- 
-- On every modStatusReceived:
--		Validate that we received 12 bytes. "mod... <return>"
--		Process the newest status (validate format, evaluate & display)
--		Set "last seen status" to current
--		wait for stream event to occure
--
-- Maybe someday, when file gets "too big" a. close down the stream task. b. halt the process. c. start all over.

shellTask = nil

function startStopHUD()
	if shellTask then 
		-- terminate it
		shellTask:terminate()
		shellTask = nil
		debuglog("Terminated shellTask")
	else
		-- start it up.
		-- TODO: kill any existing hid_listner.mac processes
		debuglog("test new task (OK)")
		--	TODO:	/Applications/hid_listen/binaries/hid_listen.mac
		shellTask = hs.task.new("/Applications/hid_listen/binaries/hid_listen.mac", nil, shellTaskStreaming)		--  shellTaskDone
		debuglog("shellTask: "..tostring(shellTask))
		shellTask:setWorkingDirectory("/Users/bruce/dev/git/hammerspoon")
		debuglog("workingDirectory (OK): "..shellTask:workingDirectory())
		--shellTask:setInput("inputData")
		shellTask:start()
		debuglog("shellTask started")
	end
end

hs.hotkey.bind("Cmd Shift", "f12", nil, function() startStopHUD() end )


--	-------------------------------------------
--		TEST
--	-------------------------------------------
--	The callback functions MUST be defined first or nils get passed.
function shellTaskDone(exitcode, stdout, stderr)
	debuglog("Called shellTaskDone")
	debuglog(exitcode)
	debuglog("STDOUT: \n"..stdout)
	debuglog("STDERR: \n"..stderr)
end

function shellTaskStreaming(mtaskid, mstdout, mstderr)
--	debuglog("\n    shellTaskStreaming -------------------------------------------")
	--debuglog(mtaskid)
	debuglog("STDOUT: "..mstdout)
--	debuglog("STDERR: \n"..mstderr)
--	debuglog("END shellTaskStreaming -------------------------------------------\n")
	return true		-- KEEP STREAMING
end


--shellTask:terminate()

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
local addDelete = "add"					-- I'm not crazy about globals, but this simplifies the code
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
	"Layer 9",
}
layerNames[0] = "Base"
layerName = layerNames[0]	-- default start


-- OK, this is the real work
--		The format of the input is:
--			mod: #abcde
--		Where:
--			"mod: " is a litteral for this record, that we care about here
--			"#" A layer number, 0.. 9
--			a A value for the Layer
--			b A value for the Shift modifier
--			c A value for the Control modifier
--			d A value for the Option modifier
--			e A value for the Command modifier
--		The values available for the layer and each modifier are: 0, 3, 6, 9 and represent the
--		intensity of the layer or modifier where:
--		0 - Not active
--		3 - Active, one-shot. Will deactivate on next key press
--		6 - Active, being held by the user. Will deactivate upon release
--		9 - Locked (like caps lock). Will remain active until the modifier is pressed and 
--			released again, or in the case of layer until another layer is selected.
--		We'll use these values to inform the "brightness" of the display of the modifier (symbol)

--		Layer and laer intensity is always set. Layer intensity of 0 is meaningless (not allowed)
--		When layer "0" to "9" is received set layer text to:
--		0 = Base
--		1 = Numeric
--		2 = Nav/Pnct
--		3 = SpaceFn
--		4 = Layer 4, etc.
function displayStatus(newStat)

	debuglog("Display newStat: "..newStat)
	layerName = layerNames[tonumber(sub(newStat,6,1))]
	layerVal = 		tonumber(sub(newStat,7,1))

	modShiftVal = 	tonumber(sub(newStat,8,1))
	modControlVal = tonumber(sub(newStat,9,1))
	modOptionVal = 	tonumber(sub(newStat,10,1))
	modCommandVal = tonumber(sub(newStat,11,1))

	tearDown()
	updateHUD()
	debuglog("Layer: ".. layerName.. "  Add/Delete: ".. addDelete..  "   Shift: ".. tostring(modShift))
end

function tearDown()
  -- todo: replace w/ graphics
  if HUDView then
    debuglog("Tear down HUD view.")
    HUDView:delete()
    HUDView=nil
  end
  LayerModifierKey:exit()
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
  LayerModifierKey:exit()
  
end

--				((modShift  ) and "⇧" or "&nbsp;&nbsp;") ..
--				((modControl) and "⋏" or  "&nbsp;") ..
--				((modOption ) and "⌥" or "&nbsp;&nbsp;&nbsp;") ..
--				((modCommand) and "⌘" or "&nbsp;&nbsp;&nbsp;&nbsp;") ..


return reportLayerModifierChange
