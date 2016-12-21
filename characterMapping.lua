local characterMapping = {}
-- Numeric pad to match older USB Overdrive settings, Bruce
-- Numeric Pad to common, desired functions (Bruce)
-- Should work on:
--	Razer
--	External numeric pad
-- For example:
--	pad1:	Opt-<--	Move left 1 word
--	pad2:	Opt--->	Move right 1 word
--	pad1:	Opt-<--	Move left end of line
--	pad2:	Opt--->	Move right end of line
-- Notice, pad0, which maps to "shift", is not "sticky" like all the other keyboard shift keys.

--	From Key...					To Key...
--	hs.hotkey.bind(mods, key, message, pressedfn, releasedfn, repeatfn) --> hs.hotkey object

	hs.hotkey.bind(nil, "pad0", nil, function() hs.eventtap.keyStroke({"shift"}) end, nil, nil)
	hs.hotkey.bind(nil, "pad1", nil, function() hs.eventtap.keyStroke({"alt", "left"}) end, nil, nil)
	hs.hotkey.bind(nil, "pad2", nil, function() hs.eventtap.keyStroke({"alt", "right"}) end, nil, nil)
	hs.hotkey.bind(nil, "pad3", nil, function() hs.eventtap.keyStroke(L, {"cmd"}) end, nil, nil)	<!-- broken -->
	hs.hotkey.bind(nil, "pad4", nil, function() hs.eventtap.keyStroke({"cmd", "left"}) end, nil, nil)
	hs.hotkey.bind(nil, "pad5", nil, function() hs.eventtap.keyStroke({"cmd", "right"}) end, nil, nil)
	hs.hotkey.bind(nil, "pad6", nil, function() hs.eventtap.keyStroke({"cmd", "shift"}, "[") end, nil, nil)
	hs.hotkey.bind(nil, "pad7", nil, function() hs.eventtap.keyStroke(F, {"cmd"}) end, nil, nil)
	hs.hotkey.bind(nil, "pad8", nil, function() hs.eventtap.keyStroke(G, {"cmd"}) end, nil, nil)
	hs.hotkey.bind(nil, "pad9", nil, function() hs.eventtap.keyStroke({"cmd", "shift"}, "]") end, nil, nil)

	hs.hotkey.bind(nil, "pad.", nil, function() hs.eventtap.keyStroke("tab") end, nil, nil)
	hs.hotkey.bind(nil, "pad-", nil, function() hs.eventtap.keyStroke({"cmd", "shift"}, "]") end, nil, nil)	<!-- broken -->
	hs.hotkey.bind(nil, "pad*", nil, function() hs.eventtap.keyStroke({"cmd", "shift"}, "[") end, nil, nil)	<!-- broken -->
	hs.hotkey.bind(nil, "pad+", nil, function() hs.eventtap.keyStroke({"cmd"}, "]") end, nil, nil)
	hs.hotkey.bind(nil, "pad/", nil, function() hs.eventtap.keyStroke("space", {"cmd"}) end, nil, nil)
	hs.hotkey.bind(nil, "padenter", nil, function() hs.eventtap.keyStroke({"cmd"}, "[" ) end, nil, nil)
--	hs.hotkey.bind(nil, "padclear", 


--"fn", "ctrl", "alt", "cmd", "shift", "fn"
--hs.eventtap.keyStroke({"cmd"}, "v"))
--
--f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15,
--f16, f17, f18, f19, f20, pad, pad*, pad+, pad/, pad-, pad=,
--pad0, pad1, pad2, pad3, pad4, pad5, pad6, pad7, pad8, pad9,
--padclear, padenter, return, tab, space, delete, escape, help,
--home, pageup, forwarddelete, end, pagedown, left, right, down, up

return characterMapping
