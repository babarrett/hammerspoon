--	Bruce's Hammerspoon functions.

--	Additional resources:
--		Tutorial:	http://www.hammerspoon.org/go/ 
--		Cycle through displays: http://bezhermoso.github.io/2016/01/20/making-perfect-ramen-lua-os-x-automation-with-hammerspoon/
--		for app binding:	hs.hotkey.bind(HyperFn, 'D', function () hs.application.launchOrFocus("Dictionary") end)

--	For "requires" commands
LUA_PATH = "?;?.lua;~/dev/git/hammerspoon/?.lua"

HyperFn = {"cmd", "alt", "ctrl", "shift"}	-- Mash the 4 modifier keys for some new function

require "windowManagement"
require "pastecurrentsafariurl"

--	TODO: This is a test, delete later (soon)
--	Hello world mapped to HyperFn+W
hs.hotkey.bind(HyperFn, "W", function()
  hs.alert.show("Hello World!")
end)

--	"Help" - brief descriptions of mapped f()s. 
--	HyperFn+H to show
--	HyperFn+Esc to stop showing before it times out
helpAlertUUID = nil

hs.hotkey.bind(HYPER_MODIFIER, "H", function()
	if helpAlertUUID ~= nil then
		hs.alert.closeSpecific(helpAlertUUID)
	end
	helpAlertUUID = hs.alert.show( "Help for Bruce's Hammerspoon functions:\n" 
	.. "Hyper-Left  - move window to left 1/2 of screen.\n"
	.. "Hyper-Right - move window to right 1/2 of screen.\n"
	.. "Hyper-Up    - move window to top 1/2 of screen.\n"
	.. "Hyper-Down  - move window to bottom 1/2 of screen.\n"
	.. "Hyper-V     - paste clipboard as text (avoid web site CMD-V blockers).\n"
	.. "\n"
	-- BUG: This should loop through to accumulate active screens.
	.. "Active screens: " .. hs.screen.allScreens()[1]:name() .. ", " .. hs.screen.allScreens()[2]:name() .. "\n"
	, 
	{textSize=14, textColor={white = 1.0, alpha = 1.00 }, 
	textFont = "Andale Mono",	-- works for me. If missing reverts back to system default
	fillColor={white = 0.0, alpha = 1.00}, 
	strokeColor={red = 1, green=0, blue=0}, strokeWidth=4 }
	, 6	-- display 6 seconds
	)
  
end)

--Stop displaying Help if you've read it all
hs.hotkey.bind(HYPER_MODIFIER, "escape", function()
	hs.console.printStyledtext("found Esc")
	if alertUUID ~= nil then
		hs.alert.closeSpecific(alertUUID)
		alertUUID = nil
	else
		hs.eventtap.keyStroke({}, "escape")
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
local myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")


