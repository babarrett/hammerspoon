-- Bind Function Keys (Shift+F1-8, F13-F24) to one of 3 functions:
-- 	* Launch (or select) App
--	* Open web page
--	* Type a key (and optional modifier)
-- Bindings are to the short-cuts I care most about.
-- by: Bruce Barrett

bindFunctionKeys = {}

-- This will "run" any of 3 types of bond keys:
--	Launch an Application
--	Open a web page
--	Type a (modifier)+Key
--  We'll only try one, the first non-nil parameter
function launchAppOrWeb(app,web, key)
  if app ~= nil then
      -- Try it up to 3 ways.
	  status = hs.application.launchOrFocus(app)
	  if (not status) then
		  status = hs.application.launchOrFocusByBundleID(app)	-- use BundleID ("com.aspera.connect") if App name fails
		  if (not status) then
		    output, status = hs.execute("open " .. app)
		  end
		end
  elseif web ~= nil then
    hs.execute("open " .. web)
  elseif key ~= nil then
    -- assign to another key
    hs.eventtap.keyStroke(key["mods"], key["char"])

  end
end

-- Format of these bindings is:
--   Key modifier if any, Key to bind, Display message  (nil, not used),
--   App to launch or bundleID, Web site to open, Keypress to simulate (Example: Cmd+shift+".")

hs.hotkey.bind("Shift", "f1", nil, function() launchAppOrWeb( 'BBEdit', nil, nil) end )
hs.hotkey.bind("Shift", "f2", nil, function() launchAppOrWeb( 'iTerm', nil, nil) end )
hs.hotkey.bind("Shift", "f3", nil, function() launchAppOrWeb( 'Safari', nil) end )
hs.hotkey.bind("Shift", "f4", nil, function() launchAppOrWeb( 'Finder', nil) end )
hs.hotkey.bind("Shift", "f5", nil, function() launchAppOrWeb( 'Mail', nil) end )
hs.hotkey.bind("Shift", "f6", nil, function() launchAppOrWeb( nil, nil, {mods='CMD', char="1"} ) end )		-- CMD+1 = View Mail inbox
--hs.hotkey.bind("Shift", "f7", nil, function() launchAppOrWeb( nil, nil, {mods='CMD Shift', char="."}) end )	-- Cmd+Shift+"." = for move email to Done folder
--hs.hotkey.bind("Shift", "f8", nil, function() launchAppOrWeb( nil, nil, {mods='CMD Shift', char=","}) end )	-- Cmd+Shift+"," = for move email to Status folder

-- No idea why, but these (F9 to F11, and Shift-F10 to Shift-F11 fail. (macOS intercepts them?) Replaced with Karabiner.
hs.hotkey.bind("Shift", "f9", nil, function() hs.eventtap.keyStroke({"cmd", "shift"}, "[") end )  -- Prev browser tab
--hs.hotkey.bind("Shift", "f10", nil, function() hs.alert( 's-f10' ) end )
--hs.hotkey.bind("Shift", "f11", nil, function() hs.alert( 's-f11' ) end )
hs.hotkey.bind("Shift", "f12", nil, function() hs.eventtap.keyStroke({"cmd", "shift"}, "]") end )  -- Next browser tab

-- www short cuts
-- F13..20(24) are for the GH-122 keyboard
-- Shift + F1..F12 map to F13..20(24)
--F13 also = PrtSc/SysRq; F14 = Scroll Lock; F15 = Pause/Break
--hs.hotkey.bind("", "f13", nil, function() launchAppOrWeb( nil, "https://hangouts.google.com/") end )
--hs.hotkey.bind("Shift", "f1", nil, function() launchAppOrWeb( nil, "https://hangouts.google.com/") end )
--hs.hotkey.bind("", "f14", nil, function() launchAppOrWeb( nil, "https://drive.google.com/drive/my-drive") end )
--hs.hotkey.bind("Shift", "f2", nil, function() launchAppOrWeb( nil, "https://drive.google.com/drive/my-drive") end )
--hs.hotkey.bind("", "f15", nil, function() launchAppOrWeb( nil, "https://docs.google.com/document/u/0/?tgif=c") end )
--hs.hotkey.bind("Shift", "f3", nil, function() launchAppOrWeb( nil, "https://docs.google.com/document/u/0/?tgif=c") end )
--hs.hotkey.bind("", "f16", nil, function() launchAppOrWeb( nil, "https://sheets.google.com") end )
--hs.hotkey.bind("Shift", "f4", nil, function() launchAppOrWeb( nil, "https://sheets.google.com") end )

hs.hotkey.bind("Cmd Shift", "f10", nil, function() 	hs.eventtap.keyStroke({""}, "f10") end )

--    W = {"Geekhack", nil, "https://geekhack.org/index.php?action=watched"},		-- Geekhack, Watched
--    K = {"KLE", nil, "http://www.keyboard-layout-editor.com"},
--    H = {"Home", nil, "http://brucebarrett.com/browserhome/brucehome.html"},


local key


function dumpTable(myTable, indent)
  local count = 0
  for k,v in pairs(myTable) do
    debuglog(((indent ~= nil) and indent or "").."dumpTable: "..k..", "..tostring(v).."   type(v)="..type(v))
    if type(v) == "table" then
      dumpTable(v, "    ")
      debuglog("-------------------------------------------")
    end
  end
end

function doFnKeypress(k)
  debuglog("Function key type = "..type(key))
  debuglog("Responding to function key '"..k.."'")
end

return bindFunctionKeys
