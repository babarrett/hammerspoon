--	Tutorial:	http://www.hammerspoon.org/go/ 
--	Cycle through displays: http://bezhermoso.github.io/2016/01/20/making-perfect-ramen-lua-os-x-automation-with-hammerspoon/
--	for apps:	hs.hotkey.bind(HyperFn, 'D', function () hs.application.launchOrFocus("Dictionary") end)

--	Hellow world mapped to Hyper=W
HyperFn = {"cmd", "alt", "ctrl", "shift"}

hs.hotkey.bind(HyperFn, "W", function()
 hs.alert.show("Hello World!")
end)

