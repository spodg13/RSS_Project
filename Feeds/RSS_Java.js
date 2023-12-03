function save() {
  var htmlContent = [""];
  var bl = new Blob(htmlContent, {type: "text/html"});
  var a = document.createElement("a");
  a.href = URL.createObjectURL(bl);
  a.download = "test_Save.html";
  a.hidden = true;
  document.body.appendChild(a);
  a.innerHTML = "something random - nobody will see this, it doesn't matter what you put here";
  a.click();
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
      alert('Row picked:' + rowId);
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

function msg(){  
 alert("Hello Javatpoint");  
} 
function show() {
  alert("Hello table");
}