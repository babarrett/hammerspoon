--	Bruce's Hammerspoon functions.

--	Additional resources:
--		Tutorial:	http://www.hammerspoon.org/go/ 
--		Cycle through displays: http://bezhermoso.github.io/2016/01/20/making-perfect-ramen-lua-os-x-automation-with-hammerspoon/
--		for app binding:	hs.hotkey.bind(HyperFn, 'D', function () hs.application.launchOrFocus("Dictionary") end)

--	For "require" commands
--	TODO: test & perfect
--	TODO: generic path (this is OS X and Linux only)
LUA_PATH = os.getenv("HOME") .. "/dev/git/hammerspoon/?"
-- "?;?.lua;~/dev/git/hammerspoon/?;?.lua"

HyperFn = {"cmd", "alt", "ctrl", "shift"}	-- Mash the 4 modifier keys for some new function

local pasteCurrentSafariUrl = require "pasteCurrentSafariUrl"
local windowManagement = require "windowManagement"
local ST = require "simpleTest"
ST.bind(HyperFn, "X", "myName1")
pasteCurrentSafariUrl.bind(HyperFn, "U", "pasteSafariUrl")

local helpString = "Bruce's Hammerspoon functions\n"

-- accumulate help strings
helpString = helpString .. pasteCurrentSafariUrl.getHelpString()
helpString = helpString .. windowManagement.getHelpString()

--hs.alert.show(helpString, 
--	{textSize=16, textColor={white = 1.0, alpha = 1.00 }, 
--	textFont = "Andale Mono",	-- works for me. If missing reverts back to system default
--	fillColor={white = 0.0, alpha = 1.00}, 
--	strokeColor={red = 1, green=0, blue=0}, strokeWidth=4 }
--	, 3	-- display 3 seconds
--	)


--	"Help" - brief descriptions of mapped f()s. 
--	HyperFn+H to show
--	HyperFn+Esc to stop showing before it times out
helpAlertUUID = nil

-- #mark H=Help
hs.hotkey.bind(HyperFn, "H", function()
	if helpAlertUUID ~= nil then
		hs.alert.closeSpecific(helpAlertUUID)
	end
	helpAlertUUID = hs.alert.show( "Help for Bruce's Hammerspoon functions:\n" 
	.. pasteCurrentSafariUrl.getHelpString()
	.. "Hyper-V     - Type clipboard as text (avoid web site CMD-V blockers).\n"
	.. windowManagement.getHelpString()
	.. "\n"
	-- BUG: This should loop through to accumulate active screens.
	.. "Active screens: " .. hs.screen.allScreens()[1]:name() .. ", " .. hs.screen.allScreens()[2]:name() 
	, 
	{textSize=14, textColor={white = 1.0, alpha = 1.00 }, 
	textFont = "Andale Mono",	-- works for me. If missing reverts back to system default
	fillColor={white = 0.0, alpha = 1.00}, 
	strokeColor={red = 1, green=0, blue=0}, strokeWidth=4 }
	, 6	-- display 6 seconds
	)
	-- DEBUG:  hs.console.printStyledtext(string.gsub(package.path, ";", "\n"))

end)

--Stop displaying Help if you've read it all
hs.hotkey.bind(HyperFn, "escape", function()
	if helpAlertUUID ~= nil then
		hs.alert.closeSpecific(helpAlertUUID)
		helpAlertUUID = nil
	end
end)

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
hs.alert.show("Config loaded")	-- Alert "Reloading" here, happens not as we call reload, but on the next load. Default=2 sec.

local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/dev/git/hammerspoon/", reloadConfig):start()
