--	Bruce's Hammerspoon functions.

--	Additional resources:
--		Tutorial:	http://www.hammerspoon.org/go/ 
--		Cycle through displays: http://bezhermoso.github.io/2016/01/20/making-perfect-ramen-lua-os-x-automation-with-hammerspoon/
--		for app binding:	hs.hotkey.bind(HyperFn, 'D', function () hs.application.launchOrFocus("Dictionary") end)

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
HF.bind(HyperFn, "H", "hammerspoonHelp")
HF.bind(HyperFn, "escape", "stopHelp")

windowManagement.updateHelpString()		-- TODO: This should be internal to WindowManagement
--		hammerspoonHelp
--		stopHelp
HF.add("\n")
HF.add("-- Miscellaneous Functions --\n")
pasteCurrentSafariUrl.bind(HyperFn, "U", "pasteSafariUrl")
miscFunctions.bind(HyperFn, "V", "typeClipboard")
miscFunctions.bind(HyperFn, "Q", "quitApp")
miscFunctions.bind(HyperFn, "W", "closeWindow")
miscFunctions.bind(HyperFn, "D", "dictate")
miscFunctions.bind(HyperFn, "/", "moveToDone")
miscFunctions.bind(HyperFn, ",", "moveToStatus")

-- BUG: This should loop through to accumulate active screens.
HF.add("\nActive screens: " 
		.. hs.screen.allScreens()[1]:name() 
		.. ", " 
		.. hs.screen.allScreens()[2]:name() 
		)

--	Auto-reload config file.
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
-- Alert "Reloading" here, happens not as we call reload, but on the next load. Default=2 sec.
hs.alert.show("Config loaded")

local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dev/git/hammerspoon/", reloadConfig):start()
