--	Tutorial:	http://www.hammerspoon.org/go/ 
--	Cycle through displays: http://bezhermoso.github.io/2016/01/20/making-perfect-ramen-lua-os-x-automation-with-hammerspoon/
--	for apps:	hs.hotkey.bind(HyperFn, 'D', function () hs.application.launchOrFocus("Dictionary") end)

--	Hellow world mapped to Hyper=W
HyperFn = {"cmd", "alt", "ctrl", "shift"}

hs.hotkey.bind(HyperFn, "W", function()
 hs.alert.show("Hello World!")
end)

-- Found at: https://github.com/cmsj/hammerspoon-config/blob/master/init.lua
-- Rather than switch to Safari, copy the current URL, switch back to the previous app and paste,
-- This is a function that fetches the current URL from Safari and types it
function typeCurrentSafariURL()
    script = [[
    tell application "Safari"
        set currentURL to URL of document 1
    end tell
    return currentURL
    ]]
    ok, result = hs.applescript(script)
    if (ok) then
        hs.eventtap.keyStrokes(result)
    end
end

hs.hotkey.bind(HyperFn, 'u', typeCurrentSafariURL)
