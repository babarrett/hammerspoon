-- Launch Web Pages
-- Patterned, roughly, after: https://github.com/talha131/dotfiles/blob/master/hammerspoon/launch-applications.lua
-- by: Talha Mansoor

launchWebPages = {}
-- Operation:
--	HyperFn+S (Safari) to enter "Web Page mode"
--	<single key> to open a Web Page
--	To leave "Web Page mode" without launching a web page, press Escape.
local modalHekpKey = hs.hotkey.modal.new(HyperFn, 'S', 'Launch Web Page mode')
modalHekpKey:bind('', 'escape', function() modalHekpKey:exit() end)


local webShortCuts = {
    B = {name = 'Bruce\'s Home', addr = 'http://brucebarrett.com/browserhome/brucehome.html'},
    C = {name = 'Confluence', addr = 'https://confluence.aspera.us'},
    F = {name = 'Favorite sites', addr = 'https://jira.aspera.us'},
    J = {name = 'Jira', addr = 'https://jira.aspera.us'},
    T = {name = 'Trac', addr = 'https://trac.aspera.us'}
}

for key, web in pairs(webShortCuts) do
    modalHekpKey:bind('', key, 'Opening '.. web.name, function() hs.execute("open " .. web.addr) end, function() modalHekpKey:exit() end)
end

-- Help for the Web Page launcher
-- First gather all the help text we'll later need
local webHelpText = "Web Page help\n\n"
for key, web in hs.fnutils.sortByKeys(webShortCuts) do
	webHelpText = webHelpText .. tostring(key) .. " - " .. web.name .. "\n"
end

function launchApplications.showHelp()
	hs.alert.show( 
		webHelpText, 
		{textSize=14, textColor={white = 1.0, alpha = 1.00 }, 
		textFont = "Andale Mono",	-- works for me. If missing reverts back to system default
		fillColor={white = 0.0, alpha = 1.00}, 
		strokeColor={red = 1, green=0, blue=0}, strokeWidth=4 }
		, 6	-- display 6 seconds, then dismiss. TODO: Make this a real timer
	)
	modalHekpKey:exit()
end

-- Show help
modalHekpKey:bind('', "H", nil, function() launchApplications.showHelp() end, function() modalHekpKey:exit() end)

return launchWebPages
