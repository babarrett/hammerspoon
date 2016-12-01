-- Launch Applications
-- (TODO: Can also be used for websites)
-- Displays a NxN grid of App names and short-cut letters
-- User can use arrow keys to select an app to switch to, 
-- Enter or Space to switch. Or may use short-cut letters
-- to switch. Or Escape to cancel.
-- by: Bruce Barrett

launchApplications2 = {}
-- Operation:
--	HyperFn+A to enter "Application mode"
--	arrow keys to select an app to switch to.
--	Enter or Space to switch.
--	<single key> to launch an application
--	To leave "Application mode" without launching an application press Escape.

local DEFAULTBROWSER = 'Safari'

-- Format is:
--   Key_to_press. A single key
--   Object with up to 3 items:
--     DisplayText
--     App to launch, or nil
--     Web site to open, or nil
local appShortCuts = {
    B = {'BBEdit', 'BBEdit', nil},
    C = {'Chrome', 'Chrome', nil},
    F = {'Finder', 'Finder', nil},
    I = {'iTerm', 'iTerm', nil},
    M = {'Mail', 'Mail', nil},
    N = {'Notetaker', 'Notetaker', nil},
    P = {'System Preferences', 'System Preferences', nil},
    S = {'Safari', 'Safari', nil},
    X = {'Firefox', 'Firefox', nil},
}

-- Build Help alert string
local helpAlertText = 'Launch Application mode\n\n'
for key, appInfo in hs.fnutils.sortByKeys(appShortCuts) do
    helpAlertText = helpAlertText .. key .. ": " .. appInfo[1] .. "\n"
end

-- Build a 3x3 grid of app names
local xmin =0
local xmax =2
local ymin =0
local ymax =2

local xsel = math.floor((xmax-xmin)/2)
local ysel = math.floor((ymax-ymin)/2)

local launchAppActive = nil		-- Inactive

local modalKey = hs.hotkey.modal.new(HyperFn, 'A', helpAlertText)
--	Bind keys of interest
--	hs.hotkey.modal:bind(mods, key, message, pressedfn, releasedfn, repeatfn) -> hs.hotkey.modal object

-- Completion keys
	modalKey:bind('', 'escape', 'Exiting Launch Application mode', 
		function() 
		launchAppActive = nil
		modalKey:exit() end)
	modalKey:bind('', 'space', 'Launching current seleccted App', 
		function() 
		launchAppActive = nil
		-- TODO: Launch App
		modalKey:exit() end)
	modalKey:bind('', 'return', 'Launching current seleccted App', 
		function() 
		launchAppActive = nil
		-- TODO: Launch App
		modalKey:exit() end)

-- arrow keys
	-- insert jikl or wasd as arrow keys here too, if you wish.
	modalKey:bind('', 'left', nil, 
		function() 
		xsel = math.max(xmin, xsel-1)
		end)
	modalKey:bind('', 'right', nil, 
		function() 
		xsel = math.min(xmax, xsel+1)
		end)
	modalKey:bind('', 'up', nil, 
		function() 
		xsel = math.max(ymin, ysel-1)
		end)
	modalKey:bind('', 'down', nil, 
		function() 
		xsel = math.min(ymax, ysel+1)
		end)


-- App launch keys (defined in appShortCuts)
-- Pick up Applications to offer, sorted by activation key
for key, appInfo in hs.fnutils.sortByKeys(appShortCuts) do
    -- TODO: Test App for nil and Web site for != nil, open website instead
    modalKey:bind('', key, 'Launching '..appInfo[2], 
      function() hs.application.launchOrFocus(appInfo[2]) end,	-- Key down, launch
      function() modalKey:exit() end)							-- Key up, leave mode
end

-- Help for the App launcher
-- First gather all the help text we'll later need
--local appHelpText = "Application help\n"
--for key, app in hs.fnutils.sortByKeys(appShortCuts) do
--	appHelpText = appHelpText .. tostring(key) .. " - " .. app .. "\n"
--end
--
--local modalHelpKey = hs.hotkey.modal.new(HyperFn, 'A', 'Launch Application mode')
--modalHelpKey:bind('', 'escape', function() modalHelpKey:exit() end)
--
--function launchApplications2.showHelp()
--	hs.alert.show( 
--		appHelpText, 
--		{textSize=14, textColor={white = 1.0, alpha = 1.00 }, 
--		textFont = "Andale Mono",	-- works for me. If missing reverts back to system default
--		fillColor={white = 0.0, alpha = 1.00}, 
--		strokeColor={red = 1, green=0, blue=0}, strokeWidth=4 }
--		, 6	-- display 6 seconds, t
--	)
--	hs.alert.show('Exiting App HELP')
--	modalHelpKey:exit()
--end
--
--modalHelpKey:bind('', "H", nil, function() launchApplications2.showHelp() end, 
--  function() hs.alert.show('Exiting App HELP')
--    modalHelpKey:exit() end)

return launchApplications2
