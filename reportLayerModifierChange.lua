-- Report Layer Modifier Change
-- Bruce's Ergodox keyboard will generate an HID sequence starting with "mod: "
-- and ending with <return> when a layer or modifier change is noticed.
-- This Hammerspoon code will detect and interpret that sequence and
-- display the current state in a "heads up display"
-- Cmd+Shift+F12 to start/stop the monitoring and display.
-- by: Bruce Barrett

-- TODO: 
--		Handle Mod change to display update
--		Cmd+Shift+F11 to change display & test
--		Rename box --> HUDFrame(?)
--		Update internal docs
--		Update keyboard (hw) firmware
--		BUG: Fast on/off gets out of sync? "Debounce if happen within 2 seconds of each other? 
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
local MODIFIERS   = {"⌘", "⌥", "⌃", "⇧", "-"}
--local MODIFIERS   = {"Ba", "Ba", "Ba", "Ba"}

local WAITFORPS   = 1 -- Seconds to wait.

local HIDLEADIN = "KL: "	-- BUG: must change to "mod: " once keyboard firmware is updated

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
			-- modStatusReceived(string.sub(line string.len(HIDLEADIN)+1))
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
		end
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
    debuglog("New task: ".. PSCOMMAND.. "; Option: ".. PSOPTION)
	psScanTask = hs.task.new(PSCOMMAND, psResults, {PSOPTION} )
	psScanTask:start()
	
	-- Give it all time to work, then see if we need to start up the HUD
	hs.timer.doAfter(WAITFORPS, startHUD)
end

hs.hotkey.bind("Cmd Shift", "f12", nil, function() stopOrStartHUD() end )


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

-- See: http://www.hammerspoon.org/docs/hs.task.html#setStreamCallback
-- newStatus: The latest status values to be updated to (less the identifying lead-in, "mod: ")
-- See displayStatus() for format definition.
function modStatusReceived(newStatus)
	-- string.len("------") == 6
	if string.len(newStatus ~= 6) then
		return		-- error, give up
	end
	if newStatus == lastSeenStatus then
		return		-- shouldn't happen, but just in case
	end
	-- TODO: Replace this alert with displayStatus(newStatus)
	alert("New Status: "..newStatus)
end


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
function displayStatus(newStat)
	-- TODO: update with real changes to modifier and layer text
	debuglog("displayStatus(): "..newStat)
	layerName = layerNames[tonumber(string.sub(newStat,6,1))]
	layerVal = 		tonumber(string.sub(newStat,7,1))

	--	modCommand "⌘"
	--	modOption  "⌥"
	--	modControl "⋏" 
	--	modShift   "⇧"
	-- was tearDownHUD()
	-- TODO: Simplify: Only update those that changed
    if boxtext[1] then boxtext[1]:delete() end
    if boxtext[2] then boxtext[2]:delete() end
    if boxtext[3] then boxtext[3]:delete() end
    if boxtext[4] then boxtext[4]:delete() end
    if boxtext[5] then boxtext[5]:delete() end
	
    for i =1, 4 do
    	boxtext[i] = makeBoxText(i, tonumber(string.sub(newStat,i+2,i+2)), 0)
    	boxtext[i]:show()
    end
	layerNumb =     tonumber(string.sub(newStat,1,1))
	layerVal =      tonumber(string.sub(newStat,2,2))
	boxtext[5] = makeBoxText(5, layerVal, layerNumb)
   	boxtext[5]:show()

	-- BUG: No longer need... updateHUD()
	debuglog("HUD text and intensity updated.")
end

function updateHUD()
  -- TODO: replace w/ graphics
  if not HUDView then
    -- if it doesn't exist, make it
	debuglog("Create new HUD display")
	local screen = hs.screen.primaryScreen()
  else
    -- if it exists, refresh it
	debuglog("Refresh HUD display")
  end
end

--------------------------------------------------------------------------------------
-- Testing graphics
--------------------------------------------------------------------------------------
--	Objects created once, then used as needed.
local frame = hs.screen.primaryScreen():frame()
local boxrect   = hs.geometry.rect(frame.x+frame.w-290, frame.y+frame.h-150, 275, 100)
local box = hs.drawing.rectangle(boxrect)

-- Location of the text box for each position
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

-- Destroy HUD by deleting any graphics objects still on screen
function tearDownHUD()
    if boxtext[1] then boxtext[1]:delete() boxtext[1] = nil end
    if boxtext[2] then boxtext[2]:delete() boxtext[2] = nil end
    if boxtext[3] then boxtext[3]:delete() boxtext[3] = nil end
    if boxtext[4] then boxtext[4]:delete() boxtext[4] = nil end
    if boxtext[5] then boxtext[5]:delete() boxtext[5] = nil end
    box:delete()
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

-- Function: createHUD()
-- Creates the on-screen graphics for:
--		The background, translucent rectangle with rounded corners
-- Later, show text of modifiers: ⌘⌥⌃⇧, and layer name
-- Store created objects in known variables
function createHUD()
	-- Create on-screen rectangle
    box = hs.drawing.rectangle(boxrect)
    box:setFillColor({["red"]=0.5,["blue"]=0.5,["green"]=0.5,["alpha"]=0.5}):setFill(true)
    box:setRoundedRectRadii(10, 10)
    box:setLevel(hs.drawing.windowLevels["floating"])	-- above the rest
    box:show()
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
		-- Create modifier indicators:
--		displayStatus("0901369")
		displayStatus("099369")
	end
end

return reportLayerModifierChange
