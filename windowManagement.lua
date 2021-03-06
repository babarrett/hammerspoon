--	Move window to (some) 40,..90% of screen (left, right, top, bottom)
--	Originally taken from: https://gist.github.com/swo/91ec23d09a3d6da5b684
--	HyperFn+Left moves window to left part of the screen.
--	Likewise for other arrows.
--	HyperFn+0 centers at the currently selected size of full screen
--	If the window is already in place (say left edge) and we get another left
--	command then move it to the *screen* to the left.

--  If you find this insufficient, you may try: https://github.com/koekeishiya/chunkwm

local windowManagement = {}

-- Private
local helpString = ""
windowSizePercent = 0.50
newScreen = nil

--[[ function factory that takes the multipliers of screen width
and height to produce the window's x pos, y pos, width, and height ]]
function baseMove(x, y, w, h, direction)
	local win = hs.window.frontmostWindow()
	local fudge = 40
	if win ~= nil then	-- only if there's a window to move
		local screen = win:screen()
		local wfold = win:frame()
		local wfnew = win:frame()
		local sf = screen:frame()
--		debuglog("-------------------------------------------\nScreen Frame rect (x, y, w, h): "..sf.x..", "..sf.y..", "..sf.w..", "..sf.h)
		wfnew.x = math.floor(sf.x + sf.w * x)
		wfnew.y = math.floor(sf.y + sf.h * y)
		wfnew.w = math.floor(sf.w * w)
		wfnew.h = math.floor(sf.h * h)
--		debuglog("-------------------------------------------\nwfnew  Frame rect (x, y, w, h): "..wfnew.x..", "..wfnew.y..", "..wfnew.w..", "..wfnew.h)
		-- Now see if this = no change... in which case we'll push it to the next screen
--		debuglog("x fudge: ".. math.abs(wfold.x - wfnew.x))
--		debuglog("y fudge: ".. math.abs(wfold.y - wfnew.y))
--		debuglog("w fudge: ".. math.abs(wfold.w - wfnew.w))
--		debuglog("h fudge: ".. math.abs(wfold.h - wfnew.h))
		if (math.abs(wfold.x - wfnew.x) < fudge
		and math.abs(wfold.y - wfnew.y) < fudge
		and math.abs(wfold.w - wfnew.w) < fudge
		and math.abs(wfold.h - wfnew.h) < fudge) then
			action = {
				["left"] =	function () windowManagement.newScreen = screen:toWest(nil, true) end,
				["right"] =	function () windowManagement.newScreen = screen:toEast(nil, true) end,
				["up"] =	function () windowManagement.newScreen = screen:toNorth(nil, true) end,
				["down"] =	function () windowManagement.newScreen = screen:toSouth(nil, true) end,

				["NW"] =	function () windowManagement.newScreen = screen:toWest(nil, true) end,
				["NE"] =	function () windowManagement.newScreen = screen:toEast(nil, true) end,
				["SW"] =	function () windowManagement.newScreen = screen:toWest(nil, true) end,
				["SE"] =	function () windowManagement.newScreen = screen:toEast(nil, true) end
			}
			action[direction]()

			-- test to see if there is a screen to move to...
--			debuglog("window within fudge factor, push to next screen, if available.")
			if windowManagement.newScreen then
--				debuglog("OK to move to next screen: "..direction)
				sf = windowManagement.newScreen:frame()
				wfnew.x = math.floor(sf.x + sf.w * x)
				wfnew.y = math.floor(sf.y + sf.h * y)
				wfnew.w = math.floor(sf.w * w)
				wfnew.h = math.floor(sf.h * h)

			end
		end
		win:setFrame(wfnew, 0)
	end
end

-- private
local funNameToHelpText = {
	-- arrow kwys:
	left =		'move window to left of screen.',
	right = 	'move window to right of screen.',
	down = 		'move window to bottom of screen.',
	up =		  'move window to top of screen.',

	home =    'move window to top-left of screen.',
	pgup =    'move window to top-right of screen.',
	lineend = 'move window to bottom-left of screen.',
	pgdn =    'move window to bottom-right of screen.',

	full =		'center window at current % size.',
	percent40 =	'Set moved window size to 40% of screen',
	percent50 =	'Set moved window size to 50% of screen',
	percent60 =	'Set moved window size to 60% of screen',
	percent70 =	'Set moved window size to 70% of screen',
	percent80 =	'Set moved window size to 80% of screen',
	percent90 =	'Set moved window size to 90% of screen'
}


-- y = 0.03 to avoid Mac screen menu bar
local function left()
	baseMove(0.00, 0.00, windowSizePercent-0.01, 0.98, "left")
end
local function right()
	baseMove(1-windowSizePercent+0.01, 0.00, windowSizePercent-0.01, 0.98 , "right")
end
local function down()
	baseMove(0.01, 1-windowSizePercent+0.01, 0.98,  windowSizePercent-0.02, "down")
end
local function up()
	baseMove(0.01, 0.02, 0.98,  windowSizePercent-0.02, "up")
end
-------------------------------------------
local function home()
	baseMove(0.01, 0.02, windowSizePercent-0.02,  windowSizePercent-0.02, "NW")
end
local function pgup()
	baseMove(1-windowSizePercent+0.01, 0.02, windowSizePercent-0.02,  windowSizePercent-0.02, "NE")
end
local function lineend()  -- End key
	baseMove(0.01, 1-windowSizePercent+0.01, windowSizePercent-0.02,  windowSizePercent-0.02, "SW")
end
local function pgdn()
	baseMove(1-windowSizePercent+0.01, 1-windowSizePercent+0.01, windowSizePercent-0.02,  windowSizePercent-0.02, "SE")
end
-------------------------------------------
local function full()
	baseMove(0.50-(windowSizePercent/2)-0.02, 0.50-(windowSizePercent/2)-0.02, windowSizePercent+0.04, windowSizePercent+0.04, "full")
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
local function percent80()
	windowSizePercent = 0.80
end
local function percent90()
	windowSizePercent = 0.95  -- sic.
end
local funNameToFunction = {
	left = left,
	right = right,
	down = down,
	up = up,
	home =      home,
  pgup =      pgup,
  lineend =   lineend,
  pgdn =      pgdn,

	full = full,
	percent40 = percent40,
	percent50 = percent50,
	percent60 = percent60,
	percent70 = percent70,
	percent80 = percent80,
	percent90 = percent90

}

function windowManagement.bind(modifiers, char, functName)
	hs.hotkey.bind(modifiers, char, funNameToFunction[functName] )	-- bind the key
	-- Add to the help string
	HF.add("Hyper+" .. char .. "     - " .. funNameToHelpText[functName] .. "\n")
end

-- TODO: Want to save screen & window locations when there are multiple screens
-- and the computer is about to sleep.
-- On wake, and there is only 1 screen, leave the location variables untouched.
-- On wake, when there are multiple screens, restore the windows to their old
-- screens & locations as best we can. Matching screen sizes and positions.

return windowManagement
