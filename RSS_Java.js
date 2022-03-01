function mybutton(){
	alert ("This better work");
}


   function getScore(){
       // Get the selected score (assuming one was selected)
       var pr = document.querySelector('input[name="recognizable"]:checked').value;
	   var psens = document.querySelector('input[name="PHISensitivity"]:checked').value;
	   var prisk = document.querySelector('input[name="Risk"]:checked').value;
	   //Add one extra for media exposure
	   var total = parseInt(pr) + parseInt(psens) + parseInt(prisk) + 1;
       alert('Total grid score: ' + total );
   }






function highlight_row() {
    var table = document.getElementById('final');
    var cells = table.getElementsByTagName('td');

    for (var i = 0; i < cells.length; i++) {
        // Take each cell
        var cell = cells[i];
        // do something on onclick event for cell
        cell.onclick = function () {
            // Get the row id where the cell exists
            	
			var rowId = this.parentNode.rowIndex;
            var rowsNotSelected = table.getElementsByTagName('tr');
            for (var row = 0; row < rowsNotSelected.length; row++) {
                rowsNotSelected[row].style.backgroundColor = "";
                rowsNotSelected[row].classList.remove('selected');
            }
            var rowSelected = table.getElementsByTagName('tr')[rowId];
            rowSelected.style.backgroundColor = "yellow";
            rowSelected.className += " selected";
			var cellId = this.cellIndex + 1

            msg = 'Title: ' + rowSelected.cells[0].innerHTML;
            msg += '\r\nDescription: ' + rowSelected.cells[1].innerHTML;
			msg += '\n\nLink: ' + rowSelected.cells[2].innerHTML;
			msg += '\nPublication Date: ' + rowSelected.cells[3].innerHTML;
			//msg += '\nThe cell value is: ' + this.innerHTML copies cell selected
            navigator.clipboard.writeText(msg);
			
			alert('Copied to clipboard: \nRow Index: ' + rowId + '\nCell Index: ' + cellId);
			if(cellId==5){
				document.location = "mailto:"+'gouldd@sutterhealth.org'+"?subject="+'Test'+"&body="+msg;
			}
        }
    }

};
/*
sendEmail(message) {
    var email = message.emailId;
    var subject = message.subject;
    var emailBody = 'Hi '+message.from;
    document.location = "mailto:"+email+"?subject="+subject+"&body="+emailBody;
};


/*
function addRowHandlers() {
    var table = document.getElementById("final");
    var rows = table.getElementsByTagName("tr");
    for (i = 0; i < rows.length; i++) {
        var currentRow = table.rows[i];
        var createClickHandler = 
            function(row) 
            {
                return function() { 
                                        var cell = row.getElementsByTagName("td")[0];
                                        var id = cell.innerHTML;
                                        alert("id:" + id);
                                 };
            };

        currentRow.onclick = createClickHandler(currentRow);
    }
}
 window.onload = addRowHandlers();
 /*
 function highlight(e) {
    if (selected[0]) selected[0].className = '';
    e.target.parentNode.className = 'selected';
}

var table = document.getElementById('final'),
    selected = table.getElementsByClassName('selected');
table.onclick = highlight;

function fnselect(){
    
    alert($("tr.selected td:first" ).html());
}
*/