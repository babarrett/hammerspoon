--	Tutorial:	http://www.hammerspoon.org/go/ 
--	Cycle through displays: http://bezhermoso.github.io/2016/01/20/making-perfect-ramen-lua-os-x-automation-with-hammerspoon/
--	for apps:	hs.hotkey.bind(HyperFn, 'D', function () hs.application.launchOrFocus("Dictionary") end)

HyperFn = {"cmd", "alt", "ctrl", "shift"}	-- Mash the 4 modifier keys for some new function

--	Hello world mapped to HyperFn+W
hs.hotkey.bind(HyperFn, "W", function()
  hs.alert.show("Hello World!")
end)
