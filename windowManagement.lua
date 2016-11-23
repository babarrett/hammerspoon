local windowManagement = {}

--	Window to (some) 1/2 of screen (left, right, top, bottom)
--	Taken from: https://gist.github.com/swo/91ec23d09a3d6da5b684
--	HyperFn+Left moves window to left 1/2 of screen.
--	Likewise for other arrows.

--	TODO: Add 4,5,6 to set moved window size to 40, 50, or 60% of screen

-- Private
local helpString = ""
windowSizePercent = 0.50

--[[ function factory that takes the multipliers of screen width
and height to produce the window's x pos, y pos, width, and height ]]
function baseMove(x, y, w, h)
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.w * x
	f.y = max.h * y
	f.w = max.w * w
	f.h = max.h * h
	win:setFrame(f, 0)
end

-- private
local funNameToHelpText = {
	left =		'move window to left of screen.',
	right = 	'move window to right of screen.',
	down = 		'move window to bottom of screen.',
	up =		'move window to top of screen.',
	percent40 =	'Moved windows take 40% of screen',
	percent50 =	'Moved windows take 50% of screen',
	percent60 =	'Moved windows take 60% of screen'
}


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
local funNameToFunction = {
	left = left,
	right = right,
	down = down,
	up = up,
	percent40 = percent40,
	percent50 = percent50,
	percent60 = percent60
}

-- TODO: Is currently binding at load (requires) time.
-- 		Need to make this in response to my bind calls, an only add help lines as we use them
-- y = 0.03 to avoid Mac top menu bar

function windowManagement.bind(modifiers, char, functName)
	hs.hotkey.bind(modifiers, char, funNameToFunction[functName] )	-- bind the key
	-- Add to the help string
	HF.add("Hyper+" .. char .. "     - " .. funNameToHelpText[functName] .. "\n")
end

return windowManagement
