local repeatNextKey = {}
-- repeatNextKey.lua
-- F15		Repeat next "keypress" n times, default to 3

--  Operation:
--  1. Get activated by bound key. Set default count to 3
--  2. One of these happens:
--    If Esc is hit we cancel the operation, and the key is swallowed.
--    If bound key is hit again count is increased to 5, 8, 13, 21, 34, 65 The Fibonacci sequence (and no further)
--      and the key is swallowed.
--    If a digit is hit after the bound key is hit at least twice then that digit
--      is the character to repeat. The digit is repeated, the sequence ends.
--    If a digit is hit it is added to the count string, and the key is swallowed.
--    If any other key (or key + modifiers) is hit we send that n times, where n is
--      a) the manually entered string of digits, if that string length >=1,or
--      b) from the Fibonacci sequence
--  3. Repeat step 2 until Esc or the key to repeat is struck.

-- Private fields

-- Global variables
SWALLOWEVENT = true
isAccumulatingCounts = false          -- I'm not crazy about globals, but this really simplified the code
repeatCountString = ""
repeatCount = 3
priorRepeatCount = 2
eventTapObject = nil

-- Repeat Next Key is active, grab next key and either:
--  1. Upate the count, or
--  2. type it repeatedly
function eventTapHandler(eventObj)
  local updn = "unknown"
  if eventObj:getType() == 10 then updn = "Up" end
  if eventObj:getType() == 11 then updn = "Dn" end
  local kc = eventObj:getKeyCode()
  local keyStr = string.sub(hs.keycodes.map[kc], -1)  -- last char of key name, could be 0..9
  local flags = eventObj:getFlags()

  -- We are already in "Repeat next key mode," if we get another f15
  -- this means we bump the repeat count and continue to run.
  -- Note: If user has already started entering numbers for the repeat count ignore this
  -- TODO: CAUTION! This code needs to be changed if you change the bound key
  if kc == hs.keycodes.map["f15"] and flags["fn"] then
    if (string.len(repeatCountString) == 0) then
      nextRepeatCount = repeatCount + priorRepeatCount
      priorRepeatCount = repeatCount
      repeatCount = nextRepeatCount
      hs.alert("repeat count: ".. repeatCount)
    end
    return SWALLOWEVENT
  end

  local modifierFlags = {}
  if flags["cmd"]  then table.insert(modifierFlags, " Cmd") end
  if flags["alt"]  then table.insert(modifierFlags, " Alt") end
  if flags["shift"] then table.insert(modifierFlags, " Shift") end
  if flags["ctrl"] then table.insert(modifierFlags, " Ctrl") end
  if flags["fn"]   then table.insert(modifierFlags, " Fn") end
--  debuglog("got eventType, KeyCode, Modifiers: " .. updn ..", " .. kc .. ", " .. modifierFlags)

  if (updn ~= "Up") then
    debuglog("got non-KeyUp KeyCode: " .. kc)
    goto stopping
  end

  if "0" <= keyStr and keyStr <= "9" then
    repeatCountString = repeatCountString..keyStr
    hs.alert("repeat count: "..repeatCountString)
    return SWALLOWEVENT
  end

  ::stopping::
  if isAccumulatingCounts then
    isAccumulatingCounts = false
  end

  debuglog("turning off")
  eventTapObject:stop()
  -- no output for escape typed
  if kc == hs.keycodes.map["escape"] then
    hs.alert("repeat canceled")
  else
    if string.len(repeatCountString) > 0 then
      repeatCount = tonumber(repeatCountString)
    end
    local i
    for i=1, repeatCount do
    -- TODO: BUG: Need to include modifier array here too
      hs.eventtap.keyStroke(modifierFlags, kc, 5000)  -- output result AFTER at about 200 CPS
    end
  end
 return SWALLOWEVENT
end

function startRepeatNextKey()
--  hs.alert("got f15")
  debuglog("got f15")
	if not isAccumulatingCounts then
    debuglog("turning on")
    -- First repeatNextKey detected, set-up to start work
    isAccumulatingCounts = true
    repeatCountString = ""
    repeatCount = 5
    priorRepeatCount = 3
    hs.alert("repeat count: ".. repeatCount)
    eventTapObject:start()
	else
    -- We never come through here
    debuglog("Unexpected behavior")
	end
end

eventTapObject = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, eventTapHandler )
hs.hotkey.bind("", "f15", startRepeatNextKey, nil, nil )	-- bind the key to pressed and released
HF.add("F15 (Pause) - Repeat next 'keypress' n times\n")
