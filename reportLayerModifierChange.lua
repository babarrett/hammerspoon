-- Report Layer Modifier Change
-- Bruce's Ergodox keyboard will generate an HID sequence starting with "mod: "
-- and ending with <return> when a layer or modifier change is noticed.
-- This Hammerspoon code will detect and interpret that sequence and
-- display the current state in a "heads up display"
-- Cmd+Shift+F12 to start/stop the monitoring and display.
-- by: Bruce Barrett

-- TODO: 
--		Update keyboard (hw) firmware
--		√ Hide HID background/box/frame when all settings are default. (Layer=0, no mod keys active)
--		√ Show HID background... when any setting is not default.
--		√ Handle Mod change to display update
--		Rename box --> HUDFrame(?)
--		Update internal docs
--		BUG: Fast on/off gets out of sync? "Debounce if happen within 2 seconds of each other?
--		Add simulated LEDs to HUD: Cmd, Opt, Shift, Ctrl -- Layers (3 green LEDs) -- Num Lock (Purple)
--		Future: Also display "mode" such as mouse movement, window movement, window sizing
--		Run Lualint on all software
reportLayerModifierChange = {}

-- TODO: Review and edit this for accuracy. 
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
local MODIFIERS   = {"⌘", "⌥", "⌃", "⇧", "-"}

local WAITFORPS   = 1 -- Seconds to wait.

local HIDLEADIN = "KL: "	-- BUG: must change to "mod: " once keyboard firmware is updated

shellTask = nil
neverStarted = true
local weStoppedIt = false
local lastSeenStatus = ""
local frame
local boxrect
local HUDFrame
local testTimer = nil
local testCount = 0

-- This function is a callback from the task streaming output.
-- Collects the modifier events as they come in from the keyboard
-- Updates HUD, if found.
-- This function remains active until the next Cmd+Shift+F12 is received.
function shellTaskStreaming(mtaskid, mstdout, mstderr)
	-- Look at each line, one at a time. \n to separates the lines
	for line in string.gmatch(mstdout, "[^\n]+") do
		-- Look for "mod: " at start of line, ignore all others.
		if string.sub(line, 1, string.len(HIDLEADIN)) == HIDLEADIN then
			displayStatus(string.sub(line, string.len(HIDLEADIN)+1))
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
		  debuglog("New task: ".. KILLCOMMAND.. "; pid="..pid)
		  killTask = hs.task.new(KILLCOMMAND, nil, {pid} )
		  killTask:start()
		  if testTimer then
			debuglog("Stopping testTimer (b)-------------------------------------------")
			testTimer:stop()
			testTimer = nil
		  end
		  weStoppedIt = true

		end
	end
end

-- Cmd+Shift+F12 to start/stop manually.
-- If it's running, take down the current HUD and stop the data collection.
-- If not running, bring up the HUD and start data collection and update.
-- This way we both Stop and Start with Cmd+Shift+F12
--
-- Note: Also spawns "ps" command looking for, and killing, an already running listener that we did't know about.
-- We delay n seconds to let the spawned ps and kill do their jobs.
function stopOrStartHUD()
	weStoppedIt = false
	if shellTask then 
		-- terminate it if it's a task we know about and started
		debuglog("Stopping known listener task. "..tostring(shellTask))
		shellTask:terminate()
		shellTask = nil
		if testTimer then
			debuglog("Stopping testTimer (a)============")
			testTimer:stop()
			testTimer = nil
		end
		weStoppedIt = true
	end
	-- Scan and kill processes, no matter what
    debuglog("New task: ".. PSCOMMAND.. "; Option: ".. PSOPTION)
	psScanTask = hs.task.new(PSCOMMAND, psResults, {PSOPTION} )
	psScanTask:start()
	
	-- Give it all time to work, then see if we need to start up the HUD
	hs.timer.doAfter(WAITFORPS, startStopHUD)
	
	-- Test by updating every second. UNITTEST only
	-- test()
end

hs.hotkey.bind("Cmd Shift", "f12", nil, function() stopOrStartHUD() end )

local testStates = {
"099999",
"090000",	-- nothing to see here
"093000",	-- cmd 0, 3, 6, 9
"096000",
"099000",
"090000",	-- Opt 0, 3, 6, 9
"090300",
"090600",
"090900",
"090000",	-- Ctrl 0, 3, 6, 9
"090030",
"090060",
"090090",
"090000",	-- shift 0, 3, 6, 9
"090003",
"090006",
"090009",
"090000",	-- EQ display moves to right
"093000",
"096300",
"099630",
"096963",
"093696",
"090369",
"090036",
"090003",
"090000",
"099000",	-- all layers
"190900",
"290090",
"390009",
"490090",
"590900",
"699000",
"790600",
"890060",
"990006",
"990009",
}
function test()
	testCount = testCount + 1
	if testCount > 37 and testTimer then
		testTimer:stop()
		testTimer = nil
	else
		if testTimer == nil then
			testTimer = hs.timer.doEvery(1, test)
			debuglog("New timer: "..tostring(testTimer))
		else
			displayStatus(testStates[testCount])
		end
	end
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
layerNames[0] = "Base"	-- because we want the table to be zero-based.
layerName = layerNames[0]	-- default start
local boxtext={}


-- OK, this is the real work
--		The format of the input is:
--			mod: #abcde
--		Where:
--			"mod: " is a literal for this record, that we care about here.
--				Stripped off before this function is called.
--			# A layer number, 0.. 9. Any layer >9 is reported as 9 from the keyboard firmware
--			a An intensity value for the Layer
--			b An intensity value for the Command modifier
--			c An intensity value for the Option modifier
--			d An intensity value for the Control modifier
--			e An intensity value for the Shift modifier
--		The intensity values available for the layer and each modifier are: 0, 3, 6, 9 and represent the
--		"intensity" of the layer or modifier where:
--		0 - Not active
--		3 - Active, one-shot. Will deactivate on next key press
--		6 - Active, being held by the user. Will deactivate upon release
--		9 - Locked (like caps lock). Will remain active until the modifier is pressed and 
--			released again, or in the case of layer until another layer is selected.
--		We'll use these intensity values to inform the "brightness" of the display of the modifier (symbol)
--		0 = off, 9 = brightest, or most opaque

--		Layer and layer intensity is always set. Layer intensity of 0 is meaningless (not allowed)
--		TODO: Layer intensity is ignored for now, but could reflect the one=shot state of the layer
--		Set layer text to layerNames[tonumber(layer)], defined above
-- newStatus: The latest status values to be updated to (less the identifying lead-in, "mod: ")
function displayStatus(newStat)
	debuglog("displayStatus(): "..newStat)
	if string.len(newStat) ~= 6 then
		return		-- error, give up
	end
	if newStat == lastSeenStatus then
		return		-- shouldn't happen, but just in case
	end
	layerName = layerNames[tonumber(string.sub(newStat,1,1))]
	layerVal = 		tonumber(string.sub(newStat,2,2))

	--	modCommand "⌘"
	--	modOption  "⌥"
	--	modControl "⋏" 
	--	modShift   "⇧"
	--	Remove all, start fresh
	-- TODO: Simplify: Only update those that changed
	tearDownHUDtext()
		
	--	Kill off BG if there's nothing to display (default status)
	if string.sub(newStat,-4) == "0000" and string.sub(newStat,1,1) == "0" then
		if HUDFrame then 
			HUDFrame:hide()
		end
	else
		createHUDbg()
		for i =1, 4 do
			boxtext[i] = makeBoxText(i, tonumber(string.sub(newStat,i+2,i+2)), 0)
			boxtext[i]:show()
		end
		layerNumb =     tonumber(string.sub(newStat,1,1))
		layerVal =      tonumber(string.sub(newStat,2,2))
		boxtext[5] = makeBoxText(5, layerVal, layerNumb)
		boxtext[5]:show()

		debuglog("displayStatus(): HUD text and intensity updated.")
	end
	lastSeenStatus = newStat
end

--------------------------------------------------------------------------------------
-- Testing graphics
--------------------------------------------------------------------------------------
--	Objects created once, then used as needed.
frame = hs.screen.primaryScreen():frame()
boxrect   = hs.geometry.rect(frame.x+frame.w-290, frame.y+frame.h-150, 275, 100)
--  Create as needed
HUDFrame = nil

-- Location of the text HUDFrame for each position
local textrect={}
textrect[1] = hs.geometry.rect(frame.x+frame.w-260, frame.y+frame.h-140, 235, 160)	-- modifiers
textrect[2] = hs.geometry.rect(frame.x+frame.w-200, frame.y+frame.h-140, 235, 160)
textrect[3] = hs.geometry.rect(frame.x+frame.w-140, frame.y+frame.h-140, 235, 160)
textrect[4] = hs.geometry.rect(frame.x+frame.w- 80, frame.y+frame.h-140,  90, 160)
textrect[5] = hs.geometry.rect(frame.x+frame.w-260, frame.y+frame.h-100, 300, 160)	-- Layer name text

local textColor={}
textColor[0]  = hs.drawing.color.asRGB({["red"] = 0.00,["green"] = 0.00, ["blue"] = 0.00,["alpha"]=0.00})
textColor[3]  = hs.drawing.color.asRGB({["red"] = 0.77,["green"] = 0.77, ["blue"] = 0.77,["alpha"]=0.66})
textColor[6]  = hs.drawing.color.asRGB({["red"] = 0.88,["green"] = 0.88, ["blue"] = 0.88,["alpha"]=0.77})
textColor[9]  = hs.drawing.color.asRGB({["red"] = 0.99,["green"] = 0.99, ["blue"] = 0.99,["alpha"]=0.99})

local shadow = {
	["offset"] = {["h"]=-2,["w"]=2}, 
	["color"]  = {["red"]=0.2,["blue"]=0.2,["green"]=0.2,["alpha"]=0.5}
	}

-- We'll use these when we see a modifier down, and delete them when the modifier is released.
-- We may need to change the "color" to textColor[0], [3], [6], or [9] to reflect the mature of the modifier
-- stextLayer can always remain the same.
local stextCmd   = hs.styledtext.new("⌘", { ["color"] = textColor[9], ["ligature"] = 0, ["shadow"] = shadow } )
local stextOpt   = hs.styledtext.new("⌥", { ["color"] = textColor[9], ["ligature"] = 0, ["shadow"] = shadow } )
local stextCtrl  = hs.styledtext.new("⌃", { ["color"] = textColor[9], ["ligature"] = 0, ["shadow"] = shadow } )
local stextShift = hs.styledtext.new("⇧", { ["color"] = textColor[9], ["ligature"] = 0, ["shadow"] = shadow } )
local stextLayer = hs.styledtext.new("Qwerty",{ ["color"] = textColor[9], ["ligature"] = 0, ["shadow"] = shadow } )

boxtext[1] = hs.drawing.text(textrect[1], stextCmd)
boxtext[2] = hs.drawing.text(textrect[2], stextOpt)
boxtext[3] = hs.drawing.text(textrect[3], stextCtrl)
boxtext[4] = hs.drawing.text(textrect[4], stextShift)
boxtext[5] = hs.drawing.text(textrect[5], stextLayer)

-- Destroy HUD text by deleting any graphics objects still on screen
function tearDownHUDtext()
    if boxtext[1] then boxtext[1]:delete() boxtext[1] = nil end
    if boxtext[2] then boxtext[2]:delete() boxtext[2] = nil end
    if boxtext[3] then boxtext[3]:delete() boxtext[3] = nil end
    if boxtext[4] then boxtext[4]:delete() boxtext[4] = nil end
    if boxtext[5] then boxtext[5]:delete() boxtext[5] = nil end
end

-- Function: makeBoxText(whichText, tansparencyLevel)
--	whichText: The number of the text to create, 1 to 5. The first 4 are modifiers, #5 = layout name
--	tansparencyLevel: 0 for invisible, 1 for 1/3, 2 for 2/3, 3 for 3/3 (opaque)
--	layerNumber: 0 to 9
function makeBoxText(whichText, tansparencyLevel, layerNumber)
	--debuglog("--- makeBoxText: "..whichText..", "..tansparencyLevel..", "..layerNumber.."; ")
	if whichText <  5 then textToShow = MODIFIERS[whichText] end
	if whichText == 5 then textToShow = layerNames[layerNumber] end
	-- 			   hs.styledtext.new("⌘",       { ["color"] = textColor[9],                ["ligature"] = 0, ["shadow"] = shadow } )
	styleTextext = hs.styledtext.new(textToShow, { ["color"] = textColor[tansparencyLevel], ["ligature"] = 0, ["shadow"] = shadow } )
	return(hs.drawing.text(textrect[whichText], styleTextext))
end

-- Function: createHUDbg()
-- Creates the on-screen graphics (if needed) for:
--		The background, translucent rectangle with rounded corners
-- Store created objects in known variables
function createHUDbg()
	if HUDFrame then 
		-- Already exists, make sure it's showing
	    HUDFrame:show()
	else
		-- Create on-screen rectangle
		HUDFrame = hs.drawing.rectangle(boxrect)
		HUDFrame:setFillColor({["red"]=0.5,["blue"]=0.5,["green"]=0.5,["alpha"]=0.5}):setFill(true)
		HUDFrame:setRoundedRectRadii(10, 10)
		HUDFrame:setLevel(hs.drawing.windowLevels["floating"])	-- above the rest
		HUDFrame:show()
	end
end

--	Function: startStopHUD()
--	Global, weStoppedIt:
--		true: then we killed an HUD process, so we're done.
--		false: didn't kill an HUD process, so create one
--	Remember: The callback functions MUST be defined first or nils get passed.
function startStopHUD()
	if weStoppedIt then
		hs.alert.show("Modifier display: Off")
		debuglog("Modifier display: Off")
		tearDownHUDtext()
	    if HUDFrame then HUDFrame:hide() end
	else
		-- There was no process to stop... Start it up.
		debuglog("Modifier display: On")
		-- Start listener, point the stream to the receiving function.
		shellTask = hs.task.new(HIDLISTENER, nil, shellTaskStreaming)
		shellTask:start()
		hs.alert.show("Modifier display: On")
		-- Show an empty HUD here, as acknowledgement of start up.
		createHUDbg()
		-- Create modifier indicators:
--		displayStatus("090000")
--		displayStatus("099369")
	end
end


return reportLayerModifierChange
