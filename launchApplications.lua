-- Launch Applications (or web pages)
-- Displays a NxM grid of App names and short-cut letters
-- User can use arrow keys to select an app to switch to,
-- Enter or Space to switch. Or may use short-cut letters
-- to switch. Or Escape to cancel.
-- by: Bruce Barrett

launchApplications = {}
-- Operation:
--  HyperFn+A to enter "Application mode"
--  arrow keys to select an app to switch to.
--  Enter or Space to switch.
--  <single key> to launch an application
--  To leave "Application mode" without launching an application press Escape.

--  TODO: Send up, down, left, right changes to Hammerspoon web page as
--    Javascript to increase speed over page load. Maybe something
--    like: changeSelectionFromTo(fromCell, toCell) to move a covering rectangle
--  TODO: <Tab> to move to part of table that doesn't have single-character hotkey launch.
--  TODO: Support NW, NE, SW, SE "arrow keys" for navigating App/Webpage grids. Makes for fewer keystrokes required.
--  TODO: Go totally wild and support a 3rd dimension. Could access 3x3x3=27 entries w/ 2 arrow key presses, or 5x5x5=125 entries with 4 arrow keys
--  TODO: "Merge" hot key behavior
--      1. (done) Have 3 tables, appShortCuts, webShortCuts, and text snippits
--      2. reduce modalAppKey & modalWebKey bindings to 1 table. When both tables use the same keys stroke (or always?)
--        callout to Handle(key) which will pick the right behavior based upon the global, including "do nothing"
--        if the current "mode" does not have that key defined.
--      3. Need to handle "Space" and "Return" in a similar way.
--  TODO: Can we support "Q" to quit the currently selected app?
--  TODO: Support 1, 2, 3,.. to skip to the center of that row of the grid.
--  TODO: BUG: When only one app is open (Finder) and you Hyper+A nothing is displayed, but the keyboard is blocked.

local DEFAULTBROWSER = 'Safari'
local pickerView = nil
inMode = nil          -- I'm not crazy about globals, but this really simplified the code
finalTextToType = ""

-- Format is:
--   Key_to_press. A single key
--   Object with up to 3 items:
--     DisplayText
--     App to launch, or bundleID, or nil
--     Web site to open, or nil
local appShortCuts = {
  -- "/Users/bbarrett/" works, but "~/" does not. :-(
  -- hs.application.launchOrFocusByBundleID("com.aspera.connect") works.
  -- Use Z# to support entries without the 1 character (hot key) shortcuts
  --  Multi char strings?
    ["3"] = {'FileMaker Pro 13', '/Applications/FileMaker Pro 13 Advanced/FileMaker Pro Advanced.app', nil},
    ["7"] = {'FileMaker Pro 17', '/Applications/FileMaker Pro 17 Advanced/FileMaker Pro Advanced.app', nil},
    B = {'BBEdit', 'BBEdit', nil},

    C = {'Chrome', 'Google Chrome', nil},
    D = {'Chatty (Discuss)', 'Chatty', nil},
    G = {'OmniGraffle', 'OmniGraffle', nil},

    I = {'iTunes', 'iTunes', nil},
    J = {'Notes', 'Notes', nil},
    K = {'KiCad', 'kicad', nil},

    M = {'Markoff', 'Markoff', nil},
    N = {'Notetaker', 'Notetaker', nil},
    P = {'System Preferences', 'System Preferences', nil},

    R = {'Remote Desktop', '/Applications/Microsoft Remote Desktop.app/', nil}, -- > hs.application.nameForBundleID("com.microsoft.rdc.mac") --> "Microsoft Remote Desktop"
    S = {"Secure DMG","/Users/bbarrett/Secure.dmg & open /Users/bruce/Secure.dmg",nil}, -- open Secure.dmg either at work or at home.
    X = {'Firefox', 'Firefox', nil},

    Y = {'Calendar (Year)', 'Calendar', nil},

  -- Using Zaa so it sorts after the 1-character shortcuts.
  -- Nothing "sacred" about # of characters in name
  -- Zaa sorts before Zbb so we can keep these in order as we like
    Znu = {'Numbers', 'Numbers', nil},
    Zpa = {'Pages', 'Pages', nil},
    Zpr = {'Preview', 'Preview', nil},
    Zvi = {'VirtualBox', 'VirtualBox', nil},
}

local webShortCuts = {

--    D = {"Google Docs", nil, "https://docs.google.com/document/u/0/?tgif=c"},
--    F = {"Google Hangouts", nil, "https://hangouts.google.com/"},
--    G = {"Google Drive", nil, "https://drive.google.com/drive/my-drive"},

    H = {"Home", nil, "http://brucebarrett.com/browserhome/brucehome.html"},
--    J = {"Jira ASCN", nil, "https://jira.aspera.us/projects/ASCN?selectedItem=com.atlassian.jira.jira-projects-plugin%3Arelease-page&status=no-filter"},
    K = {"KLE", nil, "http://www.keyboard-layout-editor.com"},

--    L = {"Aspera Downlads", nil, "http://downloads.asperasoft.com"},
--    M = {"IBM Mail", nil, "IBM Mail"},
--    N = {"ADN", nil, "https://developer.asperasoft.com"},

--    O = {"Trac, Old bugs", nil, "https://trac.aspera.us"},
    R = {"Reddit/mk", nil, "https://www.reddit.com/r/MechanicalKeyboards/"},
--    S = {"Google Sheets", nil, "https://sheets.google.com"},

--    T = {"Confluence TP", nil, "https://confluence.aspera.us/display/TP/Technical+Publications"},
    W = {"Geekhack", nil, "https://geekhack.org/index.php?action=watched"},   -- Geekhack, Watched
    Y = {'Calendar (Year)', nil, 'https://calendar.google.com/calendar/render#main_7'},

--    Z = {'Zendesk', nil, 'https://aspera.zendesk.com/agent/dashboard'},

    Zgm = {'Google maps', nil, 'https://www.google.com/maps/' },
--    Ztd = {'trac - docs builds', nil, 'https://trac.aspera.us/process2/test/docs' },
--    Ztr = {'trac - release builds', nil, 'https://trac.aspera.us/process2/release/' },
--    Ztt = {'trac - test builds', nil, 'https://trac.aspera.us/process2/test/' },


}

-- Support text snippets in a single column list
local textShortCuts = {
  ["-"] = {"-------------------------------------------", "-------------------------------------------", nil},  -- D for "dashes"
--  ["A"] = {"bbarrett@asperasoft.com", "bbarrett@asperasoft.com", nil},
  ["C"] = {"communitytwok@e", "communitytwok@earthreflections.com", nil},
  ["E"] = {"bruceb@earthreflections.com", "bruceb@earthreflections.com", nil},
  ["I"] = {"brucebarrett@us.ibm.com", "brucebarrett@us.ibm.com", nil},
  ["P"] = {"Markdown Photo", "```\r      +-----+\r      |photo|\r      +-----+\r```\r", nil},
--  ["S"] = {"support@aspera", "support@asperasoft.com", nil},
  ["T"] = {"TODO: ", "TODO: ", nil},
--  ["U"] = {"test-connect", "https://test-connect.asperasoft.com", nil},
--  ["W"] = {"Webex Room", "https://ibm.webex.com/join/brucebarrett", nil}
}

-- myTable:   the table we want to know how many elements it contains
-- test:    is an optional callback. Called with k, v (Key value).
--        test returns true for "count this one."
--        If test is nill don't bother with the test, count all elements.
function countTableElements(myTable, test)
  if myTable == nil then return 0 end
  local count = 0
  for k,v in pairs(myTable) do
    if test == nil or test(k, v) then
      count = count + 1
    end
  end
  return count
end

-- TODO: support special terminal commands for development (git, pushd, cd,...), someday
local developmentShortCuts = {
  A = {"cd algernon-master", nil, nil},
  B = {"cd bruce-ergodox", nil, nil},
  C = {"cd ~/dev/git/qmk_firmware & make keyboard=ergodox keymap=bbarrett", nil, nil}
}


--  HyperFn+A starts "Launch Application mode."
--  It terminates with selecting an app, or <Esc>
local modalAppKey = hs.hotkey.modal.new(HyperFn, 'A')

--  HyperFn+W starts "Launch Webpage mode."
--  It terminates with selecting a web page, or <Esc>
local modalWebKey = hs.hotkey.modal.new(HyperFn, 'W')

--  HyperFn+T starts "Type Text snippets mode."
--  It terminates with selecting a web page, or <Esc>
local modalTextKey = hs.hotkey.modal.new(HyperFn, 'T')

--  Bind keys of interest, both Apps, Web Pages, and Text
--  hs.hotkey.modal:bind(mods, key, message, pressedfn, releasedfn, repeatfn) -> hs.hotkey.modal object
for index, modalKey in pairs({modalAppKey, modalWebKey, modalTextKey}) do
  modalKey:bind('', 'escape',
    function()
      modalKey:exit()
    end
    )
  modalKey:bind('', 'space',
    function()
      launchAppOrWebBySelection()
      modalKey:exit()
      if (finalTextToType ~= "") then
        hs.eventtap.keyStrokes(finalTextToType)
        finalTextToType = ""
      end
    end
    )
  modalKey:bind('', 'return',
    function()
      launchAppOrWebBySelection()
      modalKey:exit()
      if (finalTextToType ~= "") then
        hs.eventtap.keyStrokes(finalTextToType)
        finalTextToType = ""
      end
    end
    )


-- arrow keys, to select app to run
-- insert jikl or wasd as arrow keys here too, if you wish.
-- better yet, just map them as you usually would and they'll
-- pass through here anyway.
  modalKey:bind('', 'left', nil,
    function()
    xsel = math.max(xmin, xsel-1)
    reloadPicker()
    end)
  modalKey:bind('', 'right', nil,
    function()
    xsel = math.min(xmax, xsel+1)
    reloadPicker()
    end)
  modalKey:bind('', 'up', nil,
    function()
    ysel = math.max(ymin, ysel-1)
    reloadPicker()
    end)
  modalKey:bind('', 'down', nil,
    function()
    ysel = math.min(ymax, ysel+1)
    reloadPicker()
    end)
end


-- App launch keys (defined in appShortCuts)
-- Pick up Applications to offer, sorted by activation key
for key, appInfo in hs.fnutils.sortByKeys(appShortCuts) do
  if string.len(key) == 1 then
    modalAppKey:bind('', key, 'Launching '..appInfo[1],
      function()
      launchAppOrWeb_LA(appInfo[2])
      end,
      function() modalAppKey:exit() end)              -- Key up, leave mode
    end
end

-- Web launch keys (defined in webShortCuts)
-- Pick up Web pages to offer, sorted by activation key
-- Any key > 1 character we do not bind to
for key, webInfo in hs.fnutils.sortByKeys(webShortCuts) do
  if string.len(key) == 1 then
      modalWebKey:bind('', key, 'Opening page: '..webInfo[1],
        function()
          launchAppOrWeb_LA(webInfo[3])
          -- hs.execute("open " .. webInfo[3])
      end,  -- Key down, launch
      function() modalWebKey:exit() end)              -- Key up, leave mode
    end
end

-- Text entry keys (defined in textShortCuts)
-- Pick up textShortCuts to offer, sorted by activation key
-- Any key > 1 character we do not bind to
for key, textInfo in hs.fnutils.sortByKeys(textShortCuts) do
  if string.len(key) == 1 then
    modalTextKey:bind('', key,
    function()
      launchAppOrWeb_LA(textInfo[2])
    end,  -- Key down, launch
    function()        -- Key up, leave mode
      modalTextKey:exit()
      if (finalTextToType ~= "") then
        hs.eventtap.keyStrokes(finalTextToType)
        finalTextToType = ""
      end
    end
    )
  end
end

function modalAppKey:entered()
  -- Build a grid of app names
  inMode = "App"
  centerAndShowPicker(appShortCuts)
end

function modalWebKey:entered()
  -- Build a grid of web names
  inMode = "Web"
  centerAndShowPicker(webShortCuts)
end

function modalTextKey:entered()
  -- Build a grid of web names
  inMode = "Text"
  centerAndShowPicker(textShortCuts)
end

-- Move cursor to "center" and load "web page picker:
function centerAndShowPicker(pickerTable)
  -- TODO: Re-do these with '1'-based indexing.
  -- Select, approximately, the center cell of the App array
  xmin =0
  xmax =3
  ymin =0

  -- Dynamically size # of rows (Y) based upon # of entries in table. Using a fixed 4 columns, except for Text
  -- TODO: Remove text HACK for single column. Assume text < 15 and Web / Apps >= 15. Works for me for now.
  tc = countTableElements(pickerTable)
  ymax =math.ceil(tc / 4) -1
  if tc < 15 then
    ymax = tc -1
    xmax = 0
  end

  xsel = math.floor((xmax-xmin)/2)
  ysel = math.floor((ymax-ymin)/2)
  reloadPicker()
end

function modalAppKey:exited()
  -- Take down App selector
  takeDownPicker()
end


function modalWebKey:exited()
  -- Take down Web page selector
  takeDownPicker()
end


function modalTextKey:exited()
  -- Take down Web page selector
  takeDownPicker()
end

function takeDownPicker()
  if pickerView ~= nil then
    pickerView:delete()
    pickerView=nil
  end
  inMode = nil
end

function launchAppOrWebBySelection()
  app = nil
  -- which index, based  on (x, y) cell was selected
  index = ysel * (xmax+1) + xsel
  dataTable =  ((inMode == "App") and appShortCuts) or ((inMode == "Web") and webShortCuts) or textShortCuts;
  for key, appInfo in hs.fnutils.sortByKeys(dataTable) do
    if index == 0 then
      if (inMode == "App" or inMode == "Text") then
        app = appInfo[2]
      else
        app = appInfo[3]
      end
  end
    index = index -1
  end
  launchAppOrWeb_LA(app)
end

-- TODO: Merge/replace with f() of the same name in file: bindFunctionKeys.lua
-- For now just make the names unique
function launchAppOrWeb_LA(app)
  if inMode == "App" then
    -- hs.alert.show('Launching app... '..app)
    status = hs.application.launchOrFocus(app)
    if (not status) then
      status = hs.application.launchOrFocusByBundleID(app)  -- use BundleID ("com.aspera.connect") if App name fails
      if (not status) then
        output, status = hs.execute("open " .. app)
      end
    end
  elseif inMode == "Web" then
    -- Opening webpage, instead of app
      hs.execute("open " .. app)
  else
    -- Typing text, instead of app
    finalTextToType = app
  end
end


function reloadPicker()
  if pickerView then
  -- if it exists, refresh it
    pickerView:html(launchApplications.generateHtml())
  else
  -- if it doesn't exist, make it
  frame = hs.screen.mainScreen():frame()  -- the one containing the currently focused window
  bgX = frame.x + frame.w/2 - 750/2
  bgY = frame.y + frame.h/2 - 350/2

  webPageRect = {x = bgX, y = bgY, w = 750, h = 350}
  pickerView = hs.webview.new(webPageRect, { developerExtrasEnabled = false, suppressesIncrementalRendering = false })
  :windowStyle("utility")
  :closeOnEscape(true)
  :html(launchApplications.generateHtml())
  :allowGestures(false)
  :windowTitle("Launch Applicatiion Mode")
  :show()
  -- These 2 lines were commented out. Don't seem to help
  -- pickerView:asHSWindow():focus()
  -- pickerView:asHSDrawing():setAlpha(.98):bringToFront()
  pickerView:bringToFront()

  end

end

function launchApplications.generateHtml()
  local instructions
  if (  inMode == "App") then
    instructions = {"App", "Application"}
  elseif (  inMode == "Web") then
    instructions = {"Webpage", "Webpage"}
  else
    instructions = {"Text", "Text snippets"}
  end
    local html = [[
        <!DOCTYPE html>
        <html>
        <head>
        <style type="text/css">
            *{margin:10; padding:10;}
            html, body{
              background-color:#404040;
              font-family: arial;
              font-size: 13px;
            }
            header{
              <!-- position: fixed; -->
              top: 0;
              left: 0;
              right: 0;
              height:90px;
              background-color:#aab;
              color:#000000;
              z-index:99;
            }
            .title{
                padding: 15px;
            }

      body {
         margin: 10px; padding: 10px;
         background-color: #404040;
         color: #c0c0c0;
         width: 700px;
         margin: auto;
         font-family: "HelveticaNeue-Light", "Helvetica Neue Light",
          "Helvetica Neue", Helvetica, Arial, "Lucida Grande", sans-serif;
         font-weight: normal;
      }

      .jumpchar {
        color: #ffff00;
      }
      .unsel {
        color: #88ff80;
        font-weight: 900;
      }
      .sel {
        color: #ff0000;
        font-weight: 900;
        background-color: #ffffff;
      }
        </style>
        <title>Launch Application Mode</title>
        </head>
          <body>
            <header>
              <div class="title"><strong>Launch ]]..instructions[2]..[[ Mode</strong><br>
        Use arrow keys to select ]]..instructions[1]..[[ to launch.<br>
        Space or return to launch.<br>
        Esc to Cancel.
              </div>
            </header>

          </body>
        </html><br>
    <div id="container">
    <table id="selTable" width="100%"  border="1">
    ]]..generateAppOrWebTable()..[[
    </table>
  </div>
  <div>
    <!-- Selected cell = <span id="selCell">selected cell goes here</span>. -->
  </div>

        ]]
    -- Adding this will dump the HTML to the console where it can be copied, if desired.
    -- hs.console.printStyledtext( html )
    return html
end

function generateAppOrWebTable()
  local tableText =  "<tr>"

  local x = 0;
  local y = 0;
  local i = 0;

  for key, appInfo in hs.fnutils.sortByKeys((inMode == "App") and appShortCuts or (inMode == "Web") and webShortCuts or textShortCuts) do
    tableText = tableText .. "<td class = 'jumpchar' width='3%' align='right'>" ..
      ((string.len(key) == 1) and key..":" or "&nbsp;");  -- skip entries we don't want to use with 1 character (hot key) shortcuts
    tableText = tableText .. "<td class="

    tableText = tableText .. ((x==xsel and y==ysel) and "'sel'" or "'unsel'")

    tableText = tableText .. " width='20%'>" .. appInfo[1] .. "</td>";

    x = x + 1
    if x > xmax then
      -- end tr
      tableText = tableText .. "</tr>\n<tr>"
      x = xmin
      y = y + 1
    end

  end
  -- Fill the rest of the last row with &nbsp; in cells for cleaner display.
  if x > xmin then
    for i=xmax, x, -1 do
    tableText = tableText .. "<td class = 'jumpchar' width='5%' align='right'>&nbsp;";
    tableText = tableText .. "<td class='unsel' width='22%'>&nbsp;</td>";
    end
  end
    return tableText
end


return launchApplications
