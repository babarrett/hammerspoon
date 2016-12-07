--	Bruce's Hammerspoon functions.

--	For "require" commands
--	TODO: Support better path (there is none yet)
-- "?;?.lua;~/dev/git/hammerspoon/?;?.lua"

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
--require "KeyPressShow"

HF.add("-- Window Management Functions --\n")
windowManagement.bind(HyperFn, "Left", "left")
windowManagement.bind(HyperFn, "Right", "right")
windowManagement.bind(HyperFn, "Up", "up")
windowManagement.bind(HyperFn, "Down", "down")
windowManagement.bind(HyperFn, "4", "percent40")
windowManagement.bind(HyperFn, "5", "percent50")
windowManagement.bind(HyperFn, "6", "percent60")
windowManagement.bind(HyperFn, "7", "percent70")

HF.add("\n-- Miscellaneous Functions --\n")
HF.bind(HyperFn, "H", "hammerspoonHelp")
pasteCurrentSafariUrl.bind(HyperFn, "U", "pasteSafariUrl")
miscFunctions.bind(HyperFn, "V", "typeClipboard")
miscFunctions.bind(HyperFn, "Q", "quitApp")
miscFunctions.bind(HyperFn, "W", "closeWindow")
miscFunctions.bind(HyperFn, "D", "dictate")
--HyperFn+, and HyperFn+. get intercepted by OS X and will never call Hammerspoon
--miscFunctions.bind({"ctrl", "shift"}, "/", "moveToDone")
--miscFunctions.bind({"ctrl", "shift"}, ",", "moveToStatus")
HF.add("Hyper+A     - Enter Application mode, Arrows or Char launches App.")

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
-- Alert "Config loaded" here, happens not as we call reload, but as we load. Default alert durration=2 sec.
hs.alert.show("Config loaded")

local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dev/git/hammerspoon/", reloadConfig):start()
