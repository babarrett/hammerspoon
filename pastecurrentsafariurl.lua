-- Found at: https://github.com/cmsj/hammerspoon-config/blob/master/init.lua

-- Rather than switch to Safari, copy the current URL, switch back to the previous app and paste,
-- this is a function that fetches the current URL from Safari and types it into the current app.

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

-- Bind it to HyperFn+u
hs.hotkey.bind(HyperFn, 'u', typeCurrentSafariURL)
