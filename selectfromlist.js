document.onkeyup = KeyCheck;       
	
	function KeyCheck(e)
		{
		   var KeyID = (window.event) ? event.keyCode : e.keyCode;
		
		   switch(KeyID)
		   {
		
		      case 37:
		      window.location = "index.html";
		      break;
		
		      case 38:
		      window.location = "about.html";
		      break;
		
		      case 39:
		      window.location = "portfolio.html";
		      break;
		
		      case 40:
		      window.location = "contact.html";
		      break;
		      
		      case 49:
		      window.location = "index.html";
		      break;
		
		      case 50:
		      window.location = "about.html";
		      break;
		
		      case 51:
		      window.location = "portfolio.html";
		      break;
		
		      case 52:
		      window.location = "contact.html";
		      break;
		   }
		}
