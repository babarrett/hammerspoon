-- Report Layer Modifier Change
-- Bruce's Ergodox keyboard will generate a sequence starting with F14 
-- and ending with <return> when a layer or modifier change is noted.
-- This Hammmerspoon code will detect and interpret those "keys" and
-- display the current state in a "heads up display"
-- by: Bruce Barrett

reportLayerModifierChange = {}
-- Operation:
--	Notice the F14 key and enter the tracking mode
--	set addDelete global to "add"
--	Loop, listening for characters until <return> is received.
--		when "+" is received set addDelete global to "add"
--		when "-" is received set addDelete global to "delete"
--		Handle Mod changes
--		when "A" is received set modShift to "true" (or "false" if addDelete == "delete")
--		when "B" is received set modControl
--		when "C" is received set modOption
--		when "D" is received set modCommand
--		Handle Layer changes
--		when "0" to "9" is received set layer to:
--		0 = Base
--		1 = Numeric
--		2 = Nav/Pnct
--		3 = SpaceFn
--		4 = Layer 4, etc.

local HUD = nil
local addDelete = "add"					-- I'm not crazy about globals, but this simplifies the code
local modShift		= false
local modControl	= false
local modOption		= false
local modCommand	= false

local keyList = { 
		mi = "-", -- and later, "+"
		A = "A", B = "B", C = "C", D = "D", 
		f = "0", g = "1", h = "2", i = "3", j = "4", 
		k = "5", l = "6", m = "7", n = "8", o = "9"
		}
layerNames = {
	"Numeric",
	"Nav/Pnct",
	"SpaceFn",
	"Layer 4",
	"Layer 5",
	"Layer 6",
	"Layer 7",
	"Layer 8",
	"Layer 9",
}
layerNames[0] = "Base"
layerName = layerNames[0]	-- default start

--	HyperFn+F14 starts "Report Layer Modifier Change mode."
--	It terminates with <return>
local LayerModifierKey = hs.hotkey.modal.new(HyperFn, 'F12')

LayerModifierKey:bind('', 'return',  
	function() 
	debuglog("Return")
	-- TODO: Update HUD display here
	LayerModifierKey:exit() end)

-- Map all keys of interest to processing routine
-- Pick up Applications to offer, sorted by activation key
for key, val in hs.fnutils.sortByKeys(keyList) do
	debuglog( "Key="..key.."  val="..tostring(val).."  table val=".. tostring(keyList[key]))
	LayerModifierKey:bind('', val, nil, 
	  function()
		processChar(val)
	  end)							-- Key up, leave mode
end

debuglog("plus as shift+'=' for plus.")
LayerModifierKey:bind('{shift}', "=", nil, 
  function()
		processChar("+")
  end)							-- Key up, leave mode

-- OK, this is the real work
--		when "+" is received set addDelete global to "add"
--		when "-" is received set addDelete global to "delete"
--		Handle Mod changes
--		when "A" is received set modShift to "true" (or "false" if addDelete == "delete")
--		when "B" is received set modControl
--		when "C" is received set modOption
--		when "D" is received set modCommand
--		Handle Layer changes
--		when "0" to "9" is received set layer to:
--		0 = Base
--		1 = Numeric
--		2 = Nav/Pnct
--		3 = SpaceFn
--		4 = Layer 4, etc.
function processChar(val)
  debuglog("caught a: "..val)
  if       val == "A" then modShift = (addDelete == "add")
    elseif val == "B" then modControl = (addDelete == "add")
    elseif val == "C" then modOption = (addDelete == "add")
    elseif val == "D" then modCommand = (addDelete == "add")
    elseif val == "E" then modCommand = (addDelete == "add")
    elseif (val >= "0") and (val <= "9") then layerName = layerNames[tonumber(val)]
    elseif val == "+" then addDelete = "add"
    elseif val == "-" then addDelete = "delete"
  end
  debuglog("Layer: ".. layerName.. "  Add/Delete: ".. addDelete..  "   Shift: ".. tostring(modShift))
end

return reportLayerModifierChange
