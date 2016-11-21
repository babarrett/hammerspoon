local pasteCurrentSafariUrl = {}

-- Found at: https://github.com/cmsj/hammerspoon-config/blob/master/init.lua
-- Modified to fit my preferred method of adding functions

-- Rather than switch to Safari, copy the current URL, switch back to the previous app and paste,
-- this is a function that fetches the current URL from Safari and types it into the current app.

-- private functions to be referenced & executed later.
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

-- private
local helpString = ""
local funNameToFunction = {
	pasteSafariUrl = typeCurrentSafariURL
}

function pasteCurrentSafariUrl.bind(modifiers, char, functName)
	-- Bind it to HyperFn+U
	HF.add("Hyper+" .. char .. "     - Fetch the current URL from Safari and type it.\n")
	hs.hotkey.bind(modifiers, char, funNameToFunction[functName] )
end

return pasteCurrentSafariUrl
