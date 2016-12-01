-- Launch applications
-- from: https://github.com/talha131/dotfiles/blob/master/hammerspoon/launch-applications.lua
-- by: Talha Mansoor

launchApplications = {}
-- Operation:
--	HyperFn+A to enter "Application mode"
--	<single key> to launch an application
--	To leave "Application mode" without launching an application press Escape.
local modalKey = hs.hotkey.modal.new(HyperFn, 'A', 'Launch Application mode')
modalKey:bind('', 'escape', 'Exiting Launch Application mode', function() modalKey:exit() end)

local appShortCuts = {
    B = 'BBEdit',
    C = 'Chrome',
    F = 'Finder',
    I = 'iTerm',
    M = 'Mail',
    N = 'Notetaker',
    P = 'System Preferences',
    S = 'Safari',
    X = 'Firefox',
}

for key, app in pairs(appShortCuts) do
    modalKey:bind('', key, 'Launching '..app, function()
      hs.application.launchOrFocus(app) end, 
      function() modalKey:exit() end)
end

-- Help for the App launcher
-- First gather all the help text we'll later need
local appHelpText = "Application help\n"
for key, app in hs.fnutils.sortByKeys(appShortCuts) do
	appHelpText = appHelpText .. tostring(key) .. " - " .. app .. "\n"
end

local modalHelpKey = hs.hotkey.modal.new(HyperFn, 'A', 'Launch Application mode')
modalHelpKey:bind('', 'escape', function() modalHelpKey:exit() end)

function launchApplications.showHelp()
	hs.alert.show( 
		appHelpText, 
		{textSize=14, textColor={white = 1.0, alpha = 1.00 }, 
		textFont = "Andale Mono",	-- works for me. If missing reverts back to system default
		fillColor={white = 0.0, alpha = 1.00}, 
		strokeColor={red = 1, green=0, blue=0}, strokeWidth=4 }
		, 6	-- display 6 seconds, t
	)
	hs.alert.show('Exiting App HELP')
	modalHelpKey:exit()
end

modalHelpKey:bind('', "H", nil, function() launchApplications.showHelp() end, 
  function() hs.alert.show('Exiting App HELP')
    modalHelpKey:exit() end)

return launchApplications
