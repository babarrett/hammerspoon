--	Window to (some) 30,40,..70% of screen (left, right, top, bottom)
--	Originally taken from: https://gist.github.com/swo/91ec23d09a3d6da5b684
--	HyperFn+Left moves window to left part of the screen.
--	Likewise for other arrows.
--	BUG: Moves windows from off of other screens to "main" (laptop) screen.

local windowManagement = {}

-- Private
local helpString = ""
windowSizePercent = 0.50

--[[ function factory that takes the multipliers of screen width
and height to produce the window's x pos, y pos, width, and height ]]
function baseMove(x, y, w, h)
	local win = hs.window.frontmostWindow()
	debuglog("win: " .. tostring(win))
	if win ~= nil then	-- only if there's a window to move
		local screen = win:screen()
		local wf = win:frame()
		local sf = screen:frame()
		
--		These were all messed up for other than the primary screen. Fixed
--		f.x = max.w * x
--		f.y = max.h * y
--		f.w = max.w * w
--		f.h = max.h * h
		wf.x = sf.x + sf.w * x
		wf.y = sf.y + sf.h * y
		wf.w = sf.w * w
		wf.h = sf.h * h
		win:setFrame(wf, 0)
	end
end

-- private
local funNameToHelpText = {
	left =		'move window to left of screen.',
	right = 	'move window to right of screen.',
	down = 		'move window to bottom of screen.',
	up =		'move window to top of screen.',
	percent40 =	'Moved windows take 40% of screen',
	percent50 =	'Moved windows take 50% of screen',
	percent60 =	'Moved windows take 60% of screen',
	percent70 =	'Moved windows take 70% of screen'
}


-- y = 0.03 to avoid Mac screen menu bar
local function left()
	baseMove(0.00, 0.03, windowSizePercent-0.01, 1.00)
end
local function right()
	baseMove(1-windowSizePercent+0.01, 0.03, windowSizePercent-0.01, 1.00)
end
local function down()
	baseMove(0.00, 1-windowSizePercent+0.01, 0.98,  windowSizePercent-0.01)
end
local function up()
	baseMove(0.00, 0.03, 0.98,  windowSizePercent-0.03)
end
local function percent40()
	windowSizePercent = 0.40
end
local function percent50()
	windowSizePercent = 0.50
end
local function percent60()
	windowSizePercent = 0.60
end
local function percent70()
	windowSizePercent = 0.70
end
local funNameToFunction = {
	left = left,
	right = right,
	down = down,
	up = up,
	percent40 = percent40,
	percent50 = percent50,
	percent60 = percent60,
	percent70 = percent70
}

function windowManagement.bind(modifiers, char, functName)
	hs.hotkey.bind(modifiers, char, funNameToFunction[functName] )	-- bind the key
	-- Add to the help string
	HF.add("Hyper+" .. char .. "     - " .. funNameToHelpText[functName] .. "\n")
end

-- TODO: Want to save screen & window locations when there are multiple screens
-- and the computer sleeps.
-- On wake, and there is only 1 screen, leave the location variables untouched.
-- On wake, when there are multiple screens, restore the windows to their old 
-- screens & locations. 

return windowManagement
