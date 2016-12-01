document.onkeyup = KeyCheck;       

var selX = 1;
var selY = 1;
	
function KeyCheck(e)
	{
	   var KeyID = (window.event) ? event.keyCode : e.keyCode;

	   switch(KeyID)
	   {
		  case 37:	// Left
		  	selX = Math.max(0, selX-1);
		  break;
	
		  case 38:	// Up
		  	selY = Math.max(0, selY-1);
		  break;
	
		  case 39:	// Right
		  	selX = Math.min(2, selX+1);
		  break;
	
		  case 9:	// Tab. Move to right, also
		  	selX = Math.min(2, selX+1);
		  break;
	
		  case 40:	// down
		  	selY = Math.min(2, selY+1);
		  break;
		  
		  case 13:	// Return
		  	// selY = Math.max(0, selY-1);
		  break;
	
		  case 32:	// Space
		  	// selX = Math.min(2, selX+1);
		  break;
	
		  case 27:	// Escape
		  	// selY = Math.min(2, selY+1);
		  break;
		  // All other keys are ignored.
	   }
	   // alert("Setting span: " + selX + ", " + selY + "  -- KeyID = " + KeyID);
	   regenTable("selTable", selX, selY);
	   document.getElementById('selCell').innerHTML = "" + selX + ", " + selY + "  KeyID=" + KeyID;
	}

function regenTable(id, selx, sely)
	{
		var x = 0;
		var y = 0;
		var i = 0;
		jumpChars = ["M", "S", "C", "X", "T", "F", "P", "B", ""]
		appNmaes  = ["Mail", "Safari", "Chrome", "Firefox", "iTerm", "Finder", "System Prefs", "BBedit", "" ]
		var html = ""
		for (y = 0; y < 3; y++) {
			// every TR
			html = html + "<tr>"
			for (x = 0; x < 3; x++) {
				// every TD
				html = html + "<td class = 'jumpchar' width='5%' align='right'>" + jumpChars[i] +":";
				html = html + "<td class="
				html = html +  ((x==selx && y==sely) ? "'sel'" : "'unsel'");
				html = html + " width='22%'>" + appNmaes[i] + "</td>";
				i++;
			}
			html = html + "</tr>\n";
		}
		document.getElementById(id).innerHTML = html;
	}

