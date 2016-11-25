-- Launch applications
-- from: https://github.com/talha131/dotfiles/blob/master/hammerspoon/launch-applications.lua
-- by: Talha Mansoor

launchApplications = {}
-- Operation:
--	HyperFn+A to enter "Application mode"
--	<single key> to launch an application
--	To leave "Application mode" without launching an application press Escape.
local modalKey = hs.hotkey.modal.new(HyperFn, 'A', 'Launch Application mode')
modalKey:bind('', 'escape', function() modalKey:exit() end)

local appShortCuts = {
    B = 'BBEdit',
    C = 'Chrome',
    F = 'Finder',
    I = 'iterm',
    M = 'Mail',
    P = 'System Preferences',
    S = 'Safari',
    X = 'Firefox',
}

for key, app in pairs(appShortCuts) do
    modalKey:bind('', key, 'Launching '..app, function() hs.application.launchOrFocus(app) end, function() modalKey:exit() end)
end

return launchApplications
