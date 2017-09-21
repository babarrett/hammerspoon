-- cuChooser.lua
local cu = {}
--------------------------------------------------------------------------------------
--  Custom Chooser module API
--  (because hs.Chooser is not flexible enough)
--------------------------------------------------------------------------------------
--  ⌘⌥⌃⇧
--
--  Visual Model of display:
--
--    /------------------ BG ----------------------\
--    |[1]                                         |
--    |   +----------------------------------+     |
--    |   |"search term"                     |     | <- Optional
--    |   +----------------------------------+     |
--    |                                            |
--    |   +----------------------------------+     |
--    |   | H1  | H2     | H3  | H4     |    |     | <- Header(s), optional
--    |   +----------------------------------+     |
--    |   +----------------------------------+ |^| |
--    |   | C1  | C2     | C3  | C4     |⌘1 | |.| | <- Row 1
--    |   +----------------------------------+ |.| |
--    |   b C1  | C2     | C3  | C4     |⌘2 | |.| | <- Row 2,... with command key equivalent
--    |   bbbb-------------------------------+ |.| |
--    |   :  :     :          :     :        : |.| |
--    |   +----------------------------------+ |v| |
--    |     Descriptive text...                    |
--    |                             ... here.      |
--    \--------------------------------------------/
--    <--------------- [BG Width] ----------------->
--
--  Legend:
--    BG		Background of chooser area.
--        	Settable: Color, Alpha, corner radius [, z-order level?]
--    [1]   Boarder between BG outer edge and content
--    "search term"	Space to enter search terms, to support the current hs.chooser functionality
--        	Settable: Height, search value (default ""), text style
--          Uses: Sum of Column Widths + 2*cell boarder widths for search term width.
--    Hn    Heading number. One per column, if displayHeading(true).
--        	Settable: height
--          Uses: Any Column Widths for the heading widths.
--    Cn    Column number. Support at least pairs of columns with different widths
--        	Settable: height
--    ⌘1   Command key equivalent, only available when there is 1 column? Optional
--    Row n Row
--        	Settable: height
--    C   	Cell
--        	Settable: Styled text, and/or image
--    Cell text
--        	Settable: (optional) Styled text
--        	Settable: (optional) Text rectangle (text area - cell rectangle / 2 = boarder sizes)
--    Cell image
--          Settable: (optional) Image (png, jpg, etc,)
--          Settable: (optional) Text rectangle (text area - cell rectangle / 2 = boarder sizes)
--
--    [<...>] (optional) Vertical scrollbar region, if displayRowShowShortcuts(true).
--
--    [BG Width]	outer width of BG region
--        Computable: [BG Width] = 2*boarder width+Sum(cell widths)+2*Sum(cell boarder lines)+ scroll bar width
--
--    [BG Height] outer height of BG region
--        Computable: [BG Height] = 2*boarder height+Sum(cell heights)+2*Sum(cell boarder lines)+search term height+Descriptive text height
--
--    b   Cell boarders, all around. Definable color, alpha, and width. Boarders are between each cell
--        so add to the total BG width by (width * (number of columns+1))
--
--  Definitions:
--  	cellnum: can either be a single integer counting cells from Column1, Row1 across,
--          then down, in normal reading order, or a table of {X, Y} coordinates.
--          X for column, Y for row. C1,R1 = {1,1} or 1.
--          For a 3 column table C2,R3 = {2,3} or 8.
--
--	Typed characters accepted and used to drive the interface:
--    Up, down, left, right:				Move to adjacent cell. Stops at first/last column, and row
--    Shift+Up, down, left, right:  Extend selection if cellMultiSelect(true)
--    Cmd+1,2,3...:         				Select indicated row and exit, if displayRowShowShortcuts(true)
--    Enter:    cu is complete. Return table of selected cellnums (if any), unless search field has focus -- then search
--    Space:    cu is complete. Return table of selected cellnums (if any), unless search field has focus -- then add space
--    Tab:    	anything?
--    Home:   	1st cell in current row
--    End:    	last cell in current row
--    PageUp:   1st cell in current column
--    PageDn:   last cell in current column
--    Esc:    	Exit cu w/o changes. Returns nil
--    others (a-z,A-Z,0-9,special)  Ignore or add to search string
--    Backspace Ignore or delete char from search string
--
--  API Overview
--    • Constants
--
--    • Constructors
--      ° new   cu.chooser.new(completionFn) -> cu.chooser object
--
--
--    • Methods
--
--  CONSTRUCTORS
--  new	cu.chooser.new(completionFn) -> cu.chooser object, and the reason for returning. Usually a character that triggered
--      completionFn - A function that will be called when the chooser
--      is dismissed. It should accept one parameter, which will be nil if the user
--      dismissed the chooser window, otherwise it will be a table containing whatever
--      information you supplied for the item the user chose.
--
--  METHODS BY PART
--  CU
--      cu.chooser.show()         --  Recompute sizes, display, etc. Clear selected cell formatting
--      cu.chooser.hide()         --  Hide everything
--      cu.chooser.delegateChars( table ) --  Table of characters that cu.chooser will handle. Default is all.
--
--  BG
--      (No methods for height or width, those are computed based on margins and other object sizes)
--      cu.chooser.bgColor(color)
--      cu.chooser.bgInnerMargin(points)
--      cu.chooser.bgLocation( centered | topthird | mouse [, active | main ]) -- Where to center BG on screen, and which screen
--
--  CELLS
--      cu.chooser.cellSet(text[,callback?])--
--      cu.chooser.cellUnselectable()   --  So "label" cells don't get selected
--      cu.chooser.cellWidths( table )    --  table of widths, one entry per column.
--      cu.chooser.cellHeight( height )   --  in points
--      cu.chooser.cellInnerMargin(points ) --
--      cu.chooser.cellTextStyle( style ) --  Includes font, color, alignment
--      cu.chooser.cellSelectStyle( style ) --  Includes font, color, alignment for the cell(s) that are selected
--      cu.chooser.cellMultiSelect(boolean) --  True for allowing > 1 cell to be selected.
--      cu.chooser.cellSelect(cellnum[,add])--  Select the given cell. If add is true add new cell to any existing selection
--      cu.chooser.cellDeselect(cellnum)  --  Deselect. Select is tracked even if the cell is not visible (scrolled off)
--      cu.chooser.cellBoarders([width[,color]])
--                        -- Set boarders around each cell. With no parameters, or width=0 there's no boarder.
--                        -- color includes alpha. Width in points. Boarders are drawn with a minimal number
--                        -- of lines, so for 3 x 4 cells there will be 4 + 5 = 9 lines drawn. i.e. we don't draw a rect per cell.
--
--  ROWS
--      cu.chooser.rowsVisible( count )   --  number of visible rows. Defaults to count of rows provided.
--      cu.chooser.rowTotal( count)     --  all rows stored. Needed? or do we just count them. Defaults to count of rows provided.
--      ? cu.chooser.rowTrimExcess(boolean) --  true for shrink display, including BG if rows provided < count
--      cu.chooser.rowShowScroll(boolean) --  Show scrollbar
--      cu.chooser.rowShowShortcuts(boolean)--  Show Cmd+1, ... shortcuts after last column of each row.
--
--  HEADER
--      cu.chooser.headerSet(column, text)  --  Fill in 1 cell of the header
--      cu.chooser.headerTextStyle( style ) --  Includes font, color, alignment
--
--  SEARCH
--      cu.chooser.searchHeight( height)  --  in points
--      cu.chooser.searchInnerMargin(points)--
--      cu.chooser.searchStyle( style )
--      ... others about searching fns()
--
--  DESCR
--      cu.chooser.descrHeight( height)   --  in points. Make taler for multi-line text
--      cu.chooser.descrInnerMargin(points) --
--      cu.chooser.descrStyle( style )
--      cu.chooser.descrTrimExcess(boolean) --  true for shrink display, including BG description fits in < provided height
--
--
--  Data Structures  --
-----------------------
--
--	All graphic objects, for eventual removal
--    newcu.grob  --  The root if the list of graphic objects. .grob is a list of lists. Each sub-list contains
--            				a list of the same type of objects, for example cell styled text, boarder lines, bg itself, etc.
--
--		So the cu structure is:
--    	newcu.grob
--      	.grob.bg
--        	.grob.stbox   -- search text box
--          .grob.sttext  -- search text edit field
--          .grob.headbox -- header boxes (1 per cell)
--          .grob.headtext  -- header text (1 per cell)
--          .grob.cellbox
--          .grob.celltext
--          .grob.descrtext
--          .grob.scrlbar
--          .grob.scrlthumb
--          .grob.
--          .grob.

--  new   cu.chooser.new(completionFn) -> cu.chooser object, or nil for error
function cu.new(completionFn)
  -- validate input
  if completionFn == nil then
    return nil
  end
  newcu = {}
  newcu.grob = {}
  newcu.bg = {["width"]=100, ["height"]=50, ["color"]={["red"]=0.5,["blue"]=0.5,["green"]=0.5,["alpha"]=0.5}, ["radius"]=5}
  -- TEST: Show the BG test rectangle
  local bgRect = ""
  bgRect = hs.drawing.rectangle(hs.geometry.rect(100, 100, newcu.bg.width, newcu.bg.height))
  bgRect:setFillColor({["red"]=0.7,["blue"]=0.5,["green"]=0.5,["alpha"]=0.5}):setFill(true)
  bgRect:setRoundedRectRadii(10, 10)
  bgRect:setLevel(hs.drawing.windowLevels["floating"])
  newcu.grob.bg = (newcu.grob.bg ~= nil) and newcu.grob.bg or {}
  table.insert(newcu.grob.bg, bgRect:show() )
  hs.timer.doAfter(5, cu.delete)
  -- debuglog(bgRect)
  return newcu
end

function cu.delete()
  clearGrobs(newcu.grob.bg)
  newcu.grob.bg = nil
end


----------------------  Utilities Functions ---------------------

---	Clear (hide, delete and set to nil) all graphic objects in the provided list (table).
--  Any nil items in the list are ignored. If, by chance, one of the objects in the provided
--	list is itself a table (list) then call recursively to delete the objects in that table.
--  Nothing returned.
-- 	@param groblist The list (table) of graphic objects to be removed
function clearGrobs(groblist)
  local k, v
  for k, v in pairs(groblist) do
    -- debuglog("k: "..k.."; v: "..tostring(v))
    if type(v) == "table" then
      clearGrobs(v)
      v = nil
    else
      v:hide()
      v:delete()
      v=nil
    end
  end
end

return cu
