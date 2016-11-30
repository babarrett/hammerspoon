-- simpleTest.lua
local SimTst = {}

-- private functions to be referenced & executed later.
fun1 = function() 
	hs.console.printStyledtext("fun1() called from bound f()")
	return "fun1"
end
fun2 = function() 
	local y = 1
	return "fun2"
end


-- private
local helpString = "SimpleTest Help\n"
local funNameToFunction = {
	myName1 = fun1,
	myName2 = fun2
}

-- external interface
function SimTst.getHelpString()
--	helpString = helpString .. "Hyper+A: Apple\n"
--	helpString = helpString .. "Hyper+B: Banana\n"
--	helpString = helpString .. "Hyper+C: Carbon\n"
	hs.console.printStyledtext(fun1())
	hs.console.printStyledtext(fun2())
	return helpString
end

function SimTst.bind(modifiers, char, functName)
	hs.console.printStyledtext(# modifiers)
	hs.console.printStyledtext(char)
	hs.console.printStyledtext(functName)
	hs.hotkey.bind(modifiers, char, funNameToFunction[functName])
	return "123"
end

-- return SimTst


-- --------------------------------------------
-- -- Example usage:
-- local ST = require 'simpleTest'
-- ST.bind({}, "U", myName1)
-- helpString = helpString .. ST.getHelpString()	-- accumulate help strings



-- 
------------------------------------------------------------------------
--/ Test display and use HTML page / display /--
------------------------------------------------------------------------

local htmptest = {}

function generateHtml()
	local pageTitle = 'Test HTML page'
    local html = [[
        <!DOCTYPE html>
        <html>
        <head>
        <style type="text/css">
            *{margin:0; padding:0;}
            html, body{ 
              background-color:#ddf;
              font-family: arial;
              font-size: 13px;
            }
        </style>
        </head>
          <body>
            <header>
              <div class="title"><strong>]]..pageTitle..[[</strong></div>
              <hr />
            </header>
            <div class="content maincontent">]]..'Main Content'..[[</div>
            
			<button onclick="myFunction()">Click me</button>
			
        	<script type="text/javascript">
        	  document.write("1111");
        	  document.write("Date: "+ Date());
        	  document.write("2222");
              var i = 1;
	  		  for (i = 1; i < 5; i++) {
	            document.write("Line "+i+" is here.<br>");
              }
        	  
        	  myFunction() {
        	    
        	  }
            </script>
          </body>
        </html>
        ]]
    -- Adding this will dump the HTML to the console where it can be copied, if desired.
    -- hs.console.printStyledtext( html )
    return html
end
  


local myView = nil

hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "L", function() 
  if not myView then
    -- Bruce updated these for larger MacBook Pro screen to prevent scrolling.
    myView = hs.webview.new({x = 100, y = 50, w = 300, h = 300}, { developerExtrasEnabled = true })
      :windowStyle("utility")
      :closeOnEscape(true)
      :html(generateHtml())
      :allowGestures(true)
      :windowTitle("HTML Test")
      :show()
    -- These 2 lines were commented out. Don"t seem to help
    -- myView:asHSWindow():focus()
    -- myView:asHSDrawing():setAlpha(.98):bringToFront()
  else
    myView:delete()
    myView=nil
  end
end
)

return htmptest
