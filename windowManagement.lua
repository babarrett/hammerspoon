local windowManagement = {}

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

-- TODO: Is currently binding at load (requires) time.
-- 		Need to make this in response to my bind calls
-- y = 0.03 to avoid Mac top menu bar
hs.hotkey.bind(HyperFn, 'Left',  baseMove(0.00, 0.03, 0.49, 1.00))
hs.hotkey.bind(HyperFn, 'Right', baseMove(0.51, 0.03, 0.49, 1.00))
hs.hotkey.bind(HyperFn, 'Down',  baseMove(0.00, 0.51, 0.98, 0.49))
hs.hotkey.bind(HyperFn, 'Up',    baseMove(0.00, 0.03, 0.98, 0.46))

function windowManagement.updateHelpString()
	HF.add("-- Window Management Help --\n")
	HF.add("Hyper-Left  - move window to left 1/2 of screen.\n")
	HF.add("Hyper-Right - move window to right 1/2 of screen.\n")
	HF.add("Hyper-Up    - move window to top 1/2 of screen.\n")
	HF.add("Hyper-Down  - move window to bottom 1/2 of screen.\n")
end

return windowManagement
