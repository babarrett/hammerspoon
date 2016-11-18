--	Window to (some) 1/2 of screen (left, right, top, bottom)
--	Taken from: https://gist.github.com/swo/91ec23d09a3d6da5b684
--	Hyper+Left moves window to left 1/2 of screen.
--	Likewise for Right, Up, Down to the right half, lower half, top half.

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
hs.hotkey.bind(HYPER_MODIFIER, 'Left',  baseMove(0.00, 0.00, 0.49, 1.00))
hs.hotkey.bind(HYPER_MODIFIER, 'Right', baseMove(0.51, 0.00, 0.49, 1.00))
hs.hotkey.bind(HYPER_MODIFIER, 'Down',  baseMove(0.00, 0.51, 1.00, 0.49))
hs.hotkey.bind(HYPER_MODIFIER, 'Up',    baseMove(0.00, 0.00, 1.00, 0.49))
