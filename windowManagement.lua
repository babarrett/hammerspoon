windowManagement = {}

--	Window to (some) 1/2 of screen (left, right, top, bottom)
--	Taken from: https://gist.github.com/swo/91ec23d09a3d6da5b684
--	HyperFn+Left moves window to left 1/2 of screen.
--	Likewise for other arrows.

-- Private
local helpString = ""


--[[ function factory that takes the multipliers of screen width
and height to produce the window's x pos, y pos, width, and height ]]
function baseMove(x, y, w, h)
    return function()
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
end
-- y = 0.03 to avoid Mac top menu bar
hs.hotkey.bind(HyperFn, 'Left',  baseMove(0.00, 0.03, 0.49, 1.00))
hs.hotkey.bind(HyperFn, 'Right', baseMove(0.51, 0.03, 0.49, 1.00))
hs.hotkey.bind(HyperFn, 'Down',  baseMove(0.00, 0.51, 0.90, 0.49))
hs.hotkey.bind(HyperFn, 'Up',    baseMove(0.00, 0.03, 0.90, 0.46))

function windowManagement.getHelpString()
	helpString = "-- Window Management Help --\n"
	helpString = helpString .. "Hyper-Left  - move window to left 1/2 of screen.\n"
	helpString = helpString .. "Hyper-Right - move window to right 1/2 of screen.\n"
	helpString = helpString .. "Hyper-Up    - move window to top 1/2 of screen.\n"
	helpString = helpString .. "Hyper-Down  - move window to bottom 1/2 of screen.\n"
	return helpString
end

return windowManagement
