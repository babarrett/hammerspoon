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
--      either from the Fibonacci sequence, or the manually entered string of digits.
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
  local flags = eventObj:getFlags()

  -- We are already in "Repeat next key mode," if we get another f15
  -- this means we bump the repeat count and continue to run.
  -- TODO: CAUTION! This code needs to be changed if you change
  if kc == hs.keycodes.map["f15"] and flags["fn"] then
    nextRepeatCount = repeatCount + priorRepeatCount
    priorRepeatCount = repeatCount
    repeatCount = nextRepeatCount
    hs.alert("repeat count: ".. repeatCount)
    return SWALLOWEVENT
  end

  local modifierFlags = {}
  if flags["cmd"]  then table.insert(modifierFlags, " Cmd") end
  if flags["alt"]  then table.insert(modifierFlags, " Alt") end
  if flags["shift"] then table.insert(modifierFlags, " Shift") end
  if flags["ctrl"] then table.insert(modifierFlags, " Ctrl") end
  if flags["fn"]   then table.insert(modifierFlags, " Fn") end
--  debuglog("got eventType, KeyCode, Modifiers: " .. updn ..", " .. kc .. ", " .. modifierFlags)

  if (eventObj:getType() ~= 10) then
    debuglog("got non-KeyUp KeyCode: " .. kc)
    goto stopping
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
    -- This else never gets executed.
    -- We are already in "Repeat next key mode"
    -- so this means bump the repeat count and continue to run
    nextRepeatCount = repeatCount + priorRepeatCount
    priorRepeatCount = repeatCount
    repeatCount = nextRepeatCount
    debuglog("repeat count now: ".. repeatCount)
--    isAccumulatingCounts = false
--    eventTapObject:stop()
	end
end

eventTapObject = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, eventTapHandler )
hs.hotkey.bind("", "f15", startRepeatNextKey, nil, nil )	-- bind the key to pressed and released
HF.add("F15 (Pause) - Repeat next 'keypress' n times\n")
