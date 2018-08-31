--	Bruce's Hammerspoon functions.

--	For "require" commands
--	TODO: Support better path (there is none yet)
-- "?;?.lua;~/dev/git/hammerspoon/?;?.lua"
--	TODO: Create another modual for KeyToKey mappings such as Numeric Pad to move functions.
--	TODO: Find some way wo handle NumLock, What's blocking it? No Karibiner == always numeric.

VERSION = "2018-JAugust-30"
hs.console.clearConsole()
--  hs.alert(hs.hid.capslock.get())

LUA_PATH = os.getenv("HOME") .. "/dev/git/hammerspoon/?"

HyperFn = {"cmd", "alt", "ctrl", "shift"}	-- Mash the 4 modifier keys for some new function
HyperFnString = "⌘⌥⌃⇧"					-- Visual representation

-- log debug info to Hyperspoon Console
-- We can disable all logging in one place
function debuglog(text)
  hs.console.printStyledtext("DEBUG: "..tostring(text))
end

--hs.hotkey.bind("", "f8", nil, function() hs.alert("f8") end ) -- works
--hs.hotkey.bind("", "f9", nil, function() hs.alert("f9") end ) -- fail
--hs.hotkey.bind("", "f10", nil, function() hs.alert("f10") end ) -- fail
--hs.hotkey.bind("", "f11", nil, function() hs.alert("f11") end ) -- fail
--
--hs.hotkey.bind("Cmd", "f9", nil, function() hs.alert("cmd f9") end ) -- works
--hs.hotkey.bind("Cmd", "f10", nil, function() hs.alert("cmd f10") end ) -- works
--hs.hotkey.bind("Cmd", "f11", nil, function() hs.alert("cmd f11") end ) -- works
--
--hs.hotkey.bind("Shift", "f9", nil, function() hs.alert("shift f9") end ) -- fail
--hs.hotkey.bind("Shift", "f10", nil, function() hs.alert("shift f10") end ) -- fail
--hs.hotkey.bind("Shift", "f11", nil, function() hs.alert("shift f11") end ) -- fail
--
--hs.hotkey.bind("Ctrl", "f9", nil, function() hs.alert("ctrl f9") end ) -- works
--hs.hotkey.bind("Ctrl", "f10", nil, function() hs.alert("ctrl f10") end ) -- works
--hs.hotkey.bind("Ctrl", "f11", nil, function() hs.alert("ctrl f11") end ) -- works


--[[	First we require all modules we'll later use
	Note, as we bind to each function they add to the help string	--]]
HF 								              = require "helpFunctions"	-- global. Other modules call this too.
HF.add("-- Miscellaneous Functions -- "..VERSION.." --\n")
HF.bind(HyperFn, "H", "hammerspoonHelp")
local pasteCurrentSafariUrl 	  = require "pasteCurrentSafariUrl"
local windowManagement 			    = require "windowManagement"
local miscFunctions 			      = require "miscFunctions"
local cheatsheets				        = require "cheatsheets"
local launchApplications		    = require "launchApplications"	-- or Webpages
local switchApplications		    = require "switchApplications"
local reportLayerModifierChange	= require "reportLayerModifierChange"
local repeatNextKey             = require "repeatNextKey"
require "KeyPressShow"			-- Hyper+K shows/hides key presses on screen
require "bindFunctionKeys"
--require "characterMapping"
require "editSelection"
require "clipboard"         -- Menu item, does not use SpaceFN or HyperFn keys
local cu						= require "cuChooser"	-- Custom Chooser
foo = cu.new(function () end)

HF.add("Hyper+A     - Enter Application mode, Arrows or Char launches App.\n")
HF.add("Hyper+W     - Enter Webpage mode, Arrows or Char opens web page.\n")

miscFunctions.bind(HyperFn, "L", "lockMyScreen")
miscFunctions.bind(HyperFn, "P", "mdphotoplaceholder")
miscFunctions.bind(HyperFn, "Q", "quitApp")
pasteCurrentSafariUrl.bind(HyperFn, "U", "pasteSafariUrl")
miscFunctions.bind(HyperFn, "V", "typeClipboard")
--HyperFn+"," and HyperFn+"." get intercepted by OS X and will never call Hammerspoon
--miscFunctions.bind({"ctrl", "shift"}, "/", "moveToDone")
--miscFunctions.bind({"ctrl", "shift"}, ",", "moveToStatus")
miscFunctions.bind(HyperFn, "=", "mouseHighlight")
miscFunctions.bind(HyperFn, "-", "manydashes")
miscFunctions.bind(HyperFn, "Z", "mouseToEdge")

HF.add("\n\n-- Window Management Functions --\n")
windowManagement.bind(HyperFn, "Right", "right")
windowManagement.bind(HyperFn, "Left", "left")
windowManagement.bind(HyperFn, "Down", "down")
windowManagement.bind(HyperFn, "Up", "up")
windowManagement.bind(HyperFn, "Home", "home")
windowManagement.bind(HyperFn, "PageUp", "pgup")
windowManagement.bind(HyperFn, "End", "lineend")
windowManagement.bind(HyperFn, "PageDown", "pgdn")
windowManagement.bind(HyperFn, "4", "percent40")
windowManagement.bind(HyperFn, "5", "percent50")
windowManagement.bind(HyperFn, "6", "percent60")
windowManagement.bind(HyperFn, "7", "percent70")
windowManagement.bind(HyperFn, "8", "percent80")
windowManagement.bind(HyperFn, "9", "percent90")
windowManagement.bind(HyperFn, "0", "full")

-- Add list of screens to bottom of Help
local myScreens = "\n\nActive screens:  {"
for i = 1, # hs.screen.allScreens() do
myScreens = myScreens .. " " .. hs.screen.allScreens()[i]:name() .. ","
end
myScreens = myScreens:sub(1, myScreens:len()-1) .. " }"
HF.add(myScreens)

--	Auto-reload config file. Called whenever a *.lua in the directory changes
function reloadConfig(files)
   doReload = false
   for _,file in pairs(files) do
       if file:sub(-4) == ".lua" then
           doReload = true
       end
   end
   if doReload then
       hs.reload()
   end
end
-- Alert "Config loaded" here, happens not as we call reload, but as we load. Default alert durration=2 sec.
hs.alert.show("Config loaded")

local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dev/git/hammerspoon/", reloadConfig):start()
