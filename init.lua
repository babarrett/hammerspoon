--	Bruce's Hammerspoon functions.

--	For "require" commands
--	TODO: Support better path (there is none yet)
-- "?;?.lua;~/dev/git/hammerspoon/?;?.lua"
--	TODO: Create another modual for KeyToKey mappings such as Numeric Pad to move functions.

VERSION = "2016-Dec-20"
hs.console.clearConsole()
LUA_PATH = os.getenv("HOME") .. "/dev/git/hammerspoon/?"

HyperFn = {"cmd", "alt", "ctrl", "shift"}	-- Mash the 4 modifier keys for some new function
HyperFnString = "⌘⌥⌃⇧"					-- Visual representation

-- log debug info to Hyperspoon Console
-- We can disable all logging in one place
function debuglog(text) 
  hs.console.printStyledtext("DEBUG: "..text) 
end


--[[	First we require all modules we'll later use
		Note, as we bind to each function they add to the help string	--]]
HF 								= require "helpFunctions"	-- global. Other modules call this too.
local pasteCurrentSafariUrl 	= require "pasteCurrentSafariUrl"
local windowManagement 			= require "windowManagement"
local miscFunctions 			= require "miscFunctions"
local cheatsheets				= require "cheatsheets"
local launchApplications		= require "launchApplications"
--require "launchWebPages"		-- TODO: either add into HyperFn+A (apps table) or clone that code for HyperFn+S
require "KeyPressShow"
--require "characterMapping"

HF.add("-- Miscellaneous Functions -- "..VERSION.." --\n")
HF.bind(HyperFn, "H", "hammerspoonHelp")
pasteCurrentSafariUrl.bind(HyperFn, "U", "pasteSafariUrl")
miscFunctions.bind(HyperFn, "V", "typeClipboard")
miscFunctions.bind(HyperFn, "Q", "quitApp")
miscFunctions.bind(HyperFn, "W", "closeWindow")
miscFunctions.bind(HyperFn, "D", "dictate")
--HyperFn+, and HyperFn+. get intercepted by OS X and will never call Hammerspoon
--miscFunctions.bind({"ctrl", "shift"}, "/", "moveToDone")
--miscFunctions.bind({"ctrl", "shift"}, ",", "moveToStatus")
miscFunctions.bind(HyperFn, "=", "mouseHighlight")
miscFunctions.bind(HyperFn, "L", "lockMyScreen")

HF.add("Hyper+A     - Enter Application mode, Arrows or Char launches App.")

HF.add("\n\n-- Window Management Functions --\n")
windowManagement.bind(HyperFn, "Right", "right")
windowManagement.bind(HyperFn, "Left", "left")
windowManagement.bind(HyperFn, "Down", "down")
windowManagement.bind(HyperFn, "Up", "up")
windowManagement.bind(HyperFn, "4", "percent40")
windowManagement.bind(HyperFn, "5", "percent50")
windowManagement.bind(HyperFn, "6", "percent60")
windowManagement.bind(HyperFn, "7", "percent70")

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
