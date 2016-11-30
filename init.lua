--	Bruce's Hammerspoon functions.

--	For "require" commands
--	TODO: Support better path (there is none yet)
-- "?;?.lua;~/dev/git/hammerspoon/?;?.lua"
LUA_PATH = os.getenv("HOME") .. "/dev/git/hammerspoon/?"

HyperFn = {"cmd", "alt", "ctrl", "shift"}	-- Mash the 4 modifier keys for some new function
HyperFnString = "⌘⌥⌃⇧"

--[[	First we require all modules we'll later use
		Note, as we bind to each function they add to the help string	--]]
HF = require "helpFunctions"	-- global. Other modules call this too.
local pasteCurrentSafariUrl = require "pasteCurrentSafariUrl"
local windowManagement = require "windowManagement"
local miscFunctions = require "miscFunctions"
require "cheatsheets"
require "launch-applications"
require "launchWebPages"
require "simpletest"

HF.bind(HyperFn, "H", "hammerspoonHelp")

HF.add("\n-- Window Management Functions --\n")
windowManagement.bind(HyperFn, "Left", "left")
windowManagement.bind(HyperFn, "Right", "right")
windowManagement.bind(HyperFn, "Up", "up")
windowManagement.bind(HyperFn, "Down", "down")
windowManagement.bind(HyperFn, "4", "percent40")
windowManagement.bind(HyperFn, "5", "percent50")
windowManagement.bind(HyperFn, "6", "percent60")
--		hammerspoonHelp
--		stopHelp
HF.add("\n-- Miscellaneous Functions --\n")
pasteCurrentSafariUrl.bind(HyperFn, "U", "pasteSafariUrl")
miscFunctions.bind(HyperFn, "V", "typeClipboard")
miscFunctions.bind(HyperFn, "Q", "quitApp")
miscFunctions.bind(HyperFn, "W", "closeWindow")
miscFunctions.bind(HyperFn, "D", "dictate")
miscFunctions.bind(HyperFn, "/", "moveToDone")
miscFunctions.bind(HyperFn, ",", "moveToStatus")

HF.add("\nHyper+A     - Enter Application mode, next char launches an App.\n               H for App Launch Help.")

-- Add list of screens to bottom of Help
local myScreens = "\nActive screens: \n  " .. hs.screen.allScreens()[1]:name()
for i = 2, # hs.screen.allScreens() do
	myScreens = myScreens .. "\n  " .. hs.screen.allScreens()[i]:name()
end
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
-- Alert "Config loaded" here, happens not as we call reload, but as we load. Default durration=2 sec.
hs.alert.show("Config loaded")

local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dev/git/hammerspoon/", reloadConfig):start()
